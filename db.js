require('dotenv').config();
const { Pool } = require('pg');

let pool;

if (process.env.DATABASE_URL) {
  // ☁️ CLOUD MODE (Render)
  pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });
  console.log("🔌 Connected to CLOUD Database (Render) - db.js:12");
} else {
  // 💻 LOCAL MODE (Your Laptop)
  pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'arik_afro_db',
    password: process.env.DB_PASSWORD || 'bishop2018',
    port: process.env.DB_PORT || 5432,
  });
  console.log("🔌 Connected to LOCAL Database (Laptop) - db.js:22");
}

// ✅ Added helper to handle queries safely
module.exports = {
  query: (text, params) => pool.query(text, params),
  pool: pool 
};