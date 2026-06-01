import ServiceRequest from "../models/serviceRequest.js";
import WorkerProfile from "../models/workerProfile.js";
import Feedback from "../models/feedback.js";
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

export const getWorkerFeedbacks = asyncHandler(async (req, res) => {
  const { workerId } = req.params;

  if (!mongoose.Types.ObjectId.isValid(workerId)) {
    throw new BadRequestError("Invalid worker id", "INVALID_WORKER_ID");
  }

  const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);

  const feedbacks = await Feedback.find({ workerId })
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate("customerId", "fullName image")
    .lean();

  const data = feedbacks.map((f) => ({
    _id: f._id,
    rating: f.rate,
    comment: f.comment,
    createdAt: f.createdAt,
    customer: f.customerId
      ? {
          _id: f.customerId._id,
          fullName: f.customerId.fullName || "",
          image: f.customerId.image || "",
        }
      : null,
  }));

  return res.status(200).json({
    success: true,
    data,
    error: null,
  });
});
import {
  invalidateAdminStats,
  invalidateWorkerPublic,
} from "../lib/cache.js";

export const submitFeedback = asyncHandler(async (req, res) => {
  const session = await mongoose.startSession();

  try {
    const { requestId } = req.params;
    const { rate, comment } = req.body;
    const customerId = req.user._id;

    if (req.user.currentRole !== "customer") {
      throw new ForbiddenError("Must be Customer", "MUST_BE_CUSTOMER");
    }

    let responseData;

    await session.withTransaction(async () => {
      const serviceRequest =
        await ServiceRequest.findById(requestId).session(session);

      if (!serviceRequest) {
        throw new NotFoundError(
          "Service request not found",
          "SERVICE_REQUEST_NOT_FOUND",
        );
      }

      if (serviceRequest.customerId.toString() !== customerId.toString()) {
        throw new ForbiddenError(
          "Not allowed to submit feedback for this request",
          "NOT_ALLOWED",
        );
      }

      if (serviceRequest.status !== "accepted") {
        throw new BadRequestError(
          "Cannot submit feedback unless request is accepted",
          "REQUEST_NOT_ACCEPTED",
        );
      }

      const workerProfile = await WorkerProfile.findById(
        serviceRequest.workerId,
      ).session(session);

      if (!workerProfile) {
        throw new NotFoundError(
          "Worker profile not found",
          "WORKER_PROFILE_NOT_FOUND",
        );
      }

      const [feedback] = await Feedback.create(
        [
          {
            requestId: serviceRequest._id,
            customerId: serviceRequest.customerId,
            workerId: serviceRequest.workerId,
            rate,
            comment,
          },
        ],
        { session },
      );

      workerProfile.ratingSum += rate;
      workerProfile.ratingCount += 1;
      workerProfile.rate = Math.max(
        Math.min(
          5,
          Math.round(
            (workerProfile.ratingSum / workerProfile.ratingCount) * 10,
          ) / 10,
        ),
        0,
      );

      await workerProfile.save({ session });

      responseData = {
        feedback: {
          _id: feedback._id,
          requestId: feedback.requestId,
          workerId: feedback.workerId,
          customerId: feedback.customerId,
          rating: feedback.rate,
          comment: feedback.comment,
          createdAt: feedback.createdAt,
        },
        workerRating: {
          avg: workerProfile.rate,
          count: workerProfile.ratingCount,
        },
      };
    });

    // New rating → drop the worker's public cache (rating/count changed) and
    // wipe admin stats (avg rating + top-workers list both shift).
    // Fire-and-forget; failures don't block the response.
    if (responseData?.feedback?.workerId) {
      invalidateWorkerPublic(responseData.feedback.workerId);
    }
    invalidateAdminStats();

    return res.status(201).json({
      success: true,
      data: responseData,
      error: null,
    });
  } catch (error) {
    if (error?.code === 11000) {
      throw new ConflictError(
        "Feedback already submitted for this request",
        "FEEDBACK_ALREADY_SUBMITTED",
      );
    }

    throw error;
  } finally {
    await session.endSession();
  }
});
