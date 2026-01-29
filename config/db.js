require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'arik_afro_db',
  password: process.env.DB_PASSWORD || 'bishop2018', // 👈 TYPE YOUR PASSWORD HERE
  port: process.env.DB_PORT || 5432,
});

module.exports = pool;