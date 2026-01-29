const express = require('express');
const router = express.Router();
const pool = require('../config/db');

// 1. GET ALL USERS (With Wallet Balance)
router.get('/users', async (req, res) => {
  try {
    const result = await pool.query("SELECT user_id, full_name, email, role, wallet_balance FROM users ORDER BY user_id DESC");
    res.json(result.rows);
  } catch (err) {
    res.status(500).send("Server Error");
  }
});

// 2. GET ALL TRIP HISTORY
router.get('/trips', async (req, res) => {
  try {
    // We join with users to get names instead of just IDs
    const query = `
      SELECT t.trip_id, t.pickup_address, t.destination_address, t.total_fare, t.status, t.created_at,
      c.full_name as client_name, d.full_name as driver_name
      FROM trips t
      LEFT JOIN users c ON t.client_id = c.user_id
      LEFT JOIN users d ON t.driver_id = d.user_id
      ORDER BY t.created_at DESC
    `;
    const result = await pool.query(query);
    res.json(result.rows);
  } catch (err) {
    res.status(500).send("Server Error");
  }
});

// 3. GET PENDING WITHDRAWALS (For Approval)
router.get('/withdrawals', async (req, res) => {
  try {
    const query = `
      SELECT w.id, w.amount, w.bank_name, w.account_number, w.status, u.full_name 
      FROM withdrawals w
      JOIN users u ON w.user_id = u.user_id
      WHERE w.status = 'pending'
    `;
    const result = await pool.query(query);
    res.json(result.rows);
  } catch (err) {
    res.status(500).send("Server Error");
  }
});

// 4. APPROVE WITHDRAWAL
router.post('/approve-withdrawal', async (req, res) => {
  const { withdrawal_id } = req.body;
  try {
    await pool.query("UPDATE withdrawals SET status = 'approved' WHERE id = $1", [withdrawal_id]);
    res.json({ status: "success", message: "Withdrawal Approved" });
  } catch (err) {
    res.status(500).send("Server Error");
  }
});

module.exports = router;