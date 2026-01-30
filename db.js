require('dotenv').config();
const { Pool } = require('pg');

const isRenderInternal = process.env.DATABASE_URL && process.env.DATABASE_URL.includes('.internal');

const poolConfig = {
  connectionString: process.env.DATABASE_URL,
};

if (process.env.DATABASE_URL && !isRenderInternal) {
  poolConfig.ssl = {
    rejectUnauthorized: false
  };
}

const pool = new Pool(poolConfig);

// ✅ UPDATED INITIALIZATION: This forces the columns to be added
const initDB = async () => {
  try {
    // 1. Ensure the table exists
    await pool.query(`
      CREATE TABLE IF NOT EXISTS drivers (
        driver_id SERIAL PRIMARY KEY,
        user_id INTEGER UNIQUE NOT NULL,
        is_online BOOLEAN DEFAULT FALSE,
        is_verified BOOLEAN DEFAULT TRUE
      );
    `);

    // 2. FORCE ADD missing columns if they don't exist
    await pool.query(`ALTER TABLE drivers ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;`);
    await pool.query(`ALTER TABLE drivers ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;`);
    await pool.query(`ALTER TABLE drivers ADD COLUMN IF NOT EXISTS last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP;`);

    console.log("✅ Database Schema Updated: Latitude/Longitude columns are ready! - db.js:36");
  } catch (err) {
    console.error("❌ Error initializing DB: - db.js:38", err.message);
  }
};

initDB();

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client - db.js:45', err);
});

console.log(isRenderInternal ? "🛡️ Using INTERNAL Private Network - db.js:48" : "☁️ Using EXTERNAL Network (SSL Enabled)");

module.exports = pool;