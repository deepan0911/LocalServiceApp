const express = require('express');
const router = express.Router();
const {
  getWorkers, verifyWorker, getUsers, toggleUserStatus,
  getAllBookings, getAnalytics, getComplaints, resolveComplaint
} = require('../controllers/adminController');
const { protect, authorize } = require('../middleware/auth');

router.use(protect, authorize('admin'));

router.get('/workers', getWorkers);
router.put('/workers/:workerId/verify', verifyWorker);
router.get('/users', getUsers);
router.put('/users/:userId/status', toggleUserStatus);
router.get('/bookings', getAllBookings);
router.get('/analytics', getAnalytics);
router.get('/complaints', getComplaints);
router.put('/complaints/:id/resolve', resolveComplaint);

module.exports = router;
