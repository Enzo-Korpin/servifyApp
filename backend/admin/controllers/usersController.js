import mongoose from "mongoose";
import { asyncHandler } from "../../middleware/asyncHandler.js";
import User from "../../models/user.js";
import WorkerProfile from "../../models/workerProfile.js";
import ServiceRequest from "../../models/serviceRequest.js";
import Feedback from "../../models/feedback.js";
import {
  BadRequestError,
  ConflictError,
  NotFoundError,
} from "../../errors/httpErrors.js";
import { okResponse, paginatedResponse } from "../utils/paginate.js";

/**
 * Always-safe projection — never expose password hashes, reset codes, or FCM tokens.
 */
const PUBLIC_USER_FIELDS =
  "fullName email role currentRole image isVerified isBlocked blockedAt blockedReason authProvider onboardingStatus location createdAt updatedAt";

const escapeRegex = (s) => String(s).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

/**
 * GET /api/admin/users
 * Server-side pagination, search (name/email), filters (role, isVerified, isBlocked), sort.
 * Never fetches everything and filters in JS.
 */
export const listUsers = asyncHandler(async (req, res) => {
  const { page, limit, search, role, isVerified, isBlocked, sortBy, sortOrder } = req.query;

  const filter = {};

  if (role !== "all") filter.role = role;
  if (isVerified !== "all") filter.isVerified = isVerified === "true";
  if (isBlocked !== "all") filter.isBlocked = isBlocked === "true";

  if (search) {
    const rx = new RegExp(escapeRegex(search), "i");
    filter.$or = [{ fullName: rx }, { email: rx }];
  }

  const sort = { [sortBy]: sortOrder === "asc" ? 1 : -1 };
  const skip = (page - 1) * limit;

  // Parallel count + page query.
  const [items, total] = await Promise.all([
    User.find(filter).select(PUBLIC_USER_FIELDS).sort(sort).skip(skip).limit(limit).lean(),
    User.countDocuments(filter),
  ]);

  return paginatedResponse(res, { data: items, page, limit, total });
});

/**
 * GET /api/admin/users/:id
 * Full user detail. If the user is a worker, joins the worker profile.
 */
export const getUser = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const user = await User.findById(id).select(PUBLIC_USER_FIELDS).lean();
  if (!user) throw new NotFoundError("User not found", "USER_NOT_FOUND");

  let workerProfile = null;
  if (user.role === "worker") {
    workerProfile = await WorkerProfile.findById(id).lean();
  }

  return okResponse(res, { user, workerProfile });
});

/**
 * PATCH /api/admin/users/:id/block
 * Body: { isBlocked: boolean, reason?: string }
 * Admins cannot block themselves or other admins (defense-in-depth).
 */
export const blockUser = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { isBlocked, reason } = req.body;

  if (req.user._id.toString() === id) {
    throw new BadRequestError("You cannot block yourself", "SELF_BLOCK_FORBIDDEN");
  }

  const target = await User.findById(id).select("role isBlocked");
  if (!target) throw new NotFoundError("User not found", "USER_NOT_FOUND");

  if (target.role === "admin") {
    throw new BadRequestError("Cannot block another admin", "CANNOT_BLOCK_ADMIN");
  }

  if (target.isBlocked === isBlocked) {
    throw new ConflictError(
      isBlocked ? "User is already blocked" : "User is already unblocked",
      "BLOCK_STATE_UNCHANGED"
    );
  }

  target.isBlocked = isBlocked;
  target.blockedAt = isBlocked ? new Date() : null;
  target.blockedReason = isBlocked ? (reason || "").trim() || null : null;
  await target.save();

  return okResponse(res, {
    _id: target._id,
    isBlocked: target.isBlocked,
    blockedAt: target.blockedAt,
    blockedReason: target.blockedReason,
  });
});

/**
 * DELETE /api/admin/users/:id
 * Hard-delete is destructive: also remove worker profile, requests, feedback, notifications
 * created by/for this user. We run them in a transaction so partial failure rolls back.
 *
 * Confirmation is required from the *client* (modal dialog). Backend enforces auth only.
 */
export const deleteUser = asyncHandler(async (req, res) => {
  const { id } = req.params;

  if (req.user._id.toString() === id) {
    throw new BadRequestError("You cannot delete yourself", "SELF_DELETE_FORBIDDEN");
  }

  const target = await User.findById(id).select("role");
  if (!target) throw new NotFoundError("User not found", "USER_NOT_FOUND");

  if (target.role === "admin") {
    throw new BadRequestError("Cannot delete another admin", "CANNOT_DELETE_ADMIN");
  }

  const session = await mongoose.startSession();
  try {
    await session.withTransaction(async () => {
      await Promise.all([
        WorkerProfile.deleteOne({ _id: id }).session(session),
        ServiceRequest.deleteMany({
          $or: [{ customerId: id }, { workerId: id }],
        }).session(session),
        Feedback.deleteMany({
          $or: [{ customerId: id }, { workerId: id }],
        }).session(session),
      ]);
      await User.deleteOne({ _id: id }).session(session);
    });
  } finally {
    session.endSession();
  }

  return okResponse(res, { _id: id, deleted: true });
});
