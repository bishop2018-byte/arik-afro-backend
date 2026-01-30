const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const authRoutes = require('./routes/authRoutes');

// Load environment variables
dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// ✅ Health Check Endpoint
// Purpose: Test if the server is alive by visiting the URL in your browser
app.get('/', (req, res) => {
  res.status(200).send('Arik Afro API is Live and Running!');
});

// ✅ Routes
// This matches your Flutter calls to '${ApiConstants.baseUrl}/api/auth/...'
app.use('/api/auth', authRoutes);

// Server Setup
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT} - server.js:28`);
});