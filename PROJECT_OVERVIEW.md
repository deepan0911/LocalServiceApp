# 🔧 Local Service Booking System — Project Overview

> Full-stack, industry-grade service marketplace: 3 Flutter apps + Node.js backend.

## 📁 Final Structure

```
LocalServiceApp/
├── backend/                      ✅ Complete
│   ├── src/config/               database, cloudinary, firebase
│   ├── src/controllers/          auth, worker, booking, chat, admin
│   ├── src/middleware/           JWT auth, errorHandler
│   ├── src/models/               User, Worker, Booking, Message, Complaint
│   ├── src/routes/               5 route files
│   ├── src/services/             socketService.js (Socket.io)
│   ├── src/utils/                logger, token, seeder
│   ├── API_DOCS.md
│   └── .env
│
├── customer_app/                 ✅ Complete
│   ├── core/                     ApiClient, AppTheme, AppColors
│   ├── models/                   UserModel, WorkerModel, BookingModel, MessageModel
│   ├── providers/                Auth, Worker, Booking, Chat
│   └── screens/                  Splash, Login, Register, Home (categories),
│                                 Workers (filter+paginate), Worker Detail,
│                                 Create Booking (image attach, date pick),
│                                 Bookings (tabs), Booking Detail, Live Chat, Profile
│
├── worker_app/                   ✅ Complete
│   ├── main.dart                 Splash, Login (+register link), Dashboard,
│   │                             Bookings (chat before decide), Profile
│   └── screens/
│       ├── register_screen.dart  3-step Aadhaar registration + skills
│       └── chat_screen.dart      Real-time Socket.io chat with customer
│
└── admin_app/                    ✅ Complete
    ├── core/                     ApiClient, AdminTheme
    ├── models/                   All admin models
    ├── providers/                Auth, WorkerVerification, Bookings, Analytics, Complaints
    └── screens/                  Splash, Login (admin-only), Analytics Dashboard,
                                  Worker Verification (approve/reject + ID viewer),
                                  All Bookings (status tabs), User Management,
                                  Complaints (resolve with dialog)
```

## 🚀 Quick Start

### Backend
```bash
cd backend
# Edit .env with your MongoDB, Cloudinary, Firebase credentials
npm run dev        # starts Express + Socket.io on port 5000
npm run seed       # creates the admin account
```

### Flutter Apps
```bash
cd customer_app    # or worker_app / admin_app
flutter pub get
flutter run
```

> **Device URL:** `10.0.2.2:5000` for Android emulator · `localhost:5000` for iOS simulator

## ✅ All Features Implemented

| Feature | Status |
|---------|--------|
| JWT auth + role-based access | ✅ |
| Worker 3-step registration + Aadhaar upload | ✅ |
| Admin approve / reject with FCM notification | ✅ |
| Real-time chat (Socket.io) + image sharing + typing | ✅ |
| Privacy: customer info hidden until worker accepts | ✅ |
| Full booking lifecycle (6 statuses) | ✅ |
| Ratings & reviews with avg update | ✅ |
| Firebase push notifications | ✅ |
| Platform analytics with progress bars | ✅ |
| Complaint management + resolve flow | ✅ |
| Cloudinary image storage (docs + chat images) | ✅ |
| Worker availability toggle | ✅ |
| Paginated worker list with skill category filters | ✅ |

## ⚙️ .env Variables (backend/.env)

| Key | Purpose |
|-----|---------|
| `MONGO_URI` | MongoDB connection string |
| `JWT_SECRET` | JWT signing secret |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud |
| `CLOUDINARY_API_KEY` | Cloudinary key |
| `CLOUDINARY_API_SECRET` | Cloudinary secret |
| `FIREBASE_PROJECT_ID` | Firebase project |
| `FIREBASE_PRIVATE_KEY` | Firebase private key |
| `FIREBASE_CLIENT_EMAIL` | Firebase client email |
| `ADMIN_EMAIL` | Seeded admin email |
| `ADMIN_PASSWORD` | Seeded admin password |

## 📡 Key API Endpoints

Full reference: `backend/API_DOCS.md`

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/login` | Login (all roles) |
| POST | `/auth/register` | Customer register |
| POST | `/auth/register-worker` | Worker register (multipart) |
| GET | `/workers?skill=Electrician` | Browse workers |
| POST | `/bookings` | Create booking |
| PUT | `/bookings/:id/respond` | Worker accept/reject |
| GET | `/chat/:bookingId` | Chat history |
| GET | `/admin/analytics` | Platform stats |
| PUT | `/admin/workers/:id/verify` | Approve/reject worker |
