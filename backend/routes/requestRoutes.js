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
import { createServiceRequestValidator } from "../validators/createServiceRequestValidator.js";
const router = express.Router();

router.post(
  "/service-requests",
  protectRoute,
  createServiceRequestValidator,
  createServiceRequest,
);

router.put("/service-requests/:id/cancel", protectRoute, cancelServiceRequest);

router.get(
  "/service-requests/customer",
  protectRoute,
  getServiceRequestsForCustomer,
);

router.get(
  "/service-requests/worker",
  protectRoute,
  getServiceRequestsForWorker,
);
router.put("/service-requests/:id/accept", protectRoute, acceptServiceRequest);
router.put("/service-requests/:id/reject", protectRoute, rejectServiceRequest);
export default router;
