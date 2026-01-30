const express = require('express');
const cors = require('cors');
const db = require('./db');
const authRoutes = require('./routes/authRoutes');

const app = express();
app.use(cors());
app.use(express.json());

// ✅ Advanced Health Check
// Visit https://arik-api.onrender.com/status in your browser
app.get('/status', async (req, res) => {
  try {
    await db.query('SELECT 1'); // Simple "heartbeat" query
    res.status(200).json({ 
      server: "Online", 
      database: "Connected",
      time: new Date().toISOString() 
    });
  } catch (err) {
    res.status(500).json({ 
      server: "Online", 
      database: "Disconnected", 
      error: err.message 
    });
  }
});

app.use('/api/auth', authRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server listening on port ${PORT} - server.js:33`);
});