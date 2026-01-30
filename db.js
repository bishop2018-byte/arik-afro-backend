require('dotenv').config();
const { Pool } = require('pg');

const isRenderInternal = process.env.DATABASE_URL && process.env.DATABASE_URL.includes('.internal');

const poolConfig = {
  connectionString: process.env.DATABASE_URL,
};

// ✅ Use SSL for external connections (like your laptop)
if (process.env.DATABASE_URL && !isRenderInternal) {
  poolConfig.ssl = {
    rejectUnauthorized: false
  };
}

const pool = new Pool(poolConfig);

// ✅ AUTOMATIC TABLE INITIALIZATION
// This runs every time the server starts to ensure the 'drivers' table exists.
const initDB = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS drivers (
        driver_id SERIAL PRIMARY KEY,
        user_id INTEGER UNIQUE NOT NULL,
        latitude DOUBLE PRECISION,
        longitude DOUBLE PRECISION,
        is_online BOOLEAN DEFAULT FALSE,
        is_verified BOOLEAN DEFAULT TRUE,
        last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log("✅ Drivers table is verified/created! - db.js:34");
  } catch (err) {
    console.error("❌ Error initializing DB: - db.js:36", err.message);
  }
};

initDB();

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client - db.js:43', err);
});

console.log(isRenderInternal ? "🛡️ Using INTERNAL Private Network - db.js:46" : "☁️ Using EXTERNAL Network (SSL Enabled)");

// ✅ EXPORT THE FULL POOL
// This ensures driverController.js can access pool.query correctly
module.exports = pool;