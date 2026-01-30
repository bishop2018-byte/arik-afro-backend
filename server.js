const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const authRoutes = require('./routes/authRoutes');
const pool = require('./db');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// simple uptime health
app.get('/', (req, res) => res.status(200).send('Arik Afro API is Live and Running!'));

// DB-aware health endpoint
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    return res.json({ status: 'ok', db: 'connected' });
  } catch (err) {
    console.error('Health check DB error: - server.js:22', err.message || err);
    return res.status(500).json({ status: 'fail', db: 'error', error: err.message || err });
  }
});

app.use('/api/auth', authRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT} - server.js:31`);
  console.log(`ENV: DATABASE_URL ${process.env.DATABASE_URL ? 'SET' : 'NOT SET'} - server.js:32`);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at: - server.js:36', promise, 'reason:', reason);
});
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception thrown: - server.js:39', err);
});