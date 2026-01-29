const express = require('express');
const router = express.Router();
const tripController = require('../controllers/tripController');

// 🔍 Debugging: Check if functions are loaded correctly
console.log("Trip Controller Functions:", tripController);

// --- 1. BOOKING ---
router.post('/book', tripController.bookTrip);

// --- 2. DRIVER ACTIONS ---
router.get('/pending/:driver_id', tripController.getPendingTrips);
router.post('/accept', tripController.acceptTrip);
router.post('/start', tripController.startTrip);
router.post('/end', tripController.endTrip);

// --- 3. ACTIVE TRIP CHECKS (Status) ---
router.get('/active/:id/client', tripController.getActiveTripForClient);
router.get('/active/:id/driver', tripController.getActiveTripForDriver);

// --- 4. HISTORY ---
router.get('/history/:id/driver', tripController.getDriverHistory);
router.get('/history/:id/client', tripController.getClientHistory);

module.exports = router;