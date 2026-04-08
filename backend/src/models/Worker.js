const mongoose = require('mongoose');

const workerSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    skills: [
      {
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
      },
    ],
    experience: { type: Number, default: 0 }, // years
    bio: { type: String, maxlength: 500 },

    // Identity Verification
    aadhaarNumber: { type: String, required: true },
    aadhaarFront: { type: String, required: true }, // Cloudinary URL
    aadhaarBack: { type: String, required: true },
    additionalIdType: { type: String, enum: ['PAN', 'Passport', 'Driving License', 'Voter ID', ''] },
    additionalIdImage: { type: String },

    // Admin approval
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected', 'suspended'],
      default: 'pending',
    },
    rejectionReason: { type: String },
    approvedAt: { type: Date },
    approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

    // Availability
    isAvailable: { type: Boolean, default: false },

    // Ratings
    avgRating: { type: Number, default: 0 },
    totalRatings: { type: Number, default: 0 },
    totalBookings: { type: Number, default: 0 },

    // Service area
    serviceRadius: { type: Number, default: 10 }, // km
  },
  { timestamps: true }
);

module.exports = mongoose.model('Worker', workerSchema);
