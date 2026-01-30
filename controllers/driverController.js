// ✅ UPDATED: Supports turning status ON and OFF
exports.updateLocation = async (req, res) => {
  const { user_id, latitude, longitude, is_online } = req.body;

  try {
    // 1. Update location AND the online status (variable status)
    const updateDriver = await pool.query(
      'UPDATE drivers SET latitude = $1, longitude = $2, is_online = $3 WHERE user_id = $4 RETURNING *',
      [latitude, longitude, is_online, user_id]
    );

    if (updateDriver.rows.length === 0) {
      // ⚠️ This happens if the user_id doesn't exist in the 'drivers' table
      console.log(`Driver ID ${user_id} not found in drivers table. - driverController.js:14`);
      return res.status(404).json({ error: 'Driver record not found. Please register as a driver.' });
    }

    res.json({ message: 'Status updated successfully', driver: updateDriver.rows[0] });

  } catch (err) {
    console.error("DATABASE ERROR: - driverController.js:21", err.message);
    res.status(500).json({ error: 'Server error: Check database columns' });
  }
};