const Message = require('../models/Message');
const Booking = require('../models/Booking');
const Worker = require('../models/Worker');

// @desc    Get chat history for a booking
// @route   GET /api/chat/:bookingId
const getChatHistory = async (req, res, next) => {
  try {
    const { bookingId } = req.params;
    const booking = await Booking.findById(bookingId);
    if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

    // Authorize: customer or worker of booking
    const worker = await Worker.findOne({ user: req.user._id });
    const isCustomer = booking.customer.toString() === req.user._id.toString();
    const isWorker = worker && booking.worker.toString() === worker._id.toString();
    if (!isCustomer && !isWorker && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }

    const messages = await Message.find({ booking: bookingId })
      .populate('sender', 'name profileImage')
      .sort({ createdAt: 1 });

    // Mark unread messages as read
    await Message.updateMany(
      { booking: bookingId, sender: { $ne: req.user._id }, isRead: false },
      { isRead: true }
    );

    res.json({ success: true, data: messages });
  } catch (err) {
    next(err);
  }
};

// @desc    Send a text/image message (REST fallback, socket is primary)
// @route   POST /api/chat/:bookingId
const sendMessage = async (req, res, next) => {
  try {
    const { bookingId } = req.params;
    const { content } = req.body;
    const imageUrl = req.file ? req.file.path : null;

    const booking = await Booking.findById(bookingId);
    if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

    const worker = await Worker.findOne({ user: req.user._id });
    const isCustomer = booking.customer.toString() === req.user._id.toString();
    const senderRole = isCustomer ? 'customer' : 'worker';

    const message = await Message.create({
      booking: bookingId,
      sender: req.user._id,
      senderRole,
      content,
      image: imageUrl,
      type: imageUrl ? 'image' : 'text',
    });

    res.status(201).json({ success: true, data: message });
  } catch (err) {
    next(err);
  }
};

module.exports = { getChatHistory, sendMessage };
