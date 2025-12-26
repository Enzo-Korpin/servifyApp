# servifyApp

Servify is a mobile application that connects homeowners with nearby maintenance professionals such as plumbers, painters, and electricians. It provides users with easy access to trusted workers’ names, skills, and locations, allowing them to request help instantly.

# Servify Backend (Node.js + Express + MongoDB)

Backend API for **Servify** — a services marketplace where users can register, verify email, authenticate via JWT (stored in an HTTP-only cookie), and switch roles (**customer** ↔ **worker**).

> Repo focus: backend only (Express + MongoDB). Frontend/mobile clients integrate via REST endpoints.

---

## Tech Stack

- **Runtime:** Node.js
- **Framework:** Express
- **Database:** MongoDB (Mongoose)
- **Auth:** JWT in **HTTP-only cookie** (`token`)
- **Email:** Mailtrap (verification + welcome emails)
- **Security basics:** bcrypt password hashing, cookie-parser, env via dotenv

---

## Key Features

- ✅ Register user (customer or worker)
- ✅ Email verification with **6-digit code** (15 minutes expiry)
- ✅ Login (sets JWT cookie)
- ✅ Auth check (`/check-auth`) using JWT cookie middleware
- ✅ Switch current role (`/switch-role`) for the same account
- ✅ Worker profile model (bio, skills, rate, experience) — created automatically for worker registrations

---

## Project Structure

```
backend/
  controller/
    userController.js
  mailtrap/
    emailTemplates.js
    emails.js
    mailtrap.js
  middleware/
    verifyToken.js
  models/
    user.js
    workerProfile.js
    serviceRequest.js
    Chat.js
    Message.js
    follow.js
  routes/
    authRoutes.js
  utils/
    generateTokenAndSetCookie.js
    generateVerficationCode.js
  server.js
```

---

## Getting Started

### 1) Install

```bash
npm install
```

### 2) Create `.env`

Create a `backend/.env` file based on `.env.example`.

### 3) Run

```bash
node backend/server.js
```

> Recommended: add a start script (see “Suggested Improvements”).

---

## Environment Variables

Create `backend/.env`:

- `PORT` — default is `5000`
- `MONGO_URI` — MongoDB connection string
- `JWT_SECRET` — secret used to sign JWTs
- `MAILTRAP_API_TOKEN` — Mailtrap API token
- `MAILTRAP_API_ENDPOINT` — Mailtrap API endpoint (depends on Mailtrap config)
- `NODE_ENV` — set to `production` to enable secure cookies

---

## Authentication Model (Important)

This backend uses:

- JWT stored in **cookie** named `token`
- Cookie flags:
  - `httpOnly: true`
  - `secure: true` only when `NODE_ENV=production`
  - `sameSite: "Strict"`
  - `maxAge: 7 days`

So your frontend must:

- send requests **with credentials/cookies enabled** (e.g., `fetch(..., { credentials: "include" })`)
- configure CORS accordingly (see “Known Issues & Gaps”)

---

## API Endpoints

Base URL: `http://localhost:5000`

### `POST /register`

Register a new user. If `role=worker`, a WorkerProfile is created in the same Mongo transaction.

**Body**

```json
{
  "fullName": "Karam Ahmad",
  "email": "karam@example.com",
  "password": "StrongPass123",
  "role": "customer",
  "lat": 31.95,
  "lng": 35.91,
  "image": "https://..."
}
```

**Responses**

- `201` Created — user created, verification email sent
- `409` Conflict — email already used
- `400` Bad Request — missing fields / invalid role

---

### `POST /verify-email`

Verify email with 6-digit code.

**Body**

```json
{
  "email": "karam@example.com",
  "code": "123456"
}
```

**Responses**

- `200` OK — verified + welcome email sent
- `400` Invalid / expired code

---

### `POST /login`

Logs in and sets `token` cookie.

**Body**

```json
{
  "email": "karam@example.com",
  "password": "StrongPass123"
}
```

**Responses**

- `200` OK — cookie set
- `401` Invalid credentials
- `403` Not verified (if enforced by controller)

---

### `GET /check-auth` (Protected)

Requires JWT cookie.

**Response**

- `200` OK — returns authenticated user info (depends on controller)
- `401` Unauthorized — missing/invalid token

---

### `POST /switch-role` (Protected)

Switches `currentRole` (customer/worker) for the logged-in user.

**Body**

```json
{ "role": "worker" }
```

**Responses**

- `200` OK
- `400` Invalid role
- `401` Unauthorized

---

## Data Models (MongoDB)

### `User`

- `fullName` (required)
- `email` (required, unique)
- `password` (required, bcrypt hash)
- `role` (enum: `customer|worker`) — “account type”
- `currentRole` (enum: `customer|worker`) — active mode
- `lat`, `lng` (optional)
- `image` (optional)
- `isVerified` (default false)
- `verificationCodeHash`, `verificationCodeExpiry`

### `WorkerProfile`

Stored with `_id` equal to the User’s `_id` (linked via `ref: "User"`):

- `bio`
- `yearsOfExperience`
- `rate` (required)
- `skills` (required array of strings)

### Other models included (not wired to routes yet)

- `ServiceRequest`
- `Chat`
- `Message`
- `Follow`

---

## Suggested Improvements (High impact)

If you want this repo to look professional to recruiters, do these:

1. **Remove `node_modules/` from the repo** and ensure it’s in `.gitignore`.
2. **Do not commit `backend/.env`** (commit an `.env.example` instead).
3. Add scripts to `package.json`:
   - `"start": "node backend/server.js"`
   - `"dev": "nodemon backend/server.js"`
4. Fix CORS for cookie auth:
   - must set `cors({ origin: CLIENT_URL, credentials: true })`
   - and your client must send `credentials: "include"`.
5. Remove secrets logging:
   - `console.log("MONGO_URI =", process.env.MONGO_URI);` should not exist.
6. Add validation layer (Joi/Zod) + consistent error format.
7. Add a `/health` endpoint.
8. Add basic tests (Jest + Supertest) for auth endpoints.

---

## Known Issues & Gaps (Be honest on GitHub)

- CORS is currently `app.use(cors())` (no credentials config). Cookie auth will fail in browsers if frontend is on another origin.
- `Message` model doesn’t include a `text` field (so text messages cannot be stored properly).
- `follow.js` uses `WorkerId` with different casing than other IDs (inconsistent naming).
- No centralized error handler middleware yet.

---

## Roadmap (next features)

- Service request lifecycle (create/accept/complete/cancel)
- Chat + message sending APIs
- Worker discovery by location/skills
- Ratings & reviews
- Admin moderation

---

## License

ISC (current). You can change to MIT for portfolio usage.
