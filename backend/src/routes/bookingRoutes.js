const express = require('express');
const router = express.Router();
const {
  createBooking, getCustomerBookings, getWorkerBookings,
  getBookingById, respondToBooking, updateBookingStatus, cancelBooking, submitReview
} = require('../controllers/bookingController');
const { protect, authorize } = require('../middleware/auth');
const { upload } = require('../config/cloudinary');

router.post('/', protect, authorize('customer'), upload.array('images', 5), createBooking);
router.get('/customer', protect, authorize('customer'), getCustomerBookings);
router.get('/worker', protect, authorize('worker'), getWorkerBookings);
router.get('/:id', protect, getBookingById);
router.put('/:id/respond', protect, authorize('worker'), respondToBooking);
router.put('/:id/status', protect, authorize('worker'), updateBookingStatus);
router.put('/:id/cancel', protect, authorize('customer'), cancelBooking);
router.post('/:id/review', protect, authorize('customer'), submitReview);

module.exports = router;
