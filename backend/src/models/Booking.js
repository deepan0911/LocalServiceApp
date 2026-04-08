const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema(
  {
    customer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    worker: { type: mongoose.Schema.Types.ObjectId, ref: 'Worker', required: true },
    serviceType: {
      type: String,
      enum: [
        'Electrician',
        'Plumber',
        'Carpenter',
        'Painter',
        'AC Technician',
        'Cleaning',
        'Pest Control',
        'Mason',
        'Welder',
        'Other',
      ],
      required: true,
    },
    description: { type: String, required: true, maxlength: 1000 },
    images: [String], // Cloudinary URLs

    // Location
    address: {
      street: { type: String, required: true },
      city: { type: String, required: true },
      state: String,
      pincode: String,
      coordinates: {
        lat: Number,
        lng: Number,
      },
    },

    scheduledAt: { type: Date, required: true },

    status: {
      type: String,
      enum: [
        'pending',    // waiting for worker response
        'accepted',   // worker accepted
        'rejected',   // worker rejected
        'in_progress',// service started
        'completed',  // service done
        'cancelled',  // cancelled by customer
      ],
      default: 'pending',
    },

    // Only revealed after acceptance
    customerPhone: { type: String },
    customerFullAddress: { type: String },

    // Payment
    estimatedCost: { type: Number },
    finalCost: { type: Number },
    paymentStatus: { type: String, enum: ['unpaid', 'paid'], default: 'unpaid' },
    paymentMethod: { type: String, enum: ['cash', 'online', ''], default: '' },

    // Review (by customer after completion)
    review: {
      rating: { type: Number, min: 1, max: 5 },
      comment: { type: String, maxlength: 500 },
      createdAt: Date,
    },

    // Timestamps for status changes
    acceptedAt: Date,
    startedAt: Date,
    completedAt: Date,
    cancelledAt: Date,
    cancellationReason: String,
  },
  { timestamps: true }
);

module.exports = mongoose.model('Booking', bookingSchema);
