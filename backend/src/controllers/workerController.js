const Worker = require('../models/Worker');
const User = require('../models/User');

// @desc    Get all approved + available workers (optionally filter by skill)
// @route   GET /api/workers
const getWorkers = async (req, res, next) => {
  try {
    const { skill, page = 1, limit = 20 } = req.query;
    const filter = { status: 'approved', isAvailable: true };
    if (skill) filter.skills = skill;

    const workers = await Worker.find(filter)
      .populate('user', 'name phone profileImage address')
      .sort({ avgRating: -1, experience: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit));

    const total = await Worker.countDocuments(filter);
    res.json({ success: true, data: workers, total, page: Number(page), pages: Math.ceil(total / limit) });
  } catch (err) {
    next(err);
  }
};

// @desc    Get a single worker profile
// @route   GET /api/workers/:id
const getWorkerById = async (req, res, next) => {
  try {
    const worker = await Worker.findById(req.params.id).populate('user', 'name phone profileImage address');
    if (!worker) return res.status(404).json({ success: false, message: 'Worker not found' });
    res.json({ success: true, data: worker });
  } catch (err) {
    next(err);
  }
};

// @desc    Get my worker profile
// @route   GET /api/workers/me
const getMyWorkerProfile = async (req, res, next) => {
  try {
    const worker = await Worker.findOne({ user: req.user._id }).populate('user', 'name phone profileImage address email');
    if (!worker) return res.status(404).json({ success: false, message: 'Worker profile not found' });
    res.json({ success: true, data: worker });
  } catch (err) {
    next(err);
  }
};

// @desc    Update worker availability
// @route   PUT /api/workers/availability
const updateAvailability = async (req, res, next) => {
  try {
    const { isAvailable } = req.body;
    const worker = await Worker.findOneAndUpdate(
      { user: req.user._id },
      { isAvailable },
      { new: true }
    );
    if (!worker) return res.status(404).json({ success: false, message: 'Worker not found' });
    res.json({ success: true, data: worker });
  } catch (err) {
    next(err);
  }
};

// @desc    Update worker profile
// @route   PUT /api/workers/profile
const updateWorkerProfile = async (req, res, next) => {
  try {
    const { skills, experience, bio, serviceRadius } = req.body;
    const worker = await Worker.findOneAndUpdate(
      { user: req.user._id },
      { skills, experience, bio, serviceRadius },
      { new: true, runValidators: true }
    );
    res.json({ success: true, data: worker });
  } catch (err) {
    next(err);
  }
};

module.exports = { getWorkers, getWorkerById, getMyWorkerProfile, updateAvailability, updateWorkerProfile };
