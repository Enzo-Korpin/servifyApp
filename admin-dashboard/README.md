# Servify Admin Dashboard

A production-grade admin panel for the Servify service-marketplace, built with
React 18 + Vite, TanStack Query, React Router, Tailwind CSS and Recharts.

It talks to the existing Express/Mongoose backend over the same httpOnly-cookie
JWT used by the Flutter app, but only allows users whose role is `admin`.

---

## 1. Install

```bash
# from the repo root
cd admin-dashboard
npm install
cp .env.example .env
npm run dev
```

The dev server starts on `http://localhost:5174`. Vite proxies `/api/*` to
`http://localhost:5000` (your backend) so cookies just work.

For production:

```bash
npm run build       # outputs to dist/
npm run preview     # local sanity-check of the built bundle
```

---

## 2. Create the first admin

The User model now accepts a third role: `admin`. A seeder script is provided:

```bash
# from the repo root
ADMIN_EMAIL=admin@servify.local \
ADMIN_PASSWORD='Str0ng!Pass' \
ADMIN_FULL_NAME='Servify Admin' \
npm run seed:admin
```

The seeder is **idempotent**:

- if no user with that email exists → creates one (role `admin`, `isVerified: true`)
- if a user exists but isn't admin → promotes them
- if already admin → no-op

After it runs, log into the dashboard at `http://localhost:5174/login`.

---

## 3. File structure

```
servifyApp/
├── backend/
│   ├── admin/                          ← NEW (admin-only module)
│   │   ├── adminRoutes.js              router mounted at /api/admin
│   │   ├── controllers/
│   │   │   ├── authController.js       /auth/me
│   │   │   ├── statsController.js      /stats/*
│   │   │   ├── usersController.js      users CRUD
│   │   │   ├── workersController.js
│   │   │   ├── requestsController.js
│   │   │   ├── feedbackController.js
│   │   │   └── notificationsController.js
│   │   ├── middleware/
│   │   │   └── requireAdmin.js         enforces role === "admin"
│   │   ├── validators/
│   │   │   ├── validateQuery.js        Joi → req.query
│   │   │   └── schemas.js              per-endpoint Joi schemas
│   │   ├── utils/
│   │   │   └── paginate.js             { success, data, pagination, error } envelope
│   │   └── scripts/
│   │       └── seedAdmin.js            create/promote first admin
│   ├── models/user.js                  ← extended: "admin" role, isBlocked
│   ├── middleware/protecteRoute.js     ← also rejects blocked accounts
│   ├── service/authService.js          ← rejects blocked accounts on login
│   └── server.js                       ← mounts /api/admin
│
└── admin-dashboard/                    ← NEW (this app)
    ├── index.html
    ├── package.json
    ├── vite.config.js                  /api/* proxy in dev
    ├── tailwind.config.js
    ├── postcss.config.js
    ├── .env.example
    └── src/
        ├── main.jsx                    QueryClient + Router + AuthProvider
        ├── App.jsx                     lazy-loaded routes
        ├── index.css
        ├── api/
        │   ├── client.js               axios instance + error interceptor
        │   └── endpoints.js            typed endpoint module (only place URLs live)
        ├── context/
        │   └── AuthContext.jsx         /auth/me bootstrap, login, logout
        ├── routes/
        │   └── ProtectedRoute.jsx      gate for /admin/*
        ├── hooks/
        │   ├── useDebouncedValue.js    debounced search input
        │   └── useQueryParams.js       URL-driven filters
        ├── lib/
        │   ├── cn.js                   clsx re-export
        │   └── format.js               numbers, dates, relative time
        ├── components/
        │   ├── layout/
        │   │   ├── AdminLayout.jsx     sidebar + topbar shell
        │   │   ├── Sidebar.jsx
        │   │   └── Topbar.jsx
        │   └── ui/
        │       ├── Avatar.jsx
        │       ├── Badge.jsx           (+ StatusBadge)
        │       ├── Button.jsx
        │       ├── ConfirmDialog.jsx
        │       ├── DataTable.jsx
        │       ├── EmptyState.jsx
        │       ├── ErrorState.jsx
        │       ├── FilterSelect.jsx
        │       ├── FullPageSpinner.jsx
        │       ├── PageHeader.jsx
        │       ├── Pagination.jsx
        │       ├── SearchInput.jsx
        │       ├── Skeleton.jsx
        │       └── StatCard.jsx
        └── pages/
            ├── LoginPage.jsx
            ├── DashboardPage.jsx
            ├── UsersPage.jsx           /admin/users
            ├── UserDetailPage.jsx      /admin/users/:id
            ├── WorkersPage.jsx
            ├── WorkerDetailPage.jsx
            ├── RequestsPage.jsx
            ├── RequestDetailPage.jsx
            ├── FeedbackPage.jsx
            ├── NotificationsPage.jsx   (+ KPI cards)
            ├── SettingsPage.jsx
            └── NotFoundPage.jsx
```

---

## 4. Environment variables

### Admin dashboard (`admin-dashboard/.env`)

| Var                 | Used by                | Notes                                                                   |
| ------------------- | ---------------------- | ----------------------------------------------------------------------- |
| `VITE_API_BASE_URL` | Production build       | Absolute base URL of the deployed backend. Leave empty in dev.          |
| `VITE_API_PROXY`    | Vite dev server        | URL the Vite proxy forwards `/api/*` to. Default `http://localhost:5000`. |
| `VITE_DEV_PORT`     | Vite dev server        | Default `5174`.                                                          |

### Backend (existing `.env`, add if missing)

| Var               | Purpose                                                                            |
| ----------------- | ---------------------------------------------------------------------------------- |
| `NODE_ENV`        | `production` enables `secure: true`, `sameSite: "none"` for cross-site cookies.    |
| `JWT_SECRET`      | Already used.                                                                       |
| `CLIENT_ORIGINS`  | Comma-separated allowed origins for CORS, **must include the admin URL** in prod.   |
| `ADMIN_EMAIL`     | Used by the seeder.                                                                 |
| `ADMIN_PASSWORD`  | Used by the seeder.                                                                 |
| `ADMIN_FULL_NAME` | Used by the seeder (optional).                                                      |

Example for local development:

```env
NODE_ENV=development
CLIENT_ORIGINS=http://localhost:5174,http://localhost:3000
JWT_SECRET=replace-me
```

---

## 5. How it connects to the existing Servify backend

1. **Same auth cookie.** The dashboard logs in via the existing
   `POST /api/auth/login` endpoint — no special admin login flow. After login it
   calls `GET /api/admin/auth/me`; the server's `protectRoute + requireAdmin`
   chain returns 200 only if `req.user.role === "admin"`. A non-admin who
   somehow logs in gets a 403 immediately and the dashboard auto-logs them out.

2. **Same error envelope.** All admin endpoints return the existing
   `{ success, data, error: { code, message, details } }` shape. The dashboard's
   axios interceptor unwraps it into rejected promises that carry `.code`,
   `.status`, and `.message`.

3. **Same cookies in prod.** `secure: true, sameSite: "none"` is already set
   when `NODE_ENV=production` — make sure both the backend and the dashboard
   are served over HTTPS and that `CLIENT_ORIGINS` includes the dashboard origin.

4. **No frontend role trust.** `requireAdmin` runs server-side on **every**
   admin route. The frontend's `ProtectedRoute` is purely UX — it can be
   bypassed and the API will still 403 the request.

---

## 6. Database indexes

The following indexes were added to `User`:

```js
userSchema.index({ createdAt: -1 });
userSchema.index({ role: 1, createdAt: -1 });
userSchema.index({ isVerified: 1, createdAt: -1 });
userSchema.index({ isBlocked: 1 });
userSchema.index({ fullName: "text", email: "text" });
```

Other collections already had production indexes — they're listed here for
completeness. **No new indexes are required on these**, but verify they exist:

```js
// ServiceRequest (already present)
{ customerId: 1, createdAt: -1, _id: -1 }
{ workerId:   1, createdAt: -1, _id: -1 }
{ workerId:   1, status: 1 }

// Feedback (already present, plus we use workerId for joins)
{ requestId: 1 }   // unique

// Notification (already present)
{ userId: 1, createdAt: -1 }
```

If you have a large feedback collection, add these two for the admin filters:

```js
db.feedbacks.createIndex({ workerId: 1, createdAt: -1 });
db.feedbacks.createIndex({ rate: 1, createdAt: -1 });
```

