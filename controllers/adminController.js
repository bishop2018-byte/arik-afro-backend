const pool = require('../config/db');

// --- 1. GET DASHBOARD STATS ---
exports.getStats = async (req, res) => {
  try {
    const totalUsers = await pool.query("SELECT COUNT(*) FROM users");
    const totalTrips = await pool.query("SELECT COUNT(*) FROM trips");
    // Calculate total money currently held in user wallets (Virtual Liability)
    const totalWallet = await pool.query("SELECT SUM(wallet_balance) FROM users");
    
    res.json({
      users: totalUsers.rows[0].count,
      trips: totalTrips.rows[0].count,
      wallet_liability: totalWallet.rows[0].sum || 0.00
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
};

// --- 2. GET PENDING WITHDRAWALS ---
exports.getWithdrawals = async (req, res) => {
  try {
    const requests = await pool.query(
      `SELECT w.*, u.full_name, u.email 
       FROM withdrawals w 
       JOIN users u ON w.user_id = u.user_id 
       WHERE w.status = 'pending' 
       ORDER BY w.created_at ASC`
    );
    res.json(requests.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
};

// --- 3. APPROVE WITHDRAWAL (Mark as Paid) ---
exports.approveWithdrawal = async (req, res) => {
  const { withdrawal_id } = req.body;
  try {
    // We just mark it as paid because money was already deducted when they requested it.
    await pool.query("UPDATE withdrawals SET status = 'paid' WHERE id = $1", [withdrawal_id]);
    res.json({ status: "success", message: "Withdrawal Marked as Paid" });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
};

// --- 4. VIEW ALL USERS & WALLETS ---
exports.getAllUsers = async (req, res) => {
  try {
    const users = await pool.query("SELECT user_id, full_name, email, role, wallet_balance, phone FROM users ORDER BY user_id DESC");
    res.json(users.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
};