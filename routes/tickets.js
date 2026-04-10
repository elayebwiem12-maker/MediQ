const express = require('express');
const pool = require('../db/pool');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Prendre un ticket
router.post('/', authenticateToken, async (req, res) => {
  const { clinic_id, type } = req.body;
  const user_id = req.user.id;
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // Numéro du ticket
    const maxTicket = await client.query(
      'SELECT COALESCE(MAX(ticket_number), 0) + 1 as next_num FROM tickets WHERE clinic_id = $1',
      [clinic_id]
    );
    const ticketNumber = maxTicket.rows[0].next_num;
    
    // Position dans la file
    const waitingCount = await client.query(
      'SELECT COUNT(*) FROM tickets WHERE clinic_id = $1 AND status = $2',
      [clinic_id, 'waiting']
    );
    const position = parseInt(waitingCount.rows[0].count) + 1;
    
    // Temps d'attente estimé
    const clinic = await client.query(
      'SELECT avg_normal_wait FROM clinics WHERE id = $1',
      [clinic_id]
    );
    const estimatedTime = (position - 1) * (clinic.rows[0].avg_normal_wait || 12);
    
    // Créer le ticket
    const result = await client.query(
      `INSERT INTO tickets (ticket_number, user_id, clinic_id, type, status, position, estimated_time)
       VALUES ($1, $2, $3, $4, 'waiting', $5, $6) RETURNING *`,
      [ticketNumber, user_id, clinic_id, type || 'normal', position, Math.max(2, estimatedTime)]
    );
    
    await client.query('COMMIT');
    res.status(201).json(result.rows[0]);
  } catch (error) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: error.message });
  } finally {
    client.release();
  }
});

// Voir la file d'attente
router.get('/clinic/:clinicId', authenticateToken, async (req, res) => {
  const { clinicId } = req.params;
  
  try {
    const result = await pool.query(
      `SELECT t.*, u.name, u.phone, c.name as clinic_name
       FROM tickets t
       JOIN users u ON t.user_id = u.id
       JOIN clinics c ON t.clinic_id = c.id
       WHERE t.clinic_id = $1 AND t.status != 'done'
       ORDER BY t.created_at ASC`,
      [clinicId]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Appeler le prochain patient
router.put('/clinic/:clinicId/call-next', authenticateToken, async (req, res) => {
  const { clinicId } = req.params;
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // Passer l'appelé à "fait"
    await client.query(
      "UPDATE tickets SET status = 'done', completed_at = NOW() WHERE clinic_id = $1 AND status = 'called'",
      [clinicId]
    );
    
    // Prendre le prochain
    const nextTicket = await client.query(
      `SELECT * FROM tickets 
       WHERE clinic_id = $1 AND status = 'waiting'
       ORDER BY created_at ASC LIMIT 1`,
      [clinicId]
    );
    
    if (nextTicket.rows.length > 0) {
      await client.query(
        "UPDATE tickets SET status = 'called', called_at = NOW() WHERE id = $1",
        [nextTicket.rows[0].id]
      );
    }
    
    await client.query('COMMIT');
    res.json({ success: true, ticket: nextTicket.rows[0] || null });
  } catch (error) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: error.message });
  } finally {
    client.release();
  }
});

module.exports = router;