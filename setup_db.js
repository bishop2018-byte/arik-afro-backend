const { Client } = require('pg');

// 👇 THIS IS YOUR EXACT DATABASE KEY (I added ?ssl=true for you)
const connectionString = 'postgresql://arik_db_user:bRR6tHbVLsUdxEeTFnm1aLdM2cbmKFYv@dpg-d5tshc7gi27c738olmsg-a.frankfurt-postgres.render.com/arik_db?ssl=true';

const client = new Client({
  connectionString: connectionString,
  ssl: { rejectUnauthorized: false } 
});

const createTables = async () => {
  try {
    await client.connect();
    console.log("🔌 Connected to Cloud Database...");

    // 1. Create Users Table
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        user_id SERIAL PRIMARY KEY,
        full_name VARCHAR(100),
        email VARCHAR(100) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        role VARCHAR(20) NOT NULL,
        wallet_balance DECIMAL(10,2) DEFAULT 0.00
      );
    `);
    console.log("✅ Users Table Created");

    // 2. Create Trips Table
    await client.query(`
      CREATE TABLE IF NOT EXISTS trips (
        trip_id SERIAL PRIMARY KEY,
        client_id INT REFERENCES users(user_id),
        driver_id INT REFERENCES users(user_id),
        pickup_address TEXT,
        destination_address TEXT,
        total_fare DECIMAL(10,2),
        status VARCHAR(20) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log("✅ Trips Table Created");

    // 3. Create Withdrawals Table
    await client.query(`
      CREATE TABLE IF NOT EXISTS withdrawals (
        id SERIAL PRIMARY KEY,
        user_id INT REFERENCES users(user_id),
        amount DECIMAL(10,2),
        bank_name VARCHAR(100),
        account_number VARCHAR(20),
        status VARCHAR(20) DEFAULT 'pending'
      );
    `);
    console.log("✅ Withdrawals Table Created");

    console.log("🎉 ALL DONE! Your database is ready.");
  } catch (err) {
    console.error("❌ Error:", err);
  } finally {
    await client.end();
  }
};

createTables();