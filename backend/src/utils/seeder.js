require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const connectDB = require('../config/database');

const seed = async () => {
  await connectDB();

  // Clear admin if exists
  await User.deleteOne({ email: process.env.ADMIN_EMAIL });

  const admin = await User.create({
    name: process.env.ADMIN_NAME || 'Admin',
    email: process.env.ADMIN_EMAIL || 'admin@localservice.com',
    phone: '9999999999',
    password: process.env.ADMIN_PASSWORD || 'Admin@1234',
    role: 'admin',
  });

  console.log(`Admin created: ${admin.email}`);
  process.exit(0);
};

seed().catch((e) => { console.error(e); process.exit(1); });
