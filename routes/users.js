const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const authenticateToken = require('../middleware/auth');

router.post('/player-id', authenticateToken, async (req, res) => {
  const { player_id } = req.body;
  const userId = req.user.id;

  try {
    await pool.query('UPDATE users SET onesignal_player_id = $1 WHERE id = $2', [player_id, userId]);
    console.log('Player ID sauvegarde pour user:', userId);
    res.json({ success: true });
  } catch (error) {
    console.error('Erreur sauvegarde playerId:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;