const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

// --- MIDDLEWARE ---
app.use(cors());
app.use(express.json());

// --- ROUTES ---

// 1. Auth (Login/Register)
app.use('/api/auth', require('./routes/authRoutes'));

// 2. Driver & Trip Management
app.use('/api/drivers', require('./routes/driverRoutes'));
app.use('/api/trips', require('./routes/tripRoutes'));

// 3. Money Management
app.use('/api/wallet', require('./routes/walletRoutes'));     // Fund Wallet
app.use('/api/withdraw', require('./routes/withdrawalRoutes')); // Withdraw Funds

// 4. Admin Panel
app.use('/api/admin', require('./routes/adminRoutes'));       // Monitor Activity

// --- START SERVER ---
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));