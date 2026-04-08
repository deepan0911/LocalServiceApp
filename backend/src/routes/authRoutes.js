const express = require('express');
const router = express.Router();
const { registerCustomer, registerWorker, login, getMe, updateFcmToken } = require('../controllers/authController');
const { protect } = require('../middleware/auth');
const { upload } = require('../config/cloudinary');

router.post('/register', registerCustomer);
router.post(
  '/register-worker',
  upload.fields([
    { name: 'aadhaarFront', maxCount: 1 },
    { name: 'aadhaarBack', maxCount: 1 },
    { name: 'additionalId', maxCount: 1 },
  ]),
  registerWorker
);
router.post('/login', login);
router.get('/me', protect, getMe);
router.put('/fcm-token', protect, updateFcmToken);

module.exports = router;
