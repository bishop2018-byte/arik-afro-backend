const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// 🔍 DEBUGGING CHECK
// If these print "undefined" in your terminal, it means the controller wasn't saved correctly.
console.log("Register Function:", authController.registerUser);
console.log("Login Function:", authController.loginUser);

// ✅ THE ROUTES
// We use .registerUser and .loginUser to match the new controller code
router.post('/register', authController.registerUser);
router.post('/login', authController.loginUser);

module.exports = router;