import { asyncHandler } from "../../middleware/asyncHandler.js";
import User from "../../models/user.js";
import WorkerProfile from "../../models/workerProfile.js";
import ServiceRequest from "../../models/serviceRequest.js";
import Feedback from "../../models/feedback.js";
import { NotFoundError } from "../../errors/httpErrors.js";
import { okResponse, paginatedResponse } from "../utils/paginate.js";

const escapeRegex = (s) => String(s).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

/**
 * GET /api/admin/workers
 * Joins User + WorkerProfile, filters/searches on either side, paginates.
 *
 * We start from WorkerProfile because:
 *   - filters like minRating/minExperience apply to WorkerProfile fields
 *   - the join to User is 1:1 ($lookup unwind), so ordering remains stable
 */
export const listWorkers = asyncHandler(async (req, res) => {
  const { page, limit, search, minRating, minExperience, sortBy, sortOrder } = req.query;

  const profileMatch = {};
  if (minRating > 0) profileMatch.rate = { $gte: minRating };
  if (minExperience > 0) profileMatch.yearsOfExperience = { $gte: minExperience };

  const userMatch = { "user.role": "worker" };
  if (search) {
    const rx = new RegExp(escapeRegex(search), "i");
    userMatch.$or = [
      { "user.fullName": rx },
      { "user.email": rx },
      { skills: rx },
    ];
  }

  const sortField =
    sortBy === "rate"
      ? "rate"
      : sortBy === "ratingCount"
      ? "ratingCount"
      : sortBy === "yearsOfExperience"
      ? "yearsOfExperience"
      : "createdAt";

  const sortStage = { [sortField]: sortOrder === "asc" ? 1 : -1 };
  const skip = (page - 1) * limit;

  const basePipeline = [
    { $match: profileMatch },
    {
      $lookup: {
        from: "users",
        localField: "_id",
        foreignField: "_id",
        as: "user",
        pipeline: [
          {
            $project: {
              fullName: 1,
              email: 1,
              image: 1,
              role: 1,
              isBlocked: 1,
              isVerified: 1,
              location: 1,
              createdAt: 1,
            },
          },
        ],
      },
    },
    { $unwind: "$user" },
    { $match: userMatch },
  ];

  const [items, totalRows] = await Promise.all([
    WorkerProfile.aggregate([
      ...basePipeline,
      { $sort: sortStage },
      { $skip: skip },
      { $limit: limit },
    ]),
    WorkerProfile.aggregate([...basePipeline, { $count: "total" }]),
  ]);

  const total = totalRows[0]?.total ?? 0;
  return paginatedResponse(res, { data: items, page, limit, total });
});

/**
 * GET /api/admin/workers/:id
 * Worker user + profile + last requests + last feedback (capped, fast).
 */
export const getWorker = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const [user, workerProfile] = await Promise.all([
    User.findOne({ _id: id, role: "worker" })
      .select(
        "fullName email image role isVerified isBlocked blockedAt blockedReason location createdAt"
      )
      .lean(),
    WorkerProfile.findById(id).lean(),
  ]);

  if (!user) throw new NotFoundError("Worker not found", "WORKER_NOT_FOUND");

  const [recentRequests, recentFeedback, requestCounts] = await Promise.all([
    ServiceRequest.find({ workerId: id })
      .select("customerId status message createdAt acceptedAt rejectedAt cancelledAt")
      .populate({ path: "customerId", select: "fullName email image" })
      .sort({ createdAt: -1 })
      .limit(10)
      .lean(),
    Feedback.find({ workerId: id })
      .select("rate comment customerId createdAt")
      .populate({ path: "customerId", select: "fullName email image" })
      .sort({ createdAt: -1 })
      .limit(10)
      .lean(),
    ServiceRequest.aggregate([
      { $match: { workerId: user._id } },
      { $group: { _id: "$status", count: { $sum: 1 } } },
    ]),
  ]);

  const counts = { pending: 0, accepted: 0, rejected: 0, cancelled: 0 };
  for (const row of requestCounts) counts[row._id] = row.count;

  return okResponse(res, {
    user,
    workerProfile,
    recentRequests,
    recentFeedback,
    requestCounts: counts,
  });
});
