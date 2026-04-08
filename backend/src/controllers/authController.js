const User = require('../models/User');
const Worker = require('../models/Worker');
const { generateToken } = require('../utils/generateToken');

// @desc    Register customer
// @route   POST /api/auth/register
const registerCustomer = async (req, res, next) => {
  try {
    const { name, email, phone, password, address } = req.body;
    const user = await User.create({ name, email, phone, password, address, role: 'customer' });
    const token = generateToken(user._id, user.role);
    res.status(201).json({ success: true, token, user: { id: user._id, name, email, phone, role: user.role } });
  } catch (err) {
    next(err);
  }
};

// @desc    Register worker (with doc uploads)
// @route   POST /api/auth/register-worker
const registerWorker = async (req, res, next) => {
  try {
    const { name, email, phone, password, address, skills, experience, bio, aadhaarNumber, additionalIdType } = req.body;

    // Files are uploaded via multer/cloudinary
    const files = req.files || {};
    if (!files.aadhaarFront || !files.aadhaarBack) {
      return res.status(400).json({ success: false, message: 'Aadhaar front and back images are required' });
    }

    const user = await User.create({ name, email, phone, password, address, role: 'worker' });

    const workerData = {
      user: user._id,
      skills: JSON.parse(skills || '[]'),
      experience: experience || 0,
      bio,
      aadhaarNumber,
      aadhaarFront: files.aadhaarFront[0].path,
      aadhaarBack: files.aadhaarBack[0].path,
    };
    if (additionalIdType && files.additionalId) {
      workerData.additionalIdType = additionalIdType;
      workerData.additionalIdImage = files.additionalId[0].path;
    }

    await Worker.create(workerData);
    res.status(201).json({
      success: true,
      message: 'Registration successful. Awaiting admin approval.',
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Login (customer / worker / admin)
// @route   POST /api/auth/login
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ success: false, message: 'Email and password are required' });

    const user = await User.findOne({ email }).select('+password');
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    if (!user.isActive) return res.status(403).json({ success: false, message: 'Account deactivated' });

    // For workers, check approval
    if (user.role === 'worker') {
      const worker = await Worker.findOne({ user: user._id });
      if (!worker || worker.status !== 'approved') {
        return res.status(403).json({ success: false, message: `Account is ${worker?.status || 'not found'}. Please wait for admin approval.` });
      }
    }

    const token = generateToken(user._id, user.role);
    res.json({ success: true, token, user: { id: user._id, name: user.name, email: user.email, phone: user.phone, role: user.role } });
  } catch (err) {
    next(err);
  }
};

// @desc    Get current user profile
// @route   GET /api/auth/me
const getMe = async (req, res) => {
  res.json({ success: true, user: req.user });
};

// @desc    Update FCM token
// @route   PUT /api/auth/fcm-token
const updateFcmToken = async (req, res, next) => {
  try {
    await User.findByIdAndUpdate(req.user._id, { fcmToken: req.body.fcmToken });
    res.json({ success: true, message: 'FCM token updated' });
  } catch (err) {
    next(err);
  }
};

module.exports = { registerCustomer, registerWorker, login, getMe, updateFcmToken };
