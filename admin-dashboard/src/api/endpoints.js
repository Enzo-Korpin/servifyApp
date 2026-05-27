import { api } from "./client.js";

// Centralized endpoint module. Pages call these — never axios directly.
// Keeps URL strings and response unwrapping in one place.

const unwrap = (r) => r.data;

// ── Auth ───────────────────────────────────────────────────────────────────
export const authApi = {
  login: (email, password) =>
    api.post("/api/auth/login", { email, password }).then(unwrap),
  logout: () => api.post("/api/auth/logout").then(unwrap),
  me: () => api.get("/api/admin/auth/me").then(unwrap),
};

// ── Stats ──────────────────────────────────────────────────────────────────
export const statsApi = {
  overview: () => api.get("/api/admin/stats").then(unwrap),
  usersGrowth: (days = 30) =>
    api.get("/api/admin/stats/users-growth", { params: { days } }).then(unwrap),
  requestsByStatus: () =>
    api.get("/api/admin/stats/requests-by-status").then(unwrap),
  topWorkers: (limit = 5) =>
    api.get("/api/admin/stats/top-workers", { params: { limit } }).then(unwrap),
  mostActiveCustomers: (limit = 5) =>
    api
      .get("/api/admin/stats/most-active-customers", { params: { limit } })
      .then(unwrap),
  reportsOverview: () => api.get("/api/admin/reports/overview").then(unwrap),
};

// ── Users ──────────────────────────────────────────────────────────────────
export const usersApi = {
  list: (params) => api.get("/api/admin/users", { params }).then(unwrap),
  get: (id) => api.get(`/api/admin/users/${id}`).then(unwrap),
  block: (id, body) =>
    api.patch(`/api/admin/users/${id}/block`, body).then(unwrap),
  remove: (id) => api.delete(`/api/admin/users/${id}`).then(unwrap),
};

// ── Workers ────────────────────────────────────────────────────────────────
export const workersApi = {
  list: (params) => api.get("/api/admin/workers", { params }).then(unwrap),
  get: (id) => api.get(`/api/admin/workers/${id}`).then(unwrap),
};

// ── Service Requests ───────────────────────────────────────────────────────
export const requestsApi = {
  list: (params) => api.get("/api/admin/service-requests", { params }).then(unwrap),
  get: (id) => api.get(`/api/admin/service-requests/${id}`).then(unwrap),
  remove: (id) => api.delete(`/api/admin/service-requests/${id}`).then(unwrap),
};

// ── Feedback ───────────────────────────────────────────────────────────────
export const feedbackApi = {
  list: (params) => api.get("/api/admin/feedback", { params }).then(unwrap),
  get: (id) => api.get(`/api/admin/feedback/${id}`).then(unwrap),
  remove: (id) => api.delete(`/api/admin/feedback/${id}`).then(unwrap),
};

// ── Notifications ──────────────────────────────────────────────────────────
export const notificationsApi = {
  list: (params) =>
    api.get("/api/admin/notifications", { params }).then(unwrap),
};
