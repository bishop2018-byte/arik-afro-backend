const pool = require('../db');

// 1. UPDATE LOCATION FUNCTION
const updateLocation = async (req, res) => {
  const { user_id, latitude, longitude, is_online } = req.body;
  try {
    const updateDriver = await pool.query(
      'UPDATE drivers SET latitude = $1, longitude = $2, is_online = $3 WHERE user_id = $4 RETURNING *',
      [latitude, longitude, is_online, user_id]
    );

    if (updateDriver.rows.length === 0) {
      return res.status(404).json({ error: 'Driver record not found.' });
    }
    res.json({ message: 'Status updated', driver: updateDriver.rows[0] });
  } catch (err) {
    console.error("DB ERROR: - driverController.js:17", err.message);
    res.status(500).json({ error: 'Server error' });
  }
};

// 2. GET NEARBY DRIVERS FUNCTION
const getNearbyDrivers = async (req, res) => {
  const { latitude, longitude } = req.query;
  try {
    const nearbyQuery = `
      SELECT drivers.driver_id, users.full_name, drivers.latitude, drivers.longitude,
      (6371 * acos(cos(radians($1)) * cos(radians(latitude)) * cos(radians(longitude) - radians($2)) + sin(radians($1)) * sin(radians(latitude)))) AS distance
      FROM drivers
      JOIN users ON drivers.user_id = users.user_id
      WHERE drivers.is_online = TRUE 
      ORDER BY distance ASC LIMIT 10;
    `;
    const drivers = await pool.query(nearbyQuery, [latitude, longitude]);
    res.json(drivers.rows);
  } catch (err) {
    console.error("NEARBY ERROR: - driverController.js:37", err.message);
    res.status(500).json({ error: 'Server error' });
  }
};

// ✅ THE CRITICAL PART: EXPORTING BOTH
module.exports = {
  updateLocation,
  getNearbyDrivers
};