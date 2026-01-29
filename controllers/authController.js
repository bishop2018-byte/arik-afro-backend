// 👇 CHECK THIS PATH! If your db.js is in the main folder, use '../db'
const pool = require('../db'); 
const bcrypt = require('bcryptjs');

// --- REGISTER ---
exports.registerUser = async (req, res) => {
  // Destructure the input
  const { full_name, email, password, phone, role } = req.body;

  try {
    // 1. Check if user exists
    const userExist = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
    if (userExist.rows.length > 0) {
      return res.status(400).send("User already exists");
    }

    // 2. Encrypt Password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 3. Create User 
    // ⚠️ FIXED: Changed 'password_hash' to 'password' to match your database
    const newUser = await pool.query(
      "INSERT INTO users (full_name, email, password, phone, role, wallet_balance) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *",
      [full_name, email, hashedPassword, phone, role, 0.00]
    );

    // 4. Auto-create basic driver entry (Only if role is driver)
    if (role === 'driver') {
      await pool.query(
        "INSERT INTO drivers (user_id, car_model, plate_number) VALUES ($1, 'Toyota', 'ABC-123')",
        [newUser.rows[0].user_id]
      );
    }

    res.status(201).json(newUser.rows[0]);

  } catch (err) {
    console.error("❌ Register Error:", err.message);
    res.status(500).send("Server Error: " + err.message);
  }
};

// --- LOGIN ---
exports.loginUser = async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await pool.query("SELECT * FROM users WHERE email = $1", [email]);

    if (user.rows.length === 0) {
      return res.status(401).json("Invalid Credential");
    }

    // ⚠️ FIXED: Changed 'password_hash' to 'password'
    const validPassword = await bcrypt.compare(password, user.rows[0].password);
    
    if (!validPassword) {
      return res.status(401).json("Invalid Credential");
    }

    res.json(user.rows[0]);

  } catch (err) {
    console.error("❌ Login Error:", err.message);
    res.status(500).send("Server Error");
  }
};