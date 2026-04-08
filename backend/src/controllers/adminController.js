const User = require('../models/User');
const Worker = require('../models/Worker');
const Booking = require('../models/Booking');
const Complaint = require('../models/Complaint');
const { sendNotification } = require('../config/firebase');

// @desc    Get all pending workers
// @route   GET /api/admin/workers?status=pending
const getWorkers = async (req, res, next) => {
  try {
    const { status = 'pending', page = 1, limit = 20 } = req.query;
    const workers = await Worker.find({ status })
      .populate('user', 'name email phone address createdAt')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit));
    const total = await Worker.countDocuments({ status });
    res.json({ success: true, data: workers, total });
  } catch (err) {
    next(err);
  }
};

// @desc    Approve / Reject worker
// @route   PUT /api/admin/workers/:workerId/verify
const verifyWorker = async (req, res, next) => {
  try {
    const { action, reason } = req.body; // action: 'approve' | 'reject'
    const worker = await Worker.findById(req.params.workerId).populate('user', 'fcmToken name');
    if (!worker) return res.status(404).json({ success: false, message: 'Worker not found' });

    if (action === 'approve') {
      worker.status = 'approved';
      worker.approvedAt = new Date();
      worker.approvedBy = req.user._id;
    } else {
      worker.status = 'rejected';
      worker.rejectionReason = reason;
    }
    await worker.save();

    // Notify worker
    if (worker.user?.fcmToken) {
      await sendNotification(
        worker.user.fcmToken,
        action === 'approve' ? 'Account Approved!' : 'Registration Rejected',
        action === 'approve'
          ? 'Your account has been approved. You can now start accepting bookings.'
          : `Your registration was rejected: ${reason}`,
        {}
      );
    }

    res.json({ success: true, data: worker });
  } catch (err) {
    next(err);
  }
};

// @desc    Get all users
// @route   GET /api/admin/users
const getUsers = async (req, res, next) => {
  try {
    const { role, page = 1, limit = 20 } = req.query;
    const filter = role ? { role } : {};
    const users = await User.find(filter).sort({ createdAt: -1 }).skip((page - 1) * limit).limit(Number(limit));
    const total = await User.countDocuments(filter);
    res.json({ success: true, data: users, total });
  } catch (err) {
    next(err);
  }
};

// @desc    Deactivate / activate user
// @route   PUT /api/admin/users/:userId/status
const toggleUserStatus = async (req, res, next) => {
  try {
    const user = await User.findById(req.params.userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    user.isActive = !user.isActive;
    await user.save();
    res.json({ success: true, data: { isActive: user.isActive } });
  } catch (err) {
    next(err);
  }
};

// @desc    Get all bookings
// @route   GET /api/admin/bookings
const getAllBookings = async (req, res, next) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const filter = status ? { status } : {};
    const bookings = await Booking.find(filter)
      .populate('customer', 'name phone')
      .populate({ path: 'worker', populate: { path: 'user', select: 'name phone' } })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit));
    const total = await Booking.countDocuments(filter);
    res.json({ success: true, data: bookings, total });
  } catch (err) {
    next(err);
  }
};

// @desc    Get platform analytics
// @route   GET /api/admin/analytics
const getAnalytics = async (req, res, next) => {
  try {
    const [totalCustomers, totalWorkers, totalBookings, pendingWorkers, activeBookings] = await Promise.all([
      User.countDocuments({ role: 'customer' }),
      Worker.countDocuments({ status: 'approved' }),
      Booking.countDocuments(),
      Worker.countDocuments({ status: 'pending' }),
      Booking.countDocuments({ status: { $in: ['pending', 'accepted', 'in_progress'] } }),
    ]);

    // Bookings by status
    const bookingsByStatus = await Booking.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]);

    // Top 5 services
    const topServices = await Booking.aggregate([
      { $group: { _id: '$serviceType', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 5 },
    ]);

    // Revenue (completed bookings with finalCost)
    const revenueData = await Booking.aggregate([
      { $match: { status: 'completed', finalCost: { $exists: true } } },
      { $group: { _id: null, totalRevenue: { $sum: '$finalCost' } } },
    ]);

    res.json({
      success: true,
      data: {
        totalCustomers,
        totalWorkers,
        totalBookings,
        pendingWorkers,
        activeBookings,
        bookingsByStatus,
        topServices,
        totalRevenue: revenueData[0]?.totalRevenue || 0,
      },
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get all complaints
// @route   GET /api/admin/complaints
const getComplaints = async (req, res, next) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const filter = status ? { status } : {};
    const complaints = await Complaint.find(filter)
      .populate('raisedBy', 'name email')
      .populate('against', 'name email')
      .populate('booking')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit));
    res.json({ success: true, data: complaints });
  } catch (err) {
    next(err);
  }
};

// @desc    Resolve complaint
// @route   PUT /api/admin/complaints/:id/resolve
const resolveComplaint = async (req, res, next) => {
  try {
    const { resolution } = req.body;
    const complaint = await Complaint.findByIdAndUpdate(
      req.params.id,
      { status: 'resolved', resolution, resolvedBy: req.user._id, resolvedAt: new Date() },
      { new: true }
    );
    res.json({ success: true, data: complaint });
  } catch (err) {
    next(err);
  }
};

module.exports = { getWorkers, verifyWorker, getUsers, toggleUserStatus, getAllBookings, getAnalytics, getComplaints, resolveComplaint };
