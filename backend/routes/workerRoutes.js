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

const router = express.Router();

router.get("/service-requests/worker-status", protectRoute, getWorkerStatus);
router.post("/switch-role", protectRoute, switchRole);
router.get("/allWorkers", getAllWorker);
router.get("/profile", protectRoute, getWorkerProfile);
router.put("/profile", protectRoute, workerProfileValidation, updateWorkerProfile);
router.get("/:id", getWorkerById);


export default router;
