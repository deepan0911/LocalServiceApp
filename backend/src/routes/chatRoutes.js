const express = require('express');
const router = express.Router();
const { getChatHistory, sendMessage } = require('../controllers/chatController');
const { protect } = require('../middleware/auth');
const { upload } = require('../config/cloudinary');

router.get('/:bookingId', protect, getChatHistory);
router.post('/:bookingId', protect, upload.single('image'), sendMessage);

module.exports = router;
