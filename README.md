# Servify

Servify is a full-stack mobile application that connects customers with nearby maintenance workers such as plumbers, electricians, painters, cleaners, and other service providers. Customers can discover workers by location, skills, distance, and rating, send service requests, follow workers, chat, and receive request-status notifications.

The project is built with a Flutter mobile frontend and a Node.js/Express backend powered by MongoDB, Redis, BullMQ, JWT cookie authentication, Cloudinary image uploads, email verification, Google Sign-In, and map-based worker discovery.

---

## Table of Contents

- [Overview](#overview)
- [Main Features](#main-features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [Running with Docker](#running-with-docker)
- [Running Manually](#running-manually)
- [API Overview](#api-overview)
- [Database Models](#database-models)
- [Frontend Notes](#frontend-notes)
- [Security Notes](#security-notes)
- [Roadmap](#roadmap)
- [License](#license)

---

## Overview

Servify solves a simple problem: when a customer needs home maintenance help, they should be able to quickly find trusted nearby workers and request help from inside one app.

The system supports two main user roles:

- **Customer**: searches for nearby workers, follows workers, sends service requests, manages profile, views notifications, and communicates with workers.
- **Worker**: manages worker profile, skills, experience, service requests, and request status actions such as accepting or rejecting requests.

---

## Main Features

### Authentication & Account Management

- Customer and worker signup.
- Email verification using a verification code.
- Resend verification code with cooldown/rate-limit behavior.
- Login and logout.
- JWT authentication stored in an HTTP-only cookie.
- Protected routes using authentication middleware.
- Forgot password, reset-code verification, and password reset flow.
- Google Sign-In support.
- Worker onboarding flow for Google-authenticated workers.

### Customer Features

- View and update customer profile.
- Discover nearby workers using geolocation.
- Filter workers by skill, radius, distance, rating, or rating count.
- Search workers by name.
- Follow and unfollow workers.
- View followed workers.
- Create service requests.
- Cancel service requests.
- Submit feedback/rating after service.
- Receive notifications when a worker accepts or rejects a request.

### Worker Features

- View and update worker profile.
- Add skills, bio, and years of experience.
- View worker service-request status summary.
- View incoming customer requests.
- Accept or reject service requests.
- Receive request-related data from customers.

### Chat & Messaging

- Chat model for customer-worker conversations.
- Message model for storing messages.
- Message routes and service layer included.

### Notifications

- Notification model for request updates.
- Fetch user notifications.
- Mark one notification as read.
- Mark all notifications as read.

### Maps & Location

- Location stored using GeoJSON coordinates.
- Nearby worker discovery using geospatial querying.
- Flutter map integration.
- Tile caching support for better map performance.
- Dijkstra algorithm prototype folder included for path/routing experiments.

### AI Assistant

- AI backend module included.
- OpenRouter integration for AI model calls.
- AI conversation, message, and proposal models included.

---

## Tech Stack

### Backend

| Layer | Technology |
|---|---|
| Runtime | Node.js |
| Framework | Express.js |
| Database | MongoDB + Mongoose |
| Authentication | JWT + HTTP-only cookies |
| Password Hashing | bcrypt |
| Validation | Joi + custom middleware |
| File/Image Uploads | Cloudinary |
| Email | Nodemailer / SMTP |
| Queue | BullMQ |
| Cache/Queue Backend | Redis |
| Security / Protection | Arcjet |
| AI Integration | OpenRouter API |
| Containerization | Docker + Docker Compose |

### Frontend

| Layer | Technology |
|---|---|
| Framework | Flutter |
| Language | Dart |
| HTTP Client | Dio |
| Cookie Persistence | dio_cookie_manager + cookie_jar |
| Maps | flutter_map |
| Location | geolocator + geocoding |
| Tile Caching | flutter_map_tile_caching |
| Environment Variables | flutter_dotenv |
| Google Login | google_sign_in |

---

## Project Structure

```bash
servifyApp/
├── backend/
│   ├── ai/                 # AI routes, services, models, OpenRouter integration
│   ├── db/                 # MongoDB connection
│   ├── errors/             # Custom HTTP error classes
│   ├── lib/                # External service configs: Cloudinary, Arcjet
│   ├── mailtrap/           # Email templates, email sender, limiter
│   ├── middleware/         # Auth, validation, onboarding, error handling
│   ├── models/             # Mongoose models
│   ├── queues/             # BullMQ / Redis queues
│   ├── routes/             # Express routes
│   ├── service/            # Business logic layer
│   ├── utils/              # Token, verification code, Google auth utilities
│   ├── validators/         # Validation helpers/schemas
│   ├── workers/            # Background workers
│   └── server.js           # Express app entry point
│
├── frontend/
│   ├── android/            # Android Flutter project
│   ├── assets/             # App images and icons
│   ├── ios/                # iOS Flutter project
│   ├── lib/
│   │   ├── Access/         # Login, signup, verification screens
│   │   ├── Follow/         # Follow-related UI
│   │   ├── Home_pages/     # Customer/worker home screens
│   │   ├── ai/             # AI frontend screens/services
│   │   ├── core/           # Network/client configuration
│   │   ├── models/         # Dart models
│   │   ├── notifications/  # Notification screens
│   │   ├── profiles/       # Customer/worker profiles
│   │   ├── requests/       # Request screens
│   │   ├── services/       # API service classes
│   │   ├── worker/         # Worker-specific UI
│   │   ├── Switcher.dart
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── README.md
│
├── dijkistra/
│   └── algo.js             # Dijkstra algorithm prototype
│
├── Dockerfile
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── package.json
└── README.md
```

---

## Architecture

The project follows a clean separation between frontend, backend routes, business logic, database models, middleware, and external services.

```text
Flutter App
   |
   | HTTP requests with Dio + persisted cookies
   v
Express API
   |
   | Middleware: auth, validation, onboarding, error handling
   v
Service Layer
   |
   | Business logic: auth, requests, workers, notifications, feedback
   v
MongoDB / Redis / External Services
```

### Backend Flow Example

```text
Customer sends service request
   -> Express route receives request
   -> protectRoute validates JWT cookie
   -> validation middleware checks request body
   -> requestService creates/updates database records
   -> notification is created for the target user
   -> response is returned to Flutter app
```

---

## Getting Started

### Prerequisites

Make sure you have the following installed:

- Node.js 20+
- npm
- Flutter SDK
- Android Studio or a configured Android emulator
- MongoDB Atlas account or local MongoDB
- Docker Desktop, optional but recommended
- Redis, required if running queue/worker features manually without Docker

---

## Environment Variables

Create a `.env` file in the project root:

```env
# Server
NODE_ENV=development
PORT=5000

# Database
MONGO_URI=your_mongodb_connection_string

# Auth
JWT_SECRET=your_strong_jwt_secret

# SMTP / Email
SMTP_SERVICE=gmail
SMTP_USER=your_email@example.com
SMTP_PASS=your_email_app_password
EMAIL_FROM=Servify Team <your_email@example.com>

# Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# Google Sign-In
GOOGLE_CLIENT_IDS=your_android_or_web_google_client_id

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# Arcjet
ARCJET_KEY=your_arcjet_key
ARCJET_ENV=development

# AI / OpenRouter
OPENROUTER_API_KEY=your_openrouter_api_key
OPENROUTER_MODELS=model_one,model_two
```

For Flutter, create `frontend/.env` if your app reads frontend-specific keys such as map API keys or runtime configuration.

Example:

```env
MAPTILER_API_KEY=your_maptiler_key
```

Never commit real `.env` files to GitHub.

---

## Running with Docker

The recommended backend development setup is Docker Compose because it starts the API, Redis, and worker together.

### Development

```bash
docker compose -f docker-compose.dev.yml up --build
```

This starts:

- `servify-api` on port `5000`
- `servify-worker`
- `redis` on port `6379`

### Production

```bash
docker compose -f docker-compose.prod.yml up --build -d
```

---

## Running Manually

### 1. Install backend dependencies

From the project root:

```bash
npm install
```

### 2. Start the backend API

```bash
npm run dev
```

The backend should run on:

```text
http://localhost:5000
```

### 3. Start the worker

In a second terminal:

```bash
npm run worker
```

If you are not using Docker, make sure Redis is running locally and update your `.env`:

```env
REDIS_HOST=localhost
REDIS_PORT=6379
```

### 4. Run the Flutter app

```bash
cd frontend
flutter pub get
flutter run
```

For Android emulator development, the backend base URL should usually be:

```text
http://10.0.2.2:5000
```

For a real physical device, use your computer's local network IP instead, for example:

```text
http://192.168.x.x:5000
```

---

## API Overview

Base URL:

```text
http://localhost:5000
```

### Auth Routes

Prefix: `/api/auth`

| Method | Endpoint | Description | Protected |
|---|---|---|---|
| POST | `/signup` | Register customer or worker | No |
| POST | `/login` | Login and set JWT cookie | No |
| POST | `/logout` | Logout and clear token cookie | No |
| POST | `/verify-email` | Verify account email | No |
| POST | `/resend-verification` | Resend verification code | No |
| POST | `/forgot-password` | Send reset password code | No |
| POST | `/verify-reset-code` | Verify password reset code | No |
| POST | `/reset-password` | Reset password | No |
| GET | `/check-auth` | Return authenticated user | Yes |
| POST | `/google` | Google Sign-In | No |
| POST | `/google/worker-profile` | Complete Google worker onboarding | Yes |

### Customer Routes

Prefix: `/api/customer`

| Method | Endpoint | Description | Protected |
|---|---|---|---|
| GET | `/profile` | Get customer profile | Yes |
| PUT | `/profile` | Update customer profile | Yes |
| GET | `/filtered-workers` | Get nearby/filterable workers | Yes |
| GET | `/search-workers` | Search workers by name | Yes |
| GET | `/search-filtered-workers` | Search + filter nearby workers | Yes |
| GET | `/get-location` | Get customer saved location | Yes |

### Worker Routes

Prefix: `/api/worker`

| Method | Endpoint | Description | Protected |
|---|---|---|---|
| GET | `/service-requests/worker-status` | Worker request status summary | Yes |
| POST | `/switch-role` | Switch active role | Yes |
| GET | `/allWorkers` | Get workers | No |
| GET | `/profile` | Get worker profile | Yes |
| PUT | `/profile` | Update worker profile | Yes |
| GET | `/:id` | Get worker by ID | No |

### Service Request Routes

Prefix: `/api/service-requests`

| Method | Endpoint | Description | Protected |
|---|---|---|---|
| POST | `/request` | Create service request | Yes |
| GET | `/customer` | Get customer's service requests | Yes |
| GET | `/worker` | Get worker's service requests | Yes |
| PUT | `/:id/cancel` | Cancel request | Yes |
| PUT | `/:id/accept` | Accept request | Yes |
| PUT | `/:id/reject` | Reject request | Yes |

### Follow Routes

Prefix: `/api`

| Method | Endpoint | Description | Protected |
|---|---|---|---|
| POST | `/follow/:workerId` | Follow worker | Yes |
| DELETE | `/unfollow/:workerId` | Unfollow worker | Yes |
| GET | `/following` | Get all followed workers | Yes |
| GET | `/following/:workerId` | Check/get specific followed worker | Yes |

### Feedback Routes

Prefix: `/api/feedback`

| Method | Endpoint | Description | Protected |
|---|---|---|---|
| POST | `/:requestId` | Submit feedback for a request | Yes |

### Notification Routes

Prefix: `/api/notifications`

| Method | Endpoint | Description | Protected |
|---|---|---|---|
| GET | `/` | Get current user's notifications | Yes |
| PATCH | `/read-all` | Mark all notifications as read | Yes |
| PATCH | `/:id/read` | Mark one notification as read | Yes |

### Message Routes

Prefix: `/api/message`

Message APIs are included in the backend route structure for customer-worker communication.

### AI Routes

Prefix: `/api/ai`

AI APIs are included for AI-powered assistant/proposal functionality.

---

## Database Models

The backend uses Mongoose models including:

- `User`
- `PendingUser`
- `WorkerProfile`
- `ServiceRequest`
- `Feedback`
- `Follow`
- `Notification`
- `Chat`
- `Message`
- `AIConversation`
- `AIMessage`
- `AIProposal`

### Important Data Design Notes

- User location is stored as GeoJSON `Point` using `[lng, lat]` order.
- Worker profile is separated from the main user account.
- Pending users are stored before email verification.
- Notifications are stored in MongoDB and exposed through API endpoints.
- Feedback is linked to service requests and workers.

---

## Frontend Notes

The Flutter app uses Dio with cookie persistence. This is important because the backend stores JWT authentication in an HTTP-only cookie named `token`.

For Android emulator development:

```dart
baseUrl: 'http://10.0.2.2:5000'
```

For a physical device, replace it with your computer's LAN IP.

Example:

```dart
baseUrl: 'http://192.168.1.10:5000'
```

---

## Security Notes

- Passwords are hashed using bcrypt.
- JWT is stored in an HTTP-only cookie.
- Cookie settings change based on `NODE_ENV`.
- Cloudinary credentials must stay private.
- SMTP credentials must stay private.
- Google client IDs must be configured correctly.
- Never commit `.env`, API keys, database credentials, or private tokens.

Recommended production improvements:

- Restrict CORS to the real frontend/mobile client origin.
- Remove debugging logs that print tokens or sensitive data.
- Add request logging with safe redaction.
- Add automated tests for auth, requests, feedback, and notifications.
- Add a `/health` endpoint for deployment monitoring.
- Add centralized API documentation using Swagger/OpenAPI.

---

## Roadmap

Planned or recommended improvements:

- Complete real-time chat using WebSocket or Socket.IO.
- Add push notifications using Firebase Cloud Messaging.
- Add payment flow for paid services.
- Add admin dashboard.
- Add worker verification/moderation.
- Improve AI assistant proposal workflow.
- Improve map routing beyond the Dijkstra prototype.
- Add unit and integration tests.
- Add CI/CD pipeline.
- Add screenshots and demo video to this README.

---


## License

This project is currently licensed under the ISC License.

---

## Author

Built by the Servify team as a full-stack mobile application project.