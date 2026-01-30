require('dotenv').config();
const { Pool } = require('pg');

const isRenderInternal = process.env.DATABASE_URL && process.env.DATABASE_URL.includes('.internal');

const poolConfig = {
  connectionString: process.env.DATABASE_URL,
};

// ✅ Only use SSL if we are NOT on the internal network
if (process.env.DATABASE_URL && !isRenderInternal) {
  poolConfig.ssl = {
    rejectUnauthorized: false
  };
}

const pool = new Pool(poolConfig);

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client - db.js:20', err);
});

console.log(isRenderInternal ? "🛡️ Using INTERNAL Private Network (No SSL) - db.js:23" : "☁️ Using EXTERNAL Network (SSL Enabled)");

module.exports = {
  query: (text, params) => pool.query(text, params),
};