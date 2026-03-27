import express from "express";
import { sendMessage, getMessages, getUserConversations } from "./ai.controller.js";
import { protectRoute } from "../middleware/protecteRoute.js";
const router = express.Router();

router.post("/messages",protectRoute, sendMessage);
router.get("/conversations/:conversationId/messages", protectRoute, getMessages);
router.get("/conversations", protectRoute, getUserConversations);

export default router;