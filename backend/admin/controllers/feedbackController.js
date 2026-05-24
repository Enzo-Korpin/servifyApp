import mongoose from "mongoose";
import { asyncHandler } from "../../middleware/asyncHandler.js";
import Feedback from "../../models/feedback.js";
import WorkerProfile from "../../models/workerProfile.js";
import User from "../../models/user.js";
import { NotFoundError } from "../../errors/httpErrors.js";
import { okResponse, paginatedResponse } from "../utils/paginate.js";

const escapeRegex = (s) => String(s).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

/**
 * GET /api/admin/feedback
 * Paginated feedback list with rating range, free-text search across worker/customer name/email.
 *
 * Search is implemented as a User filter (separate query) → ID set → feedback filter.
 * This avoids cross-collection $lookup in the hot path while still keeping pagination
 * accurate on the indexed Feedback collection.
 */
export const listFeedback = asyncHandler(async (req, res) => {
  const {
    page,
    limit,
    minRating,
    maxRating,
    search,
    workerId,
    customerId,
    sortBy,
    sortOrder,
  } = req.query;

  const filter = { rate: { $gte: minRating, $lte: maxRating } };
  if (workerId) filter.workerId = workerId;
  if (customerId) filter.customerId = customerId;

  if (search) {
    const rx = new RegExp(escapeRegex(search), "i");
    const matchingUserIds = await User.find({
      $or: [{ fullName: rx }, { email: rx }],
    })
      .select("_id")
      .lean();
    const ids = matchingUserIds.map((u) => u._id);
    if (ids.length === 0) {
      return paginatedResponse(res, { data: [], page, limit, total: 0 });
    }
    filter.$or = [{ workerId: { $in: ids } }, { customerId: { $in: ids } }];
  }

  const sort = { [sortBy]: sortOrder === "asc" ? 1 : -1 };
  const skip = (page - 1) * limit;

  const [items, total] = await Promise.all([
    Feedback.find(filter)
      .populate({ path: "customerId", select: "fullName email image" })
      .populate({ path: "workerId", select: "fullName email image" })
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean(),
    Feedback.countDocuments(filter),
  ]);

  return paginatedResponse(res, { data: items, page, limit, total });
});

/**
 * GET /api/admin/feedback/:id
 */
export const getFeedback = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const fb = await Feedback.findById(id)
    .populate({ path: "customerId", select: "fullName email image" })
    .populate({ path: "workerId", select: "fullName email image" })
    .lean();

  if (!fb) throw new NotFoundError("Feedback not found", "FEEDBACK_NOT_FOUND");
  return okResponse(res, fb);
});

/**
 * DELETE /api/admin/feedback/:id
 * Removing feedback must also decrement the worker's aggregate (rate, ratingSum, ratingCount).
 * Run in a transaction so deletes never get out of sync with the rollup.
 */
export const deleteFeedback = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const fb = await Feedback.findById(id).lean();
  if (!fb) throw new NotFoundError("Feedback not found", "FEEDBACK_NOT_FOUND");

  const session = await mongoose.startSession();
  try {
    await session.withTransaction(async () => {
      await Feedback.deleteOne({ _id: id }).session(session);

      const profile = await WorkerProfile.findById(fb.workerId).session(session);
      if (profile) {
        const nextCount = Math.max(0, (profile.ratingCount || 0) - 1);
        const nextSum = Math.max(0, (profile.ratingSum || 0) - fb.rate);
        profile.ratingCount = nextCount;
        profile.ratingSum = nextSum;
        profile.rate = nextCount === 0 ? 0 : Number((nextSum / nextCount).toFixed(2));
        await profile.save({ session });
      }
    });
  } finally {
    session.endSession();
  }

  return okResponse(res, { _id: id, deleted: true });
});
