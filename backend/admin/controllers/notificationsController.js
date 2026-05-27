import { asyncHandler } from "../../middleware/asyncHandler.js";
import Notification from "../../models/notification.js";
import ServiceRequest from "../../models/serviceRequest.js";
import Feedback from "../../models/feedback.js";
import User from "../../models/user.js";
import { okResponse, paginatedResponse } from "../utils/paginate.js";
import { withCache, cacheKeys } from "../../lib/cache.js";

/**
 * GET /api/admin/notifications
 * Lists all system notifications (across all users). Useful for moderation/audit.
 */
export const listNotifications = asyncHandler(async (req, res) => {
  const { page, limit, type, isRead } = req.query;

  const filter = {};
  if (type !== "all") filter.type = type;
  if (isRead !== "all") filter.isRead = isRead === "true";

  const skip = (page - 1) * limit;

  const [items, total] = await Promise.all([
    Notification.find(filter)
      .populate({ path: "userId", select: "fullName email image role" })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Notification.countDocuments(filter),
  ]);

  return paginatedResponse(res, { data: items, page, limit, total });
});

/**
 * GET /api/admin/reports/overview
 * High-level KPIs for the reports page — derived metrics (acceptance rate, etc.).
 */
export const getReportsOverview = asyncHandler(async (_req, res) => {
  const data = await withCache(
    cacheKeys.adminReportsOverview(),
    60,
    async () => {
      const monthAgo = new Date();
      monthAgo.setDate(monthAgo.getDate() - 30);

      const [totalReq, accepted, completed, totalNotif, recentUsers] =
        await Promise.all([
          ServiceRequest.countDocuments({}),
          ServiceRequest.countDocuments({ status: "accepted" }),
          Feedback.countDocuments({}),
          Notification.countDocuments({}),
          User.countDocuments({ createdAt: { $gte: monthAgo } }),
        ]);

      return {
        requests: {
          total: totalReq,
          accepted,
          acceptanceRate:
            totalReq === 0 ? 0 : Number(((accepted / totalReq) * 100).toFixed(1)),
        },
        feedback: { completedJobs: completed },
        notifications: { total: totalNotif },
        growth: { last30Days: recentUsers },
      };
    },
  );
  return okResponse(res, data);
});
