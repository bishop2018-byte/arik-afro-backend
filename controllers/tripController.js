const pool = require('../db');

// --- 1. BOOK A TRIP ---
exports.bookTrip = async (req, res) => {
  const { client_id, driver_id, pickup_address, destination_address, currency } = req.body;
  try {
    const newTrip = await pool.query(
      "INSERT INTO trips (client_id, driver_id, pickup_address, destination_address, currency, status) VALUES ($1, $2, $3, $4, $5, 'pending') RETURNING *",
      [client_id, driver_id, pickup_address, destination_address, currency]
    );
    res.json(newTrip.rows[0]);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server error");
  }
};

// --- 2. CHECK PENDING REQUESTS (Polling) ---
exports.getPendingTrips = async (req, res) => {
  const { driver_id } = req.params;
  try {
    const trips = await pool.query(
      "SELECT trips.*, users.full_name as client_name FROM trips JOIN users ON trips.client_id = users.user_id WHERE driver_id = $1 AND status = 'pending'",
      [driver_id]
    );
    res.json(trips.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server error");
  }
};

// --- 3. ACCEPT TRIP ---
exports.acceptTrip = async (req, res) => {
  const { trip_id } = req.body;
  try {
    await pool.query("UPDATE trips SET status = 'accepted' WHERE trip_id = $1", [trip_id]);
    res.json("Trip Accepted");
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server error");
  }
};

// --- 4. START TRIP ---
exports.startTrip = async (req, res) => {
  const { trip_id } = req.body;
  try {
    await pool.query("UPDATE trips SET status = 'started' WHERE trip_id = $1", [trip_id]);
    res.json("Trip Started");
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server error");
  }
};

// --- 5. END TRIP (Calculates Fare) ---
exports.endTrip = async (req, res) => {
  const { trip_id } = req.body;
  try {
    // 1. Mark as completed
    const trip = await pool.query(
      "UPDATE trips SET status = 'completed' WHERE trip_id = $1 RETURNING *",
      [trip_id]
    );
    
    // 2. Simple Fare Calculation (You can make this complex later)
    // Base fee 500 + Random distance fee
    const fare = 500 + Math.floor(Math.random() * 1000); 
    const earnings = fare * 0.85; // Driver gets 85%

    // 3. Update Wallet (Optional step for later)
    
    res.json({
      status: "completed",
      total_fare: fare,
      driver_earnings: earnings,
      symbol: trip.rows[0].currency === 'USD' ? '$' : '₦'
    });

  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server error");
  }
};

// --- 6. GET ACTIVE TRIP (Client) ---
exports.getActiveTripForClient = async (req, res) => {
  const { id } = req.params;
  try {
    const trip = await pool.query(
      "SELECT trips.*, drivers.plate_number, drivers.car_model, users.full_name as driver_name, users.phone as driver_phone FROM trips JOIN drivers ON trips.driver_id = drivers.driver_id JOIN users ON drivers.user_id = users.user_id WHERE trips.client_id = $1 AND trips.status IN ('accepted', 'started')",
      [id]
    );
    if (trip.rows.length === 0) return res.json(null);
    res.json(trip.rows[0]);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server error");
  }
};

// --- 7. GET ACTIVE TRIP (Driver) - 🛡️ FIX HERE ---
exports.getActiveTripForDriver = async (req, res) => {
  const { id } = req.params; // This is the USER_ID from the app
  try {
    // We strictly look for 'accepted' or 'started'. 
    // We IGNORE 'completed' or 'pending'.
    const trip = await pool.query(
      "SELECT trips.*, users.full_name as client_name, users.phone as client_phone FROM trips JOIN users ON trips.client_id = users.user_id WHERE trips.driver_id = (SELECT driver_id FROM drivers WHERE user_id = $1) AND trips.status IN ('accepted', 'started')",
      [id]
    );

    if (trip.rows.length === 0) {
      return res.json(null); // ✅ Correctly tells app "No Active Trip"
    }
    
    res.json(trip.rows[0]);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server error");
  }
};

// --- 8. GET HISTORY ---
exports.getDriverHistory = async (req, res) => {
  const { id } = req.params;
  try {
    const history = await pool.query(
      "SELECT * FROM trips WHERE driver_id = (SELECT driver_id FROM drivers WHERE user_id = $1) AND status = 'completed' ORDER BY created_at DESC",
      [id]
    );
    res.json(history.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server error");
  }
};

exports.getClientHistory = async (req, res) => {
  const { id } = req.params;
  try {
    const history = await pool.query(
      "SELECT * FROM trips WHERE client_id = $1 AND status = 'completed' ORDER BY created_at DESC",
      [id]
    );
    res.json(history.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server error");
  }
};