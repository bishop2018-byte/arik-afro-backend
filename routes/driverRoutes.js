const express = require('express');
const router = express.Router();
const driverController = require('../controllers/driverController');

// Debugging line: This will print in your terminal so we can see if functions loaded
console.log("Loaded Controller Functions: - driverRoutes.js:6", Object.keys(driverController));

router.post('/update-location', driverController.updateLocation);
router.get('/nearby', driverController.getNearbyDrivers);

module.exports = router;