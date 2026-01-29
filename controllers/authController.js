const pool = require('../config/db');
const bcrypt = require('bcryptjs');

// --- REGISTER ---
exports.registerUser = async (req, res) => {
  const { full_name, email, password, phone, role } = req.body;

  try {
    // Check if user exists
    const userExist = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
    if (userExist.rows.length > 0) {
      return res.status(400).send("User already exists");
    }

    // Encrypt Password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create User
    const newUser = await pool.query(
      "INSERT INTO users (full_name, email, password_hash, phone, role, wallet_balance) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *",
      [full_name, email, hashedPassword, phone, role, 0.00]
    );

    // Auto-create basic driver entry to prevent login errors
    if (role === 'driver') {
      await pool.query(
        "INSERT INTO drivers (user_id, car_model, plate_number) VALUES ($1, 'Toyota', 'ABC-123')",
        [newUser.rows[0].user_id]
      );
    }

    res.status(201).json(newUser.rows[0]);

  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server error");
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

    // Check Password
    const validPassword = await bcrypt.compare(password, user.rows[0].password_hash);
    if (!validPassword) {
      return res.status(401).json("Invalid Credential");
    }

    res.json(user.rows[0]);

  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server error");
  }
};