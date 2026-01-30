process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'; // 🚀 FORCE BYPASS SSL
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const pool = require('./db');

// --- 🛣️ ROUTE IMPORTS ---
const authRoutes = require('./routes/authRoutes');
const driverRoutes = require('./routes/driverRoutes'); // ✅ ADDED
const tripRoutes = require('./routes/tripRoutes');     // ✅ ADDED

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// --- 🏠 HEALTH CHECKS ---
app.get('/', (req, res) => res.status(200).send('Arik Afro API is Live and Running!'));

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    return res.json({ status: 'ok', db: 'connected' });
  } catch (err) {
    console.error('Health check DB error: - server.js:26', err.message);
    return res.status(500).json({ status: 'fail', db: 'error' });
  }
});

// --- 🔗 API ENDPOINTS ---
app.use('/api/auth', authRoutes);
app.use('/api/drivers', driverRoutes); // ✅ ADDED - This fixes the "Online" switch
app.use('/api/trips', tripRoutes);     // ✅ ADDED - This fixes the booking

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT} - server.js:38`);
});

// --- 🛡️ ERROR HANDLING ---
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection: - server.js:43', reason);
});
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception: - server.js:46', err);
});