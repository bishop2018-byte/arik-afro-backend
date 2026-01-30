const { Client } = require('pg');

// ✅ FIXED: Using the EXTERNAL URL so your laptop can talk to Render
const connectionString = 'postgresql://arik_db_user:bRR6tHbVLsUdxEeTFnm1aLdM2cbmKFYv@dpg-d5tshc7gi27c738olmsg-a.frankfurt-postgres.render.com/arik_db?ssl=true';

const client = new Client({
  connectionString: connectionString,
  ssl: { rejectUnauthorized: false } 
});

const updateTables = async () => {
  try {
    console.log("⏳ Connecting to Render Database...");
    await client.connect();
    console.log("🔌 Connected! Checking for missing columns...");

    // 1. Add PHONE column
    await client.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);`);
    console.log("✅ Check 1: 'phone' column exists.");

    // 2. Add WALLET_BALANCE column
    await client.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS wallet_balance DECIMAL(10,2) DEFAULT 0.00;`);
    console.log("✅ Check 2: 'wallet_balance' column exists.");

    // 3. Add DRIVERS table
    await client.query(`
      CREATE TABLE IF NOT EXISTS drivers (
        driver_id SERIAL PRIMARY KEY,
        user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
        car_model VARCHAR(100),
        plate_number VARCHAR(20),
        license_number VARCHAR(50),
        is_verified BOOLEAN DEFAULT FALSE
      );
    `);
    console.log("✅ Check 3: 'drivers' table exists.");

    console.log("🎉 SUCCESS! Your Database is fully upgraded.");
  } catch (err) {
    console.error("❌ CONNECTION ERROR:", err.message);
  } finally {
    await client.end();
  }
};

updateTables();