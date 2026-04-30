import express from "express";
import {
  getMessages,
  getUsersForSidebar,
  sendMessage,
} from "../service/messageService.js";
import { protectRoute } from "../middleware/protecteRoute.js";
import { requireCompletedOnboarding } from "../middleware/requireCompletedOnboarding.js";

import { sendMessageValidation } from "../middleware/messageValidation.js";

const router = express.Router();

router.get("/users", protectRoute, requireCompletedOnboarding, getUsersForSidebar);
router.get("/:id", protectRoute, requireCompletedOnboarding, getMessages);

router.post("/send/:id", protectRoute, requireCompletedOnboarding, sendMessageValidation, sendMessage);

export default router;
