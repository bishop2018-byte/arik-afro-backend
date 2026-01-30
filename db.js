require('dotenv').config();
const { Pool } = require('pg');

let pool;

if (process.env.DATABASE_URL) {
  pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  console.log('🔌 DB: Using cloud DATABASE_URL (ssl enabled) - db.js:11');
} else {
  pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'arik_afro_db',
    password: process.env.DB_PASSWORD || 'bishop2018',
    port: process.env.DB_PORT || 5432,
  });
  console.log('🔌 DB: Using local DB settings - db.js:20');
}

pool
  .connect()
  .then((client) => {
    client.release();
    console.log('✅ Database connection successful - db.js:27');
  })
  .catch((err) => {
    console.error('❌ Database connection failed: - db.js:30', err.message || err);
  });

module.exports = pool;