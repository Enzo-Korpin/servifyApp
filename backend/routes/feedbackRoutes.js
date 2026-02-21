import express from "express";

import { protectRoute } from "../middleware/protecteRoute.js";
import { submitFeedback } from "../service/feedbackService.js";
import { submitFeedbackValidation } from "../middleware/feedbackValidation.js";

const router = express.Router();

router.post(
  "/service-requests/:requestId/feedback",
  protectRoute,
  submitFeedbackValidation,
  submitFeedback,
);

export default router;
