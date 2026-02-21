import express from "express";

import { protectRoute } from "../middleware/protecteRoute.js";

import { getWorkerStatus, switchRole } from "../service/workerService.js";

const router = express.Router();

router.get("/service-requests/worker-status", protectRoute, getWorkerStatus);
router.post("/switch-role", protectRoute, switchRole);

export default router;
