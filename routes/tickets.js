const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const authenticateToken = require('../middleware/auth');
const { sendNotificationToPatient } = require('../services/notification');

// Helper function to emit queue updates
const emitQueueUpdate = (io, clinicId) => {
  io.to('clinic_' + clinicId).emit('queue_updated', { 
    clinicId, 
    timestamp: new Date().toISOString(),
    message: 'La file d\'attente a ete mise a jour'
  });
};

// Prendre un ticket
router.post('/', authenticateToken, async (req, res) => {
  const io = req.app.get('io');
  
  try {
    const { clinic_id, priority } = req.body;
    const user_id = req.user.id;

    const maxResult = await pool.query(
      'SELECT COALESCE(MAX(ticket_number), 0) as max_num FROM tickets WHERE clinic_id = $1 AND DATE(created_at) = CURRENT_DATE',
      [clinic_id]
    );

    const ticketNumber = maxResult.rows[0].max_num + 1;

    const posResult = await pool.query(
      'SELECT COUNT(*) as count FROM tickets WHERE clinic_id = $1 AND status = $2 AND DATE(created_at) = CURRENT_DATE',
      [clinic_id, 'waiting']
    );

    const position = parseInt(posResult.rows[0].count) + 1;
    const estimatedTime = position * 7;

    const result = await pool.query(
      'INSERT INTO tickets (user_id, clinic_id, ticket_number, priority, status, position, estimated_time) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
      [user_id, clinic_id, ticketNumber, priority || 'normal', 'waiting', position, estimatedTime]
    );

    emitQueueUpdate(io, clinic_id);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// Recuperer la file d'attente
router.get('/clinic/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      'SELECT t.*, u.name as patient_name, u.phone as patient_phone FROM tickets t JOIN users u ON t.user_id = u.id WHERE t.clinic_id = $1 AND DATE(t.created_at) = CURRENT_DATE ORDER BY CASE t.status WHEN $2 THEN 1 WHEN $3 THEN 2 WHEN $4 THEN 3 END, CASE t.priority WHEN $5 THEN 1 WHEN $6 THEN 2 END, t.ticket_number ASC',
      [id, 'called', 'waiting', 'done', 'urgent', 'normal']
    );

    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// Appeler le suivant normalement (FIFO)
router.put('/clinic/:id/call-next', authenticateToken, async (req, res) => {
  const io = req.app.get('io');
  
  try {
    const { id } = req.params;

    const normalCalledResult = await pool.query(
      'SELECT COUNT(*) as count FROM tickets WHERE clinic_id = $1 AND status IN ($2, $3) AND priority = $4 AND DATE(created_at) = CURRENT_DATE',
      [id, 'called', 'done', 'normal']
    );

    const urgentCalledResult = await pool.query(
      'SELECT COUNT(*) as count FROM tickets WHERE clinic_id = $1 AND status IN ($2, $3) AND priority = $4 AND DATE(created_at) = CURRENT_DATE',
      [id, 'called', 'done', 'urgent']
    );

    const normalCalled = parseInt(normalCalledResult.rows[0].count);
    const urgentCalled = parseInt(urgentCalledResult.rows[0].count);

    const urgentWaiting = await pool.query(
      'SELECT * FROM tickets WHERE clinic_id = $1 AND status = $2 AND priority = $3 AND DATE(created_at) = CURRENT_DATE ORDER BY ticket_number ASC LIMIT 1',
      [id, 'waiting', 'urgent']
    );

    const normalWaiting = await pool.query(
      'SELECT * FROM tickets WHERE clinic_id = $1 AND status = $2 AND priority = $3 AND DATE(created_at) = CURRENT_DATE ORDER BY ticket_number ASC LIMIT 1',
      [id, 'waiting', 'normal']
    );

    await pool.query(
      'UPDATE tickets SET status = $1 WHERE clinic_id = $2 AND status = $3',
      ['done', id, 'called']
    );

    let nextTicket = null;

    const shouldCallNormal = normalCalled > 0 && normalCalled % 3 === 0 && urgentCalled > 0 && normalWaiting.rows.length > 0;

    if (shouldCallNormal && normalWaiting.rows.length > 0) {
      nextTicket = normalWaiting.rows[0];
    } else if (urgentWaiting.rows.length > 0) {
      nextTicket = urgentWaiting.rows[0];
    } else if (normalWaiting.rows.length > 0) {
      nextTicket = normalWaiting.rows[0];
    }

    if (!nextTicket) {
      return res.status(404).json({ message: 'Aucun patient en attente' });
    }

    const result = await pool.query(
      'UPDATE tickets SET status = $1 WHERE id = $2 RETURNING *',
      ['called', nextTicket.id]
    );

    // Envoyer notification au patient
    const patientResult = await pool.query(
      'SELECT name, onesignal_player_id FROM users WHERE id = $1',
      [nextTicket.user_id]
    );

    const playerId = patientResult.rows[0]?.onesignal_player_id;
    const patientName = patientResult.rows[0]?.name;

    if (playerId) {
      await sendNotificationToPatient(playerId, nextTicket.ticket_number, patientName, nextTicket.priority);
    }

    const patientInfo = await pool.query(
      'SELECT name, phone FROM users WHERE id = $1',
      [nextTicket.user_id]
    );

    emitQueueUpdate(io, id);
    
    io.to('clinic_' + id).emit('patient_called', {
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

// Appeler un patient urgent en priorite
router.put('/clinic/:id/call-urgent', authenticateToken, async (req, res) => {
  const io = req.app.get('io');
  
  try {
    const { id } = req.params;

    await pool.query(
      'UPDATE tickets SET status = $1 WHERE clinic_id = $2 AND status = $3',
      ['done', id, 'called']
    );

    const urgentWaiting = await pool.query(
      'SELECT * FROM tickets WHERE clinic_id = $1 AND status = $2 AND priority = $3 AND DATE(created_at) = CURRENT_DATE ORDER BY ticket_number ASC LIMIT 1',
      [id, 'waiting', 'urgent']
    );

    if (urgentWaiting.rows.length === 0) {
      return res.status(404).json({ message: 'Aucun patient urgent en attente' });
    }

    const result = await pool.query(
      'UPDATE tickets SET status = $1 WHERE id = $2 RETURNING *',
      ['called', urgentWaiting.rows[0].id]
    );

    // Envoyer notification au patient urgent
    const patientResult = await pool.query(
      'SELECT name, onesignal_player_id FROM users WHERE id = $1',
      [urgentWaiting.rows[0].user_id]
    );

    const playerId = patientResult.rows[0]?.onesignal_player_id;
    const patientName = patientResult.rows[0]?.name;

    if (playerId) {
      await sendNotificationToPatient(playerId, urgentWaiting.rows[0].ticket_number, patientName, 'urgent');
    }

    const patientInfo = await pool.query(
      'SELECT name, phone FROM users WHERE id = $1',
      [urgentWaiting.rows[0].user_id]
    );

    emitQueueUpdate(io, id);
    
    io.to('clinic_' + id).emit('patient_called', {
      ticketNumber: urgentWaiting.rows[0].ticket_number,
      patientName: patientInfo.rows[0]?.name || 'Patient',
      priority: 'urgent'
    });

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// Historique des tickets du patient
router.get('/my', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT t.*, c.name as clinic_name FROM tickets t JOIN clinics c ON t.clinic_id = c.id WHERE t.user_id = $1 ORDER BY t.created_at DESC',
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;