require('dotenv').config();
const { Pool } = require('pg');

let pool;

if (process.env.DATABASE_URL) {
  // ☁️ CLOUD MODE (Render)
  pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
      // ✅ This is the critical line: it tells Node to trust Render's self-signed cert
      rejectUnauthorized: false 
    },
    connectionTimeoutMillis: 10000, 
  });
  console.log("🔌 Database: CLOUD mode with SSL bypass enabled. - db.js:16");
} else {
  // 💻 LOCAL MODE
  pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'arik_afro_db',
    password: process.env.DB_PASSWORD || 'bishop2018',
    port: 5432,
  });
  console.log("🔌 Database: LOCAL mode. - db.js:26");
}

module.exports = {
  query: (text, params) => pool.query(text, params),
};