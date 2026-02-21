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

export const submitFeedback = asyncHandler(async (req, res) => {
  const session = await mongoose.startSession();
  const safeAbort = async () => {
    await session.abortTransaction();
  };

  try {
    const { requestId } = req.params;
    const { rate, comment } = req.body;
    const customerId = req.user._id;

    if (req.user.currentRole !== "customer") {
      throw new ForbiddenError("Must be Customer", "MUST_BE_CUSTOMER");
    }
    session.startTransaction();

    const serviceRequest =
      await ServiceRequest.findById(requestId).session(session);

    if (!serviceRequest) {
      await safeAbort();
      throw new NotFoundError(
        "Service request not found",
        "SERVICE_REQUEST_NOT_FOUND",
      );
    }

    if (serviceRequest.customerId.toString() !== customerId.toString()) {
      await safeAbort();
      throw new ForbiddenError(
        "Not allowed to submit feedback for this request",
        "NOT_ALLOWED",
      );
    }

    if (serviceRequest.status !== "accepted") {
      await safeAbort();
      throw new BadRequestError(
        "Cannot submit feedback unless request is accepted",
        "REQUEST_NOT_ACCEPTED",
      );
    }

    const feedbackDoc = await Feedback.create(
      [
        {
          requestId: serviceRequest._id,
          customerId: serviceRequest.customerId,
          workerId: serviceRequest.workerId,
          rate: rate,
          comment,
        },
      ],
      { session },
    );

    const feedback = feedbackDoc[0];
    const updatedWorker = await WorkerProfile.findByIdAndUpdate(
      serviceRequest.workerId,
      {
        $inc: { ratingSum: rate, ratingCount: 1 },
      },
      {
        new: true,
        session,
      },
    );
    if (!updatedWorker) {
      await safeAbort();
      throw new NotFoundError(
        "Worker profile not found",
        "WORKER_PROFILE_NOT_FOUND",
      );
    }
    updatedWorker.rate = Math.max(
      Math.min(
        5,
        Math.round((updatedWorker.ratingSum / updatedWorker.ratingCount) * 10) /
          10,
      ),
      0,
    );

    await updatedWorker.save({ session });

    await serviceRequest.save({ session });

    await session.commitTransaction();

    return res.status(201).json({
      sucsess: true,
      data: {
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
          avg: updatedWorker.rate,
          count: updatedWorker.ratingCount,
        },
      },
      error: null,
    });
  } finally {
    session.endSession();
  }
});
