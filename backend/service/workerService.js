import serviceRequest from "../models/serviceRequest.js";
import WorkerProfile from "../models/workerProfile.js";
import mongoose from "mongoose";

import { asyncHandler } from "../middleware/asyncHandler.js";
import {
  BadRequestError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  PayloadTooLargeError,
} from "../errors/httpErrors.js";
import { PassThrough } from "stream";

export const getWorkerProfile = asyncHandler(async (req, res) => {});

export const updateWorkerProfile = asyncHandler(async (req, res) => {});

export const getAllWorkers = asyncHandler(async (req, res) => {
  const rawLimit = req.query.limit;
  const parsedLimit = Number.parseInt(rawLimit, 10);

  if (
    rawLimit !== undefined &&
    (!Number.isInteger(parsedLimit) || parsedLimit <= 0)
  ) {
    throw new BadRequestError(
      "limit must be a positive integer",
      "INVALID_LIMIT",
    );
  }

  const limit = rawLimit === undefined ? 10 : Math.min(parsedLimit, 10);
  const before = req.query.before;

  const query = {};

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

    query.$or = [
      { createdAt: { $lt: beforeDate } },
      {
        createdAt: beforeDate,
        _id: { $lt: new mongoose.Types.ObjectId(beforeId) },
      },
    ];
  }

  const docs = await WorkerProfile.find(query)
    .sort({ createdAt: -1, _id: -1 })
    .limit(limit)
    .populate("_id", "fullName image role")
    .lean();

  const workers = docs.reverse();

  const nextCursor =
    docs.length > 0
      ? `${docs[docs.length - 1].createdAt.toISOString()}|${docs[docs.length - 1]._id._id}`
      : null;

  return res.status(200).json({
    success: true,
    data: { workers, nextCursor },
    error: null,
  });
});

export const getWorkerById = asyncHandler(async (req, res) => {
  const workerId = req.params.id;
  if (!mongoose.Types.ObjectId.isValid(workerId)) {
    throw new BadRequestError("Invalid worker ID", "INVALID_WORKER_ID");
  }
  const worker = await WorkerProfile.findById(workerId).populate(
    "_id",
    "-password",
  );
  if (!worker) {
    throw new NotFoundError("Worker not found", "WORKER_NOT_FOUND");
  }
  return res.status(200).json({ success: true, data: worker, error: null });
});

export const switchRole = asyncHandler(async (req, res) => {
  const userId = req.user._id;
  const { targetRole } = req.body;

  if (!["customer", "worker"].includes(targetRole)) {
    throw new BadRequestError("Invalid target role", "INVALID_TARGET_ROLE");
  }

  if (req.user.role === "customer" && targetRole === "worker") {
    throw new ForbiddenError(
      "Customers are not allowed to switch to worker",
      "CUSTOMER_NOT_ALLOWED_TO_SWITCH_TO_WORKER",
    );
  }

  if (targetRole === "worker") {
    const hasProfile = await WorkerProfile.exists({ _id: userId });
    if (!hasProfile) {
      throw new ConflictError(
        "Worker profile not found. Please create a worker profile before switching to worker role.",
        "WORKER_PROFILE_NOT_FOUND",
      );
    }
  }

  if (req.user.currentRole === targetRole) {
    throw new BadRequestError(
      `Already in ${targetRole} role`,
      "ALREADY_IN_TARGET_ROLE",
    );
  }

  req.user.currentRole = targetRole;
  await req.user.save();

  return res.status(200).json({
    success: true,
    data: { currentRole: req.user.currentRole },
    error: null,
  });
});

export const getWorkerStatus = asyncHandler(async (req, res) => {
  const workerId = req.user._id;
  if (req.user.currentRole !== "worker") {
    throw new ForbiddenError("Must be Worker", "MUST_BE_WORKER");
  }
  const rows = await serviceRequest.aggregate([
    {
      $match: {
        workerId: new mongoose.Types.ObjectId(workerId),
        status: { $in: ["pending", "accepted", "rejected"] },
      },
    },
    {
      $group: {
        _id: "$status",
        count: { $sum: 1 },
      },
    },
  ]);
  const stats = { pending: 0, accepted: 0, rejected: 0 };
  rows.forEach((row) => {
    stats[row._id] = row.count;
  });
  return res.status(200).json({ success: true, data: stats, error: null });
});
