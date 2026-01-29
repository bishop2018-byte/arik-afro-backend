const pool = require('../config/db');

// --- UPDATE DRIVER LOCATION ---
exports.updateLocation = async (req, res) => {
  const { user_id, latitude, longitude } = req.body;

  try {
    // 1. Update location & Set status to Online
    const updateDriver = await pool.query(
      'UPDATE drivers SET latitude = $1, longitude = $2, is_online = TRUE WHERE user_id = $3 RETURNING *',
      [latitude, longitude, user_id]
    );

    if (updateDriver.rows.length === 0) {
      return res.status(404).json({ error: 'Driver not found' });
    }

    res.json({ message: 'Location updated', driver: updateDriver.rows[0] });

  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Server error' });
  }
};

// --- FIND NEARBY DRIVERS (NEW) ---
exports.getNearbyDrivers = async (req, res) => {
  // We expect the client's location in the URL (e.g., ?latitude=6.5&longitude=3.3)
  const { latitude, longitude } = req.query; 

  try {
    // The SQL "Haversine Formula"
    // It calculates the distance between the Client and every Driver
    // 6371 is the radius of Earth in Kilometers
    const nearbyQuery = `
      SELECT 
        drivers.driver_id, 
        users.full_name, 
        users.phone,
        drivers.latitude, 
        drivers.longitude,
        (
          6371 * acos(
            cos(radians($1)) * cos(radians(latitude)) * cos(radians(longitude) - radians($2)) + 
            sin(radians($1)) * sin(radians(latitude))
          )
        ) AS distance
      FROM drivers
      JOIN users ON drivers.user_id = users.user_id
      WHERE drivers.is_online = TRUE 
      AND drivers.is_verified = TRUE
      ORDER BY distance ASC
      LIMIT 10;
    `;

    const drivers = await pool.query(nearbyQuery, [latitude, longitude]);

    res.json(drivers.rows);

  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Server error' });
  }
};