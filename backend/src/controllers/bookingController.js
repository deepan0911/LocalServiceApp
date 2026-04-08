const Booking = require('../models/Booking');
const Worker = require('../models/Worker');
const User = require('../models/User');
const { sendNotification } = require('../config/firebase');

// @desc    Create booking (customer)
// @route   POST /api/bookings
const createBooking = async (req, res, next) => {
  try {
    const { workerId, serviceType, description, address, scheduledAt } = req.body;

    const worker = await Worker.findById(workerId).populate('user', 'fcmToken name');
    if (!worker || worker.status !== 'approved' || !worker.isAvailable) {
      return res.status(400).json({ success: false, message: 'Worker not available' });
    }

    const imageUrls = req.files ? req.files.map((f) => f.path) : [];

    const booking = await Booking.create({
      customer: req.user._id,
      worker: workerId,
      serviceType,
      description,
      address,
      scheduledAt,
      images: imageUrls,
      customerPhone: req.user.phone,
      customerFullAddress: `${address.street}, ${address.city}`,
    });

    // Notify worker
    if (worker.user?.fcmToken) {
      await sendNotification(worker.user.fcmToken, 'New Booking Request', `${req.user.name} wants to book ${serviceType}`, { bookingId: booking._id.toString() });
    }

    res.status(201).json({ success: true, data: booking });
  } catch (err) {
    next(err);
  }
};

// @desc    Get bookings for customer
// @route   GET /api/bookings/customer
const getCustomerBookings = async (req, res, next) => {
  try {
    const { status, page = 1, limit = 10 } = req.query;
    const filter = { customer: req.user._id };
    if (status) filter.status = status;

    const bookings = await Booking.find(filter)
      .populate({ path: 'worker', populate: { path: 'user', select: 'name phone profileImage' } })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit));

    const total = await Booking.countDocuments(filter);
    res.json({ success: true, data: bookings, total });
  } catch (err) {
    next(err);
  }
};

// @desc    Get bookings for logged-in worker
// @route   GET /api/bookings/worker
const getWorkerBookings = async (req, res, next) => {
  try {
    const worker = await Worker.findOne({ user: req.user._id });
    if (!worker) return res.status(404).json({ success: false, message: 'Worker profile not found' });

    const { status, page = 1, limit = 10 } = req.query;
    const filter = { worker: worker._id };
    if (status) filter.status = status;

    const bookings = await Booking.find(filter)
      .populate('customer', 'name profileImage')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit));

    const total = await Booking.countDocuments(filter);
    res.json({ success: true, data: bookings, total });
  } catch (err) {
    next(err);
  }
};

// @desc    Get single booking
// @route   GET /api/bookings/:id
const getBookingById = async (req, res, next) => {
  try {
    const booking = await Booking.findById(req.params.id)
      .populate('customer', 'name profileImage phone address')
      .populate({ path: 'worker', populate: { path: 'user', select: 'name phone profileImage' } });

    if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

    // Only customer or worker of this booking can view it
    const worker = await Worker.findOne({ user: req.user._id });
    const isCustomer = booking.customer._id.toString() === req.user._id.toString();
    const isWorker = worker && booking.worker._id.toString() === worker._id.toString();
    const isAdmin = req.user.role === 'admin';

    if (!isCustomer && !isWorker && !isAdmin) {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }

    // Hide sensitive info unless accepted
    const data = booking.toObject();
    if (!isAdmin && !isWorker) {
      // customer can always see everything
    } else if (isWorker && booking.status === 'pending') {
      delete data.customerPhone;
      delete data.customerFullAddress;
    }

    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
};

// @desc    Worker accepts or rejects booking
// @route   PUT /api/bookings/:id/respond
const respondToBooking = async (req, res, next) => {
  try {
    const { action, rejectionReason } = req.body; // action: 'accept' | 'reject'
    const worker = await Worker.findOne({ user: req.user._id });
    const booking = await Booking.findById(req.params.id).populate('customer', 'fcmToken name');

    if (!booking || booking.worker.toString() !== worker._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }
    if (booking.status !== 'pending') {
      return res.status(400).json({ success: false, message: 'Booking is not pending' });
    }

    if (action === 'accept') {
      booking.status = 'accepted';
      booking.acceptedAt = new Date();
    } else {
      booking.status = 'rejected';
      booking.cancellationReason = rejectionReason;
    }
    await booking.save();

    // Notify customer
    if (booking.customer?.fcmToken) {
      await sendNotification(
        booking.customer.fcmToken,
        action === 'accept' ? 'Booking Accepted!' : 'Booking Rejected',
        action === 'accept' ? 'Worker has accepted your booking.' : `Worker rejected: ${rejectionReason}`,
        { bookingId: booking._id.toString() }
      );
    }

    res.json({ success: true, data: booking });
  } catch (err) {
    next(err);
  }
};

// @desc    Mark booking as in_progress / completed
// @route   PUT /api/bookings/:id/status
const updateBookingStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const booking = await Booking.findById(req.params.id).populate('customer', 'fcmToken');

    if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

    booking.status = status;
    if (status === 'in_progress') booking.startedAt = new Date();
    if (status === 'completed') {
      booking.completedAt = new Date();
      // Bump worker total bookings
      await Worker.findByIdAndUpdate(booking.worker, { $inc: { totalBookings: 1 } });
    }
    await booking.save();

    if (booking.customer?.fcmToken) {
      await sendNotification(booking.customer.fcmToken, 'Service Update', `Booking status: ${status}`, { bookingId: booking._id.toString() });
    }

    res.json({ success: true, data: booking });
  } catch (err) {
    next(err);
  }
};

// @desc    Customer cancels booking
// @route   PUT /api/bookings/:id/cancel
const cancelBooking = async (req, res, next) => {
  try {
    const { reason } = req.body;
    const booking = await Booking.findOne({ _id: req.params.id, customer: req.user._id });
    if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });
    if (!['pending', 'accepted'].includes(booking.status)) {
      return res.status(400).json({ success: false, message: 'Cannot cancel at this stage' });
    }
    booking.status = 'cancelled';
    booking.cancelledAt = new Date();
    booking.cancellationReason = reason;
    await booking.save();
    res.json({ success: true, data: booking });
  } catch (err) {
    next(err);
  }
};

// @desc    Submit review after completion
// @route   POST /api/bookings/:id/review
const submitReview = async (req, res, next) => {
  try {
    const { rating, comment } = req.body;
    const booking = await Booking.findOne({ _id: req.params.id, customer: req.user._id, status: 'completed' });
    if (!booking) return res.status(404).json({ success: false, message: 'Completed booking not found' });
    if (booking.review?.rating) return res.status(400).json({ success: false, message: 'Review already submitted' });

    booking.review = { rating, comment, createdAt: new Date() };
    await booking.save();

    // Update worker avg rating
    const worker = await Worker.findById(booking.worker);
    const newTotal = worker.totalRatings + 1;
    const newAvg = ((worker.avgRating * worker.totalRatings) + rating) / newTotal;
    worker.avgRating = Math.round(newAvg * 10) / 10;
    worker.totalRatings = newTotal;
    await worker.save();

    res.json({ success: true, data: booking });
  } catch (err) {
    next(err);
  }
};

module.exports = { createBooking, getCustomerBookings, getWorkerBookings, getBookingById, respondToBooking, updateBookingStatus, cancelBooking, submitReview };
