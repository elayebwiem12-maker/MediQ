const express = require('express');
const http = require('http');
const cors = require('cors');
require('dotenv').config();

const app = express();
const server = http.createServer(app);

// Middleware
app.use(cors());
app.use(express.json());

// Routes
const authRoutes = require('./routes/auth');
const ticketRoutes = require('./routes/tickets');
const clinicRoutes = require('./routes/clinics');

app.use('/api/auth', authRoutes);
app.use('/api/tickets', ticketRoutes);
app.use('/api/clinics', clinicRoutes);

// Route de test
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'MediQ API fonctionne !' });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`✅ MediQ Backend démarré sur le port ${PORT}`);
  console.log(`📍 Test: http://localhost:${PORT}/api/health`);
});