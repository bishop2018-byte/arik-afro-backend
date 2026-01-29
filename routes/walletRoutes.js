const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const axios = require('axios');

// 🔑 REPLACE THIS WITH YOUR PAYSTACK SECRET KEY (When you get one)
const PAYSTACK_SECRET_KEY = 'sk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxx'; 

// --- VERIFY PAYMENT & FUND WALLET ---
router.post('/fund', async (req, res) => {
  const { user_id, reference, amount } = req.body; // Amount is in KOBO

  try {
    let status = 'failed';

    // ✅ 1. BYPASS LOGIC: Check if this is a simulation
    if (reference && reference.startsWith('TEST_')) {
      console.log(`[TEST MODE] Approving transaction: ${reference}`);
      status = 'success';
    } 
    // ❌ 2. REAL LOGIC: (Commented out until you have an API Key)
    /*
    else {
      const verification = await axios.get(`https://api.paystack.co/transaction/verify/${reference}`, {
        headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` }
      });
      status = verification.data.data.status;
    }
    */

    if (status === 'success') {
      const nairaAmount = amount / 100; // Convert Kobo to Naira

      // 3. Add money to database
      const updatedUser = await pool.query(
        "UPDATE users SET wallet_balance = wallet_balance + $1 WHERE user_id = $2 RETURNING wallet_balance",
        [nairaAmount, user_id]
      );

      res.json({ 
        status: "success", 
        new_balance: updatedUser.rows[0].wallet_balance,
        message: "Wallet funded successfully!" 
      });
    } else {
      res.status(400).json("Payment verification failed (Are you using the Test Button?)");
    }
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
});

module.exports = router;