const { Client } = require('pg');

// 👇 THIS MUST BE YOUR RENDER URL (Copy from setup_db.js)
const connectionString = 'postgresql://arik_db_user:bRR6tHbVLsUdxEeTFnm1aLdM2cbmKFYv@dpg-d5tshc7gi27c738olmsg-a.frankfurt-postgres.render.com/arik_db?ssl=true';

const client = new Client({
  connectionString: connectionString,
  ssl: { rejectUnauthorized: false }
});

const updateTables = async () => {
  try {
    await client.connect();
    console.log("🔌 Connected! Updating Database...");

    // 1. Add PHONE column to Users table
    try {
        await client.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);`);
        console.log("✅ Added 'phone' column.");
    } catch(e) { console.log("Phone check passed."); }

    // 2. Add DRIVERS table
    await client.query(`
      CREATE TABLE IF NOT EXISTS drivers (
        driver_id SERIAL PRIMARY KEY,
        user_id INT REFERENCES users(user_id),
        car_model VARCHAR(100),
        plate_number VARCHAR(20),
        license_number VARCHAR(50),
        is_verified BOOLEAN DEFAULT FALSE
      );
    `);
    console.log("✅ Created 'drivers' table.");
    console.log("🎉 Database Sync Complete!");
  } catch (err) {
    console.error("❌ Error:", err);
  } finally {
    await client.end();
  }
};

updateTables();