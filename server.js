const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
require('dotenv').config();

const app = express();
const server = http.createServer(app);

// Configure Socket.IO with proper CORS
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true
  },
  allowEIO3: true,
  transports: ['websocket', 'polling']
});

// Enable CORS for all routes
app.use(cors({
  origin: '*',
  credentials: true
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.set('io', io);

// Add request logging
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Routes
const authRoutes = require('./routes/auth');
const ticketRoutes = require('./routes/tickets');
const clinicRoutes = require('./routes/clinics');
const userRoutes = require('./routes/users');

app.use('/api/auth', authRoutes);
app.use('/api/tickets', ticketRoutes);
app.use('/api/clinics', clinicRoutes);
app.use('/api/users', userRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'MediQ API fonctionne',
    timestamp: new Date().toISOString()
  });
});

// Test endpoint without auth
app.get('/api/test', (req, res) => {
  res.json({ message: 'Backend is accessible!' });
});

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  socket.on('join_clinic', (clinicId) => {
    socket.join('clinic_' + clinicId);
    console.log('Socket ' + socket.id + ' joined clinic ' + clinicId);
  });
  
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

const PORT = 3000;

// Bind to 0.0.0.0, not localhost
server.listen(PORT, '0.0.0.0', () => {
  console.log('Backend demarre sur le port ' + PORT);
  console.log('Accessible sur:');
  console.log('   - Local: http://localhost:' + PORT);
  console.log('   - Emulateur: http://10.0.2.2:' + PORT);
});

// Error handling
server.on('error', (error) => {
  console.error('Server error:', error);
});