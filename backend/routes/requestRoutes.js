import express from "express";

import {
  createServiceRequest,
  getServiceRequestsForCustomer,
  getServiceRequestsForWorker,
  cancelServiceRequest,
  acceptServiceRequest,
  rejectServiceRequest,} from "../controller/requestController.js";

import { protectRoute } from "../middleware/protecteRoute.js";
const router = express.Router();

router.post("/service-requests", protectRoute, createServiceRequest);
router.get("/service-requests/customer", protectRoute, getServiceRequestsForCustomer);
router.patch("/service-requests/:id/cancel", protectRoute, cancelServiceRequest);

router.get("/service-requests/worker", protectRoute, getServiceRequestsForWorker);
router.patch("/service-requests/:id/accept", protectRoute, acceptServiceRequest);
router.patch("/service-requests/:id/reject", protectRoute, rejectServiceRequest);
export default router;