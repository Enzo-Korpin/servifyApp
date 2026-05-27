import express from "express";

import { protectRoute } from "../middleware/protecteRoute.js";
import { submitFeedback } from "../service/feedbackService.js";
import { submitFeedbackValidation } from "../middleware/feedbackValidation.js";
import { submitFeedbackLimiter } from "../lib/rateLimit.js";

const router = express.Router();

router.post(
  "/:requestId",
  protectRoute,
  // Per-user limiter complements arcjet (per-IP) — 5 feedbacks / minute / user.
  submitFeedbackLimiter,
  submitFeedbackValidation,
  submitFeedback,
);

export default router;
