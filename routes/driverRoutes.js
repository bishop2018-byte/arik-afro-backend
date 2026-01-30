const router = require('express').Router();
const driverController = require('../controllers/driverController');

// ✅ UPDATED FOR CLOUD
// Route 1: Driver sends GPS updates
// POST https://arik-api.onrender.com/api/drivers/update-location
router.post('/update-location', driverController.updateLocation);

// Route 2: Client searches for drivers
// GET https://arik-api.onrender.com/api/drivers/nearby
router.get('/nearby', driverController.getNearbyDrivers);

module.exports = router;