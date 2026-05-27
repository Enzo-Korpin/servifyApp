import { asyncHandler } from "../../middleware/asyncHandler.js";
import User from "../../models/user.js";
import WorkerProfile from "../../models/workerProfile.js";
import ServiceRequest from "../../models/serviceRequest.js";
import Feedback from "../../models/feedback.js";
import { okResponse } from "../utils/paginate.js";
import { withCache, cacheKeys } from "../../lib/cache.js";

// All admin stats endpoints are read-heavy and idempotent — cache them.
// 60s TTL is short enough that mutations propagate naturally between manual
// refreshes; mutation handlers (block/delete) also explicitly invalidate.
const STATS_TTL_SEC = 60;

const startOfThisMonth = () => {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth(), 1);
};

/**
 * GET /api/admin/stats
 * Big summary cards for the dashboard landing page. Uses Promise.all for parallelism
 * and `countDocuments` (with indexed filters) — no heavy aggregations on the hot path.
 */
export const getStats = asyncHandler(async (_req, res) => {
  const data = await withCache(cacheKeys.adminStats(), STATS_TTL_SEC, () =>
    computeStats(),
  );
  return okResponse(res, data);
});

const computeStats = async () => {
  const monthStart = startOfThisMonth();

  const [
    totalUsers,
    totalCustomers,
    totalWorkers,
    totalAdmins,
    blockedUsers,
    verifiedUsers,
    pendingRequests,
    acceptedRequests,
    rejectedRequests,
    cancelledRequests,
    totalRequests,
    feedbackCount,
    ratingAgg,
    newUsersThisMonth,
    requestsThisMonth,
  ] = await Promise.all([
    User.countDocuments({}),
    User.countDocuments({ role: "customer" }),
    User.countDocuments({ role: "worker" }),
    User.countDocuments({ role: "admin" }),
    User.countDocuments({ isBlocked: true }),
    User.countDocuments({ isVerified: true }),
    ServiceRequest.countDocuments({ status: "pending" }),
    ServiceRequest.countDocuments({ status: "accepted" }),
    ServiceRequest.countDocuments({ status: "rejected" }),
    ServiceRequest.countDocuments({ status: "cancelled" }),
    ServiceRequest.countDocuments({}),
    Feedback.countDocuments({}),
    Feedback.aggregate([
      { $group: { _id: null, avg: { $avg: "$rate" }, count: { $sum: 1 } } },
    ]),
    User.countDocuments({ createdAt: { $gte: monthStart } }),
    ServiceRequest.countDocuments({ createdAt: { $gte: monthStart } }),
  ]);

  const averageRating = ratingAgg[0]?.avg ? Number(ratingAgg[0].avg.toFixed(2)) : 0;

  return {
    users: {
      total: totalUsers,
      customers: totalCustomers,
      workers: totalWorkers,
      admins: totalAdmins,
      blocked: blockedUsers,
      verified: verifiedUsers,
      newThisMonth: newUsersThisMonth,
    },
    requests: {
      total: totalRequests,
      pending: pendingRequests,
      accepted: acceptedRequests,
      rejected: rejectedRequests,
      cancelled: cancelledRequests,
      thisMonth: requestsThisMonth,
    },
    feedback: {
      total: feedbackCount,
      averageRating,
    },
  };
};

/**
 * GET /api/admin/stats/users-growth
 * Daily new-user counts over the last N days (default 30). Optimized by:
 *   - filtering by createdAt range (uses our index)
 *   - projecting only what we need into a small grouping stage
 */
export const getUsersGrowth = asyncHandler(async (req, res) => {
  const days = Math.min(Math.max(Number(req.query.days) || 30, 1), 180);
  const data = await withCache(
    cacheKeys.adminStatsGrowth(days),
    STATS_TTL_SEC,
    () => computeUsersGrowth(days),
  );
  return okResponse(res, data);
});

const computeUsersGrowth = async (days) => {
  const since = new Date();
  since.setUTCHours(0, 0, 0, 0);
  since.setUTCDate(since.getUTCDate() - (days - 1));

  const rows = await User.aggregate([
    { $match: { createdAt: { $gte: since } } },
    {
      $group: {
        _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt", timezone: "UTC" } },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  const map = new Map(rows.map((r) => [r._id, r.count]));
  const series = [];
  for (let i = 0; i < days; i++) {
    const d = new Date(since);
    d.setUTCDate(since.getUTCDate() + i);
    const key = d.toISOString().slice(0, 10);
    series.push({ date: key, count: map.get(key) ?? 0 });
  }

  return { days, series };
};

/**
 * GET /api/admin/stats/requests-by-status
 * Simple pie-chart fuel.
 */
export const getRequestsByStatus = asyncHandler(async (_req, res) => {
  const data = await withCache(
    cacheKeys.adminStatsByStatus(),
    STATS_TTL_SEC,
    async () => {
      const rows = await ServiceRequest.aggregate([
        { $group: { _id: "$status", count: { $sum: 1 } } },
      ]);
      return rows.map((r) => ({ status: r._id, count: r.count }));
    },
  );
  return okResponse(res, data);
});

/**
 * GET /api/admin/stats/top-workers?limit=5
 * Top-rated workers (must have at least 1 rating).
 */
export const getTopWorkers = asyncHandler(async (req, res) => {
  const limit = Math.min(Math.max(Number(req.query.limit) || 5, 1), 20);

  const workers = await withCache(
    cacheKeys.adminStatsTopWorkers(limit),
    STATS_TTL_SEC,
    () =>
      WorkerProfile.aggregate([
        { $match: { ratingCount: { $gt: 0 } } },
        { $sort: { rate: -1, ratingCount: -1 } },
        { $limit: limit },
        {
          $lookup: {
            from: "users",
            localField: "_id",
            foreignField: "_id",
            as: "user",
            pipeline: [{ $project: { fullName: 1, email: 1, image: 1, isBlocked: 1 } }],
          },
        },
        { $unwind: "$user" },
        {
          $project: {
            _id: 1,
            rate: 1,
            ratingCount: 1,
            yearsOfExperience: 1,
            skills: 1,
            user: 1,
          },
        },
      ]),
  );

  return okResponse(res, workers);
});

/**
 * GET /api/admin/stats/most-active-customers?limit=5
 * Customers who created the most service requests.
 */
export const getMostActiveCustomers = asyncHandler(async (req, res) => {
  const limit = Math.min(Math.max(Number(req.query.limit) || 5, 1), 20);

  const customers = await withCache(
    cacheKeys.adminStatsActiveCustomers(limit),
    STATS_TTL_SEC,
    () =>
      ServiceRequest.aggregate([
        { $group: { _id: "$customerId", requestCount: { $sum: 1 } } },
        { $sort: { requestCount: -1 } },
        { $limit: limit },
        {
          $lookup: {
            from: "users",
            localField: "_id",
            foreignField: "_id",
            as: "user",
            pipeline: [{ $project: { fullName: 1, email: 1, image: 1, role: 1 } }],
          },
        },
        { $unwind: "$user" },
        { $project: { _id: 1, requestCount: 1, user: 1 } },
      ]),
  );

  return okResponse(res, customers);
});
