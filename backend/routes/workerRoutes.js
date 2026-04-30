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
router.post("/switch-role", protectRoute, requireCompletedOnboarding, switchRole);
router.get("/allWorkers", getAllWorker);
router.get(
  "/profile",
  protectRoute,
  getWorkerProfile,
);
router.put(
  "/profile",
  protectRoute,
  workerProfileValidation,
  updateWorkerProfile,
);
router.get("/:id", getWorkerById);

export default router;
