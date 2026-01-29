require('dotenv').config();
const { Pool } = require('pg');

let pool;

// 👇 Check: Do we have a Cloud Database URL? (From Render)
if (process.env.DATABASE_URL) {
  // ☁️ CLOUD MODE (Render)
  pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false } // Required for Cloud security
  });
  console.log("🔌 Connected to CLOUD Database");

} else {
  // 💻 LOCAL MODE (Laptop)
  pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'arik_afro_db',
    password: process.env.DB_PASSWORD || 'bishop2018',
    port: process.env.DB_PORT || 5432,
  });
  console.log("🔌 Connected to LOCAL Database");
}

module.exports = pool;