import express from "express";
import {
  getMyNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
} from "../controllers/notification.controller.js";
import { protectRoute } from "../middleware/protecteRoute.js";

const router = express.Router();

router.get("/", protectRoute, getMyNotifications);

router.patch("/read-all", protectRoute, markAllNotificationsAsRead);

router.patch("/:id/read", protectRoute, markNotificationAsRead);

export default router;