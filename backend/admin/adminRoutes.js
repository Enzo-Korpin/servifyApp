import express from "express";

import { protectRoute } from "../middleware/protecteRoute.js";
import { requireAdmin } from "./middleware/requireAdmin.js";
import { adminSensitiveLimiter } from "../lib/rateLimit.js";

import { validateQuery } from "./validators/validateQuery.js";
import {
  validateParams,
  validateBody,
  listUsersSchema,
  listWorkersSchema,
  listRequestsSchema,
  listFeedbackSchema,
  listNotificationsSchema,
  blockUserSchema,
  idParamSchema,
} from "./validators/schemas.js";

import { getCurrentAdmin } from "./controllers/authController.js";
import {
  getStats,
  getUsersGrowth,
  getRequestsByStatus,
  getTopWorkers,
  getMostActiveCustomers,
} from "./controllers/statsController.js";
import {
  listUsers,
  getUser,
  blockUser,
  deleteUser,
} from "./controllers/usersController.js";
import { listWorkers, getWorker } from "./controllers/workersController.js";
import {
  listRequests,
  getRequest,
  deleteRequest,
} from "./controllers/requestsController.js";
import {
  listFeedback,
  getFeedback,
  deleteFeedback,
} from "./controllers/feedbackController.js";
import {
  listNotifications,
  getReportsOverview,
} from "./controllers/notificationsController.js";

const router = express.Router();

// Every admin route requires: valid JWT cookie + role === "admin"
router.use(protectRoute, requireAdmin);

// ── Auth ────────────────────────────────────────────────────────────────────
router.get("/auth/me", getCurrentAdmin);

// ── Stats / Reports ─────────────────────────────────────────────────────────
router.get("/stats", getStats);
router.get("/stats/users-growth", getUsersGrowth);
router.get("/stats/requests-by-status", getRequestsByStatus);
router.get("/stats/top-workers", getTopWorkers);
router.get("/stats/most-active-customers", getMostActiveCustomers);
router.get("/reports/overview", getReportsOverview);

// ── Users ───────────────────────────────────────────────────────────────────
router.get("/users", validateQuery(listUsersSchema), listUsers);
router.get("/users/:id", validateParams(idParamSchema), getUser);
router.patch(
  "/users/:id/block",
  adminSensitiveLimiter,
  validateParams(idParamSchema),
  validateBody(blockUserSchema),
  blockUser
);
router.delete(
  "/users/:id",
  adminSensitiveLimiter,
  validateParams(idParamSchema),
  deleteUser
);

// ── Workers ─────────────────────────────────────────────────────────────────
router.get("/workers", validateQuery(listWorkersSchema), listWorkers);
router.get("/workers/:id", validateParams(idParamSchema), getWorker);

// ── Service Requests ────────────────────────────────────────────────────────
router.get("/service-requests", validateQuery(listRequestsSchema), listRequests);
router.get("/service-requests/:id", validateParams(idParamSchema), getRequest);
router.delete(
  "/service-requests/:id",
  adminSensitiveLimiter,
  validateParams(idParamSchema),
  deleteRequest
);

// ── Feedback ────────────────────────────────────────────────────────────────
router.get("/feedback", validateQuery(listFeedbackSchema), listFeedback);
router.get("/feedback/:id", validateParams(idParamSchema), getFeedback);
router.delete(
  "/feedback/:id",
  adminSensitiveLimiter,
  validateParams(idParamSchema),
  deleteFeedback
);

// ── Notifications ───────────────────────────────────────────────────────────
router.get(
  "/notifications",
  validateQuery(listNotificationsSchema),
  listNotifications
);

export default router;
