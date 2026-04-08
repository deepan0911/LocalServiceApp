const Message = require('../models/Message');
const Booking = require('../models/Booking');
const Worker = require('../models/Worker');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const initSocket = (io) => {
  // Auth middleware for socket
  io.use(async (socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) return next(new Error('Authentication error'));
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.user = await User.findById(decoded.id).select('-password');
      next();
    } catch (e) {
      next(new Error('Authentication error'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`Socket connected: ${socket.user.name} (${socket.user._id})`);

    // Join a booking room for 1-to-1 chat
    socket.on('join_booking', async ({ bookingId }) => {
      const booking = await Booking.findById(bookingId);
      if (!booking) return socket.emit('error', 'Booking not found');

      const worker = await Worker.findOne({ user: socket.user._id });
      const isCustomer = booking.customer.toString() === socket.user._id.toString();
      const isWorker = worker && booking.worker.toString() === worker._id.toString();

      if (!isCustomer && !isWorker) return socket.emit('error', 'Access denied');

      socket.join(`booking_${bookingId}`);
      socket.emit('joined', { bookingId });
    });

    // Send text message
    socket.on('send_message', async ({ bookingId, content }) => {
      try {
        const booking = await Booking.findById(bookingId);
        if (!booking) return;

        const worker = await Worker.findOne({ user: socket.user._id });
        const isCustomer = booking.customer.toString() === socket.user._id.toString();
        const senderRole = isCustomer ? 'customer' : 'worker';

        const message = await Message.create({
          booking: bookingId,
          sender: socket.user._id,
          senderRole,
          content,
          type: 'text',
        });

        await message.populate('sender', 'name profileImage');

        io.to(`booking_${bookingId}`).emit('new_message', message);
      } catch (e) {
        socket.emit('error', e.message);
      }
    });

    // Typing indicators
    socket.on('typing', ({ bookingId }) => {
      socket.to(`booking_${bookingId}`).emit('user_typing', {
        userId: socket.user._id,
        name: socket.user.name,
      });
    });
    socket.on('stop_typing', ({ bookingId }) => {
      socket.to(`booking_${bookingId}`).emit('user_stop_typing', { userId: socket.user._id });
    });

    // Online presence
    socket.on('go_online', () => {
      socket.broadcast.emit('user_online', { userId: socket.user._id });
    });

    socket.on('disconnect', async () => {
      await User.findByIdAndUpdate(socket.user._id, { lastSeen: new Date() });
      console.log(`Socket disconnected: ${socket.user.name}`);
    });
  });
};

module.exports = initSocket;
