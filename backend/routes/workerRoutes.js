import express from "express";

import { protectRoute } from "../middleware/protecteRoute.js";

import {
  getWorkerStatus,
  switchRole,
  getWorkerProfile,
  updateWorkerProfile,
  getAllWorker,
  getWorkerById,
} from "../service/workerService.js";
import { workerProfileValidation } from "../middleware/WorkerProfileValidation.js";
import { requireCompletedOnboarding } from "../middleware/requireCompletedOnboarding.js";

const router = express.Router();

router.get(
  "/service-requests/worker-status",
  protectRoute,
  requireCompletedOnboarding,
  getWorkerStatus,
);
router.post("/switch-role", protectRoute, switchRole);
router.get("/allWorkers", getAllWorker);
router.get(
  "/profile",
  protectRoute,
  requireCompletedOnboarding,
  getWorkerProfile,
);
router.put(
  "/profile",
  protectRoute,
  requireCompletedOnboarding,
  workerProfileValidation,
  updateWorkerProfile,
);
router.get("/:id", getWorkerById);

export default router;
