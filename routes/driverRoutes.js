const router = require('express').Router();
const driverController = require('../controllers/driverController');

// Route 1: Driver sends GPS updates
// POST http://localhost:5000/api/drivers/update-location
router.post('/update-location', driverController.updateLocation);

// Route 2: Client searches for drivers
// GET http://localhost:5000/api/drivers/nearby
router.get('/nearby', driverController.getNearbyDrivers);

module.exports = router;