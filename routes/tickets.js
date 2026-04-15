const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const authenticateToken = require('../middleware/auth');
const { sendNotificationToPatient } = require('../services/notification');
// Helper function to emit queue updates
const emitQueueUpdate = (io, clinicId) => {
  io.to(`clinic_${clinicId}`).emit('queue_updated', { 
    clinicId, 
    timestamp: new Date().toISOString(),
    message: 'La file d\'attente a été mise à jour'
  });
};

// Take a ticket
router.post('/', authenticateToken, async (req, res) => {
  const io = req.app.get('io');
  
  try {
    const { clinic_id, type, priority } = req.body;
    const user_id = req.user.id;

    // Get current max ticket number for this clinic today
    const maxResult = await pool.query(
      `SELECT COALESCE(MAX(ticket_number), 0) as max_num 
       FROM tickets 
       WHERE clinic_id = $1 
       AND DATE(created_at) = CURRENT_DATE`,
      [clinic_id]
    );

    const ticketNumber = maxResult.rows[0].max_num + 1;

    // Count waiting tickets to estimate position
    const posResult = await pool.query(
      `SELECT COUNT(*) as count 
       FROM tickets 
       WHERE clinic_id = $1 
       AND status = 'waiting'
       AND DATE(created_at) = CURRENT_DATE`,
      [clinic_id]
    );

    const position = parseInt(posResult.rows[0].count) + 1;
    const estimatedTime = position * 7;

    const result = await pool.query(
      `INSERT INTO tickets 
       (user_id, clinic_id, ticket_number, type, priority, status, position, estimated_time)
       VALUES ($1, $2, $3, $4, $5, 'waiting', $6, $7)
       RETURNING *`,
      [user_id, clinic_id, ticketNumber, type || 'normal', priority || 'normal', position, estimatedTime]
    );

    // Emit socket event to notify all clients in this clinic
    emitQueueUpdate(io, clinic_id);

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// Get queue for a clinic
router.get('/clinic/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `SELECT t.*, u.name as patient_name, u.phone as patient_phone
       FROM tickets t
       JOIN users u ON t.user_id = u.id
       WHERE t.clinic_id = $1
       AND DATE(t.created_at) = CURRENT_DATE
       ORDER BY 
         CASE t.status
           WHEN 'called' THEN 1
           WHEN 'waiting' THEN 2
           WHEN 'done' THEN 3
         END,
         CASE t.priority
           WHEN 'urgent' THEN 1
           WHEN 'normal' THEN 2
         END,
         t.ticket_number ASC`,
      [id]
    );

    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// Call next patient (priority algorithm: 1 urgent per 3 normal)
router.put('/clinic/:id/call-next', authenticateToken, async (req, res) => {
  const io = req.app.get('io');
  
  try {
    const { id } = req.params;

    // Count how many normal patients have been called today
    const normalCalledResult = await pool.query(
      `SELECT COUNT(*) as count FROM tickets
       WHERE clinic_id = $1
       AND status IN ('called', 'done')
       AND priority = 'normal'
       AND DATE(created_at) = CURRENT_DATE`,
      [id]
    );

    // Count how many urgent patients have been called today
    const urgentCalledResult = await pool.query(
      `SELECT COUNT(*) as count FROM tickets
       WHERE clinic_id = $1
       AND status IN ('called', 'done')
       AND priority = 'urgent'
       AND DATE(created_at) = CURRENT_DATE`,
      [id]
    );

    const normalCalled = parseInt(normalCalledResult.rows[0].count);
    const urgentCalled = parseInt(urgentCalledResult.rows[0].count);

    // Check if there are urgent tickets waiting
    const urgentWaiting = await pool.query(
      `SELECT * FROM tickets
       WHERE clinic_id = $1
       AND status = 'waiting'
       AND priority = 'urgent'
       AND DATE(created_at) = CURRENT_DATE
       ORDER BY ticket_number ASC
       LIMIT 1`,
      [id]
    );

    // Check if there are normal tickets waiting
    const normalWaiting = await pool.query(
      `SELECT * FROM tickets
       WHERE clinic_id = $1
       AND status = 'waiting'
       AND priority = 'normal'
       AND DATE(created_at) = CURRENT_DATE
       ORDER BY ticket_number ASC
       LIMIT 1`,
      [id]
    );

    // Mark current 'called' ticket as done
    await pool.query(
      `UPDATE tickets SET status = 'done'
       WHERE clinic_id = $1
       AND status = 'called'`,
      [id]
    );

    let nextTicket = null;

    // Priority algorithm: call urgent if available,
    // but every 3 normal calls, force a normal if available
    const shouldCallNormal = normalCalled > 0 && 
                             normalCalled % 3 === 0 && 
                             urgentCalled > 0 &&
                             normalWaiting.rows.length > 0;

    if (shouldCallNormal && normalWaiting.rows.length > 0) {
      nextTicket = normalWaiting.rows[0];
    } else if (urgentWaiting.rows.length > 0) {
      nextTicket = urgentWaiting.rows[0];
    } else if (normalWaiting.rows.length > 0) {
      nextTicket = normalWaiting.rows[0];
    }

    if (!nextTicket) {
      return res.status(404).json({ message: 'No patients waiting' });
    }

    // Call the next ticket
    const result = await pool.query(
      `UPDATE tickets SET status = 'called'
       WHERE id = $1
       RETURNING *`,
      [nextTicket.id]
    );
    // Envoyer notification au patient
const patientResult = await pool.query(
  'SELECT name, onesignal_player_id FROM users WHERE id = $1',
  [nextTicket.user_id]
);

const playerId = patientResult.rows[0]?.onesignal_player_id;
const patientName = patientResult.rows[0]?.name;

if (playerId) {
  await sendNotificationToPatient(playerId, nextTicket.ticket_number, patientName);
}

    // Get the patient info for notification
    const patientInfo = await pool.query(
      `SELECT name, phone FROM users WHERE id = $1`,
      [nextTicket.user_id]
    );

    // Emit socket event for queue update
    emitQueueUpdate(io, id);
    
    // Emit specific event for the called patient
    io.to(`clinic_${id}`).emit('patient_called', {
      ticketNumber: nextTicket.ticket_number,
      patientName: patientInfo.rows[0]?.name || 'Patient',
      priority: nextTicket.priority
    });

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// Get my tickets
router.get('/my', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT t.*, c.name as clinic_name
       FROM tickets t
       JOIN clinics c ON t.clinic_id = c.id
       WHERE t.user_id = $1
       ORDER BY t.created_at DESC`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;