import express from "express";

import {
  createServiceRequest,
  getServiceRequestsForCustomer,
  getServiceRequestsForWorker,
  cancelServiceRequest,
  acceptServiceRequest,
  rejectServiceRequest,
  completeServiceRequest,
} from "../controller/requestController.js";

import { protectRoute } from "../middleware/protecteRoute.js";
import { submitFeedback } from "../controller/feedbackController.js";
import { getWorkerStatus } from "../controller/workerController.js";
import { submitFeedbackValidation } from "../middleware/feedbackValidation.js";

const router = express.Router();

router.post("/serviceRequests", protectRoute, createServiceRequest);
router.get("/serviceRequests/customer", protectRoute, getServiceRequestsForCustomer);
router.patch("/serviceRequests/:id/cancel", protectRoute, cancelServiceRequest);

router.get("/serviceRequests/worker", protectRoute, getServiceRequestsForWorker);
router.patch("/serviceRequests/:id/accept", protectRoute, acceptServiceRequest);
router.patch("/serviceRequests/:id/reject", protectRoute, rejectServiceRequest);
router.patch("/serviceRequests/:id/complete", protectRoute, completeServiceRequest);
router.get("/serviceRequests/worker-status", protectRoute, getWorkerStatus);

router.post("/serviceRequests/:requestId/feedback", protectRoute, submitFeedbackValidation, submitFeedback);
export default router;