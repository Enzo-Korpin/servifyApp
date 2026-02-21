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
