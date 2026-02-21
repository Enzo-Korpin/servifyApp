import express from "express";
import {
  getMessages,
  getUsersForSidebar,
  sendMessage,
} from "../service/messageService.js";
import { protectRoute } from "../middleware/protecteRoute.js";

import { sendMessageValidation } from "../middleware/messageValidation.js";

const router = express.Router();

router.get("/users", protectRoute, getUsersForSidebar);
router.get("/:id", protectRoute, getMessages);

router.post("/send/:id", protectRoute, sendMessageValidation, sendMessage);

export default router;
