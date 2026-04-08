const express = require('express');
const router = express.Router();
const { getWorkers, getWorkerById, getMyWorkerProfile, updateAvailability, updateWorkerProfile } = require('../controllers/workerController');
const { protect, authorize } = require('../middleware/auth');

router.get('/', protect, getWorkers);
router.get('/me', protect, authorize('worker'), getMyWorkerProfile);
router.put('/availability', protect, authorize('worker'), updateAvailability);
router.put('/profile', protect, authorize('worker'), updateWorkerProfile);
router.get('/:id', protect, getWorkerById);

module.exports = router;