Mongoose creates the new User indexes automatically on first connect in
development. In production, run `User.syncIndexes()` once after deploy or
create them manually.

---

## 7. API surface (admin only — all under `/api/admin`)

| Method | Path                                  | Notes                                       |
| ------ | ------------------------------------- | ------------------------------------------- |
| GET    | `/auth/me`                            | Returns the signed-in admin                 |
| GET    | `/stats`                              | All dashboard summary cards                 |
| GET    | `/stats/users-growth?days=30`         | Daily new-user series                       |
| GET    | `/stats/requests-by-status`           | Pie-chart fuel                              |
| GET    | `/stats/top-workers?limit=5`          | Top-rated workers                           |
| GET    | `/stats/most-active-customers?limit=5`| Most requesting customers                   |
| GET    | `/reports/overview`                   | Acceptance rate + KPI rollup                |
| GET    | `/users`                              | Paginated, server-side search/filter/sort   |
| GET    | `/users/:id`                          | User + worker profile if applicable         |
| PATCH  | `/users/:id/block`                    | `{ isBlocked, reason? }`                    |
| DELETE | `/users/:id`                          | Cascading delete (txn)                      |
| GET    | `/workers`                            | Joined User + WorkerProfile, paginated       |
| GET    | `/workers/:id`                        | + recent requests + feedback + rollups      |
| GET    | `/service-requests`                   | Paginated, filter status/customer/worker    |
| GET    | `/service-requests/:id`               | Populated request                           |
| DELETE | `/service-requests/:id`               | Hard delete                                 |
| GET    | `/feedback`                           | Paginated, filter rating range + search     |
| GET    | `/feedback/:id`                       | Single feedback                             |
| DELETE | `/feedback/:id`                       | Deletes + re-computes worker rating (txn)   |
| GET    | `/notifications`                      | All-user notification log                   |

Every list endpoint accepts:

```
?page=1&limit=20&search=...&sortBy=...&sortOrder=desc
```

`limit` is capped at **50** by Joi.

---

## 8. Assumptions

The implementation makes the following assumptions — they're listed here so
they're easy to revisit:

1. **The original Flutter app already uses `secure + sameSite=none` cookies in
   prod.** That's what the codebase did before this PR; the admin dashboard
   relies on it for cross-origin auth.
2. **The single shared `/api/auth/login` endpoint accepts admins.** It
   previously returned all users; we added an `isBlocked` rejection in
   `loginUser` but didn't restrict by role. Admins go through the same flow.
3. **Admins don't need a geo location.** The `location` field on `User` was
   marked required for `customer`/`worker`. The schema now makes it optional
   for `admin`, and the seeder still writes a dummy `[0, 0]` Point.
4. **Cascading delete is acceptable.** When an admin deletes a user we also
   wipe the worker profile, their service requests and their feedback. If you
   need soft-delete or audit trails, swap the `deleteUser` controller for a
   tombstone update.
5. **Notifications use the existing enum** (`request_accepted`,
   `request_rejected`). Extend `models/notification.js`'s enum if you add
   admin-authored broadcasts later.
6. **Admin-to-admin actions are blocked.** Admins cannot block, delete, or
   demote each other via the dashboard. Manual DB ops are required for that
   (intentional defense-in-depth).
7. **Image uploads are out of scope for V1.** Editing the admin's own avatar
   would re-use the Cloudinary helpers in the backend, but the route isn't
   exposed here.
8. **The dashboard runs on a different origin** (port 5174) than the API
   (port 5000). For production this means CORS allow-listing and HTTPS.
9. **No server-side activity log table exists yet.** The Notifications page
   doubles as the audit/log surface for now. Adding a dedicated `AuditLog`
   collection is the natural next step.

---

## 9. Local checklist

```bash
# Backend
cd /path/to/servifyApp
npm install                        # already done
npm run seed:admin                 # create the admin user
npm run dev                        # http://localhost:5000

# Dashboard
cd admin-dashboard
npm install
npm run dev                        # http://localhost:5174
# → log in with the credentials from `npm run seed:admin`
```

That's it. Every list page is fully server-paginated, every filter persists in
the URL, every destructive action is gated by a `ConfirmDialog`, and every
admin route is gated by `protectRoute + requireAdmin` on the server.
