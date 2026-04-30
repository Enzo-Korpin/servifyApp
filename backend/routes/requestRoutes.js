import express from "express";

import {
  createServiceRequest,
  getServiceRequestsForCustomer,
  getServiceRequestsForWorker,
  cancelServiceRequest,
  acceptServiceRequest,
  rejectServiceRequest,
} from "../service/requestService.js";

import { protectRoute } from "../middleware/protecteRoute.js";
import { createServiceRequestValidation } from "../middleware/createServiceRequestValidation.js";
import { requireCompletedOnboarding } from "../middleware/requireCompletedOnboarding.js";

const router = express.Router();

router.post(
  "/request",
  protectRoute,
  createServiceRequestValidation,
  createServiceRequest,
);

router.get("/customer", protectRoute, getServiceRequestsForCustomer);

router.get("/worker", protectRoute, requireCompletedOnboarding, getServiceRequestsForWorker);
router.put("/:id/cancel", protectRoute, cancelServiceRequest);
router.put("/:id/accept", protectRoute, requireCompletedOnboarding, acceptServiceRequest);
router.put("/:id/reject", protectRoute, requireCompletedOnboarding, rejectServiceRequest);
export default router;
