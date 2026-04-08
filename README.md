# 🔧 Local Service Booking System

A full-stack, scalable platform connecting customers with nearby service providers (electricians, plumbers, etc.).

## 📱 Apps

| App | Description |
|-----|-------------|
| **Customer App** | Browse services, book workers, real-time chat |
| **Worker App** | Register, manage bookings, chat with customers |
| **Admin App** | Verify workers, manage platform, analytics |

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter (Dart) |
| Backend | Node.js + Express |
| Database | MongoDB (Mongoose) |
| Real-time | Socket.io |
| Auth | JWT + Bcrypt |
| Storage | Multer + Cloudinary |
| Notifications | Firebase Cloud Messaging |

## 🗂 Project Structure

```
LocalServiceApp/
├── backend/                  # Node.js + Express API
│   ├── src/
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── services/
│   │   └── utils/
│   └── package.json
├── customer_app/             # Flutter app for customers
├── worker_app/               # Flutter app for workers
├── admin_app/                # Flutter app for admins
└── README.md
```

## 🚀 Getting Started

### Backend
```bash
cd backend
npm install
cp .env.example .env   # fill in your credentials
npm run dev
```

### Flutter Apps
```bash
cd customer_app   # or worker_app / admin_app
flutter pub get
flutter run
```

## 🔑 Environment Variables

See `backend/.env.example` for required variables.

## 📖 API Docs

See `backend/API_DOCS.md` for full REST API reference.
