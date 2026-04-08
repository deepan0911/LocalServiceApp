# 📡 API Documentation

Base URL: `http://localhost:5000/api`

All protected routes require: `Authorization: Bearer <token>`

---

## 🔐 Auth

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/auth/register` | ❌ | Register customer |
| POST | `/auth/register-worker` | ❌ | Register worker (multipart) |
| POST | `/auth/login` | ❌ | Login (all roles) |
| GET | `/auth/me` | ✅ | Get current user |
| PUT | `/auth/fcm-token` | ✅ | Update FCM push token |

### POST `/auth/register`
```json
{
  "name": "John Doe",
  "email": "john@email.com",
  "phone": "9876543210",
  "password": "password123",
  "address": { "street": "123 Main St", "city": "Mumbai" }
}
```

### POST `/auth/register-worker` (multipart/form-data)
```
name, email, phone, password, skills (JSON array), experience,
bio, aadhaarNumber, aadhaarFront (file), aadhaarBack (file),
additionalIdType, additionalId (file)
```

### POST `/auth/login`
```json
{ "email": "user@email.com", "password": "password123" }
```
**Response:** `{ token, user: { id, name, email, phone, role } }`

---

## 👷 Workers

| Method | Endpoint | Auth | Role | Description |
|--------|----------|------|------|-------------|
| GET | `/workers` | ✅ | Any | List approved available workers |
| GET | `/workers/me` | ✅ | worker | My worker profile |
| PUT | `/workers/availability` | ✅ | worker | Toggle availability |
| PUT | `/workers/profile` | ✅ | worker | Update bio/skills |
| GET | `/workers/:id` | ✅ | Any | Single worker profile |

**Query params for GET `/workers`:** `skill`, `page`, `limit`

---

## 📋 Bookings

| Method | Endpoint | Auth | Role | Description |
|--------|----------|------|------|-------------|
| POST | `/bookings` | ✅ | customer | Create booking |
| GET | `/bookings/customer` | ✅ | customer | My bookings |
| GET | `/bookings/worker` | ✅ | worker | Worker's bookings |
| GET | `/bookings/:id` | ✅ | Any | Single booking |
| PUT | `/bookings/:id/respond` | ✅ | worker | Accept/Reject |
| PUT | `/bookings/:id/status` | ✅ | worker | Update status |
| PUT | `/bookings/:id/cancel` | ✅ | customer | Cancel |
| POST | `/bookings/:id/review` | ✅ | customer | Submit review |

### POST `/bookings` (multipart/form-data)
```
workerId, serviceType, description, scheduledAt,
address[street], address[city], images[] (files)
```

### PUT `/bookings/:id/respond`
```json
{ "action": "accept" }
// or
{ "action": "reject", "rejectionReason": "Not available in that area" }
```

**Privacy rule:** `customerPhone` and `customerFullAddress` are **hidden** in booking response until status = `accepted`.

---

## 💬 Chat

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/chat/:bookingId` | ✅ | Load chat history |
| POST | `/chat/:bookingId` | ✅ | Send message (REST fallback) |

### Socket.io Events

Connect: `io('http://localhost:5000', { auth: { token } })`

| Event (emit) | Payload | Description |
|---|---|---|
| `join_booking` | `{ bookingId }` | Join a chat room |
| `send_message` | `{ bookingId, content }` | Send text message |
| `typing` | `{ bookingId }` | Typing indicator |
| `stop_typing` | `{ bookingId }` | Stop typing |

| Event (listen) | Payload | Description |
|---|---|---|
| `new_message` | Message object | Incoming message |
| `user_typing` | `{ userId, name }` | Someone is typing |
| `user_stop_typing` | `{ userId }` | Stopped typing |
| `joined` | `{ bookingId }` | Confirmed room join |

---

## 🛡️ Admin

> All admin routes require `role: admin` JWT

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/workers?status=pending` | List workers by status |
| PUT | `/admin/workers/:id/verify` | Approve/Reject worker |
| GET | `/admin/users?role=customer` | List users |
| PUT | `/admin/users/:id/status` | Toggle user active/inactive |
| GET | `/admin/bookings?status=pending` | All bookings |
| GET | `/admin/analytics` | Platform analytics |
| GET | `/admin/complaints?status=open` | All complaints |
| PUT | `/admin/complaints/:id/resolve` | Resolve complaint |

### PUT `/admin/workers/:id/verify`
```json
{ "action": "approve" }
// or
{ "action": "reject", "reason": "Fake documents" }
```

### GET `/admin/analytics` Response
```json
{
  "totalCustomers": 150,
  "totalWorkers": 42,
  "totalBookings": 310,
  "pendingWorkers": 5,
  "activeBookings": 20,
  "totalRevenue": 125000,
  "bookingsByStatus": [{ "_id": "completed", "count": 200 }],
  "topServices": [{ "_id": "Electrician", "count": 90 }]
}
```

---

## 📊 Status Flow

```
pending → accepted → in_progress → completed
        ↘ rejected
pending/accepted → cancelled (by customer)
```

## 🔑 Roles

| Role | Access |
|------|--------|
| `customer` | Browse workers, create/cancel bookings, chat, review |
| `worker` | View bookings, accept/reject, chat, update status |
| `admin` | Full platform management |
