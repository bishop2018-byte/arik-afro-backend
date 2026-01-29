const express = require('express');
const router = express.Router();
const pool = require('../db');

// --- REQUEST WITHDRAWAL ---
router.post('/request', async (req, res) => {
  const { user_id, amount, bank_name, account_number } = req.body;

  try {
    // 1. Check Balance
    const user = await pool.query("SELECT wallet_balance FROM users WHERE user_id = $1", [user_id]);
    const currentBalance = parseFloat(user.rows[0].wallet_balance);

    if (currentBalance < amount) {
      return res.status(400).json("Insufficient funds");
    }

    // 2. Deduct Funds Immediately (Lock it)
    await pool.query("UPDATE users SET wallet_balance = wallet_balance - $1 WHERE user_id = $2", [amount, user_id]);

    // 3. Save Request
    await pool.query(
      "INSERT INTO withdrawals (user_id, amount, bank_name, account_number) VALUES ($1, $2, $3, $4)",
      [user_id, amount, bank_name, account_number]
    );

    res.json({ status: "success", message: "Withdrawal request sent." });

  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
});

module.exports = router;