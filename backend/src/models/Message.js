const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
  {
    booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true },
    sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    senderRole: { type: String, enum: ['customer', 'worker'], required: true },
    content: { type: String },
    image: { type: String }, // Cloudinary URL
    type: { type: String, enum: ['text', 'image'], default: 'text' },
    isRead: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Message', messageSchema);
