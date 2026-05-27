import mongoose from "mongoose";
import User from "../models/user.js";
import follow from "../models/follow.js";
import { asyncHandler } from "../middleware/asyncHandler.js";
import {
  BadRequestError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  PayloadTooLargeError,
} from "../errors/httpErrors.js";

export const followWorker = asyncHandler(async (req, res) => {
  const { workerId } = req.params;
  const customerId = req.user._id;

  if (req.user.currentRole !== "customer") {
    throw new ForbiddenError("Must be Customer", "MUST_BE_CUSTOMER");
  }

  if (!mongoose.Types.ObjectId.isValid(workerId)) {
    throw new BadRequestError("Invalid workerId", "INVALID_WORKER_ID");
  }

  if (String(customerId) === String(workerId)) {
    throw new BadRequestError("Cannot follow yourself", "CANNOT_FOLLOW_SELF");
  }

  const workerExists = await User.exists({ _id: workerId, role: "worker" });
  if (!workerExists) {
    throw new NotFoundError("Worker not found", "WORKER_NOT_FOUND");
  }

  try {
    await follow.create({
      customerId,
      workerId,
    });

    return res.status(201).json({
      success: true,
      data: null,
      error: null,
    });
  } catch (error) {
    if (error?.code === 11000) {
      throw new ConflictError(
        "Already following this worker",
        "ALREADY_FOLLOWING",
      );
    }

    throw error;
  }
});

export const unfollowWorker = asyncHandler(async (req, res) => {
  const { workerId } = req.params;
  const customerId = req.user._id;

  if (req.user.currentRole !== "customer") {
    throw new ForbiddenError("Must be Customer", "MUST_BE_CUSTOMER");
  }

  if (!mongoose.Types.ObjectId.isValid(workerId)) {
    throw new BadRequestError("Invalid workerId", "INVALID_WORKER_ID");
  }

  const workerExists = await User.exists({ _id: workerId, role: "worker" });
  if (!workerExists) {
    throw new NotFoundError("Worker not found", "WORKER_NOT_FOUND");
  }

  const deleted = await follow.deleteOne({
    customerId,
    workerId,
  });

  if (deleted.deletedCount === 0) {
    throw new NotFoundError(
      "Not following this worker",
      "NOT_FOLLOWING_WORKER",
    );
  }

  return res.status(200).json({
    success: true,
    data: null,
    error: null,
  });
});

export const getFollowingWorker = asyncHandler(async (req, res) => {
  const { workerId } = req.params;
  const customerId = req.user._id;
  const isFollowing = await follow
    .findOne({
      customerId: customerId,
      workerId: workerId,
    })
    .populate("workerId", "fullName email")
    .select("-customerId");

  if (!isFollowing) {
    throw new NotFoundError(
      "Not following this worker",
      "NOT_FOLLOWING_WORKER",
    );
  } else {
    return res
      .status(200)
      .json({ success: true, data: isFollowing, error: null });
  }
});

export const getAllFollowingWorkers = asyncHandler(async (req, res) => {
  const customerId = req.user._id;

  const limit = Math.min(parseInt(req.query.limit || "10", 10), 10);
  const before = req.query.before;

  const query = { customerId: customerId };

  if (before) {
    const [beforeDateStr, beforeId] = String(before).split("|");
    const beforeDate = new Date(beforeDateStr);

    if (
      !beforeDateStr ||
      Number.isNaN(beforeDate.getTime()) ||
      !mongoose.Types.ObjectId.isValid(beforeId)
    ) {
      throw new BadRequestError("Invalid 'before' cursor", "INVALID_CURSOR");
    }

    query.$and = [
      {
        $or: [
          { createdAt: { $lt: beforeDate } },
          { createdAt: beforeDate, _id: { $lt: beforeId } },
        ],
      },
    ];
  }

  const docs = await follow
    .find(query)
    .sort({ createdAt: -1, _id: -1 })
    .limit(limit)
    .populate("workerId", "fullName email")
    .select("-customerId")
    .lean();

  const following = docs.reverse();

  const nextCursor =
    docs.length === limit
      ? `${docs[docs.length - 1].createdAt.toISOString()}|${docs[docs.length - 1]._id}`
      : null;

  return res.status(200).json({
    success: true,
    data: { following: following.map((f) => f.workerId), nextCursor },
    error: null,
  });
});
