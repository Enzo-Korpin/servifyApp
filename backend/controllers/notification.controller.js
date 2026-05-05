import Notification from "../models/notification.js";
import { asyncHandler } from "../middleware/asyncHandler.js";

export const getMyNotifications = asyncHandler(async (req, res) => {
  const userId = req.user._id;

  const notifications = await Notification.find({ userId })
    .sort({ createdAt: -1 })
    .limit(50)
    .lean();

  return res.status(200).json({
    success: true,
    data: notifications,
    error: null,
  });
});

export const markNotificationAsRead = asyncHandler(async (req, res) => {
  const userId = req.user._id;
  const { id } = req.params;

  const notification = await Notification.findOneAndUpdate(
    {
      _id: id,
      userId,
    },
    {
      $set: {
        isRead: true,
      },
    },
    { new: true }
  );

  if (!notification) {
    return res.status(404).json({
      success: false,
      data: null,
      error: {
        message: "Notification not found",
      },
    });
  }

  return res.status(200).json({
    success: true,
    data: notification,
    error: null,
  });
});

export const markAllNotificationsAsRead = asyncHandler(async (req, res) => {
  const userId = req.user._id;

  await Notification.updateMany(
    {
      userId,
      isRead: false,
    },
    {
      $set: {
        isRead: true,
      },
    }
  );

  return res.status(200).json({
    success: true,
    message: "All notifications marked as read",
    error: null,
  });
});