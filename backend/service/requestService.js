import ServiceRequest from "../models/serviceRequest.js";
import User from "../models/user.js";
import WorkerProfile from "../models/workerProfile.js";
import Chat from "../models/Chat.js";
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

const getServiceRequestsByRole = (requiredRole, fieldName) => {
  return asyncHandler(async (req, res) => {
    const userId = req.user._id;

    if (req.user.currentRole !== requiredRole) {
      throw new ForbiddenError(`Must be ${requiredRole}`, "ROLE_FORBIDDEN");
    }

    const { status } = req.query;
    const limit = Math.min(parseInt(req.query.limit || "20", 10), 10);
    const after = req.query.after;

    const filter = { [fieldName]: userId };
    if (status) filter.status = status;

    if (after) {
      const [dateStr, id] = after.split("|");
      const date = new Date(dateStr);

      if (
        !dateStr ||
        Number.isNaN(date.getTime()) ||
        !mongoose.Types.ObjectId.isValid(id)
      ) {
        throw new BadRequestError("Invalid cursor", "INVALID_CURSOR");
      }

      filter.$or = [
        { createdAt: { $lt: date } },
        { createdAt: date, _id: { $lt: id } },
      ];
    }

    const docs = await ServiceRequest.find(filter)
      .sort({ createdAt: -1, _id: -1 })
      .limit(limit);

    const nextCursor =
      docs.length > 0
        ? `${docs[docs.length - 1].createdAt.toISOString()}|${docs[docs.length - 1]._id}`
        : null;

    return res.status(200).json({
      success: true,
      data: { docs, nextCursor },
      error: null,
    });
  });
};

export const createServiceRequest = asyncHandler(async (req, res) => {
  const customerId = req.user._id;
  const { workerId, message, addressText, lng, lat } = req.body;
  console.log([lng, lat]);

  const location = {
    type: "Point",
    coordinates: [Number(lng), Number(lat)],
  };

  if (req.user.currentRole !== "customer") {
    throw new ForbiddenError("Must be Customer", "ROLE_FORBIDDEN");
  }

  if (!mongoose.Types.ObjectId.isValid(workerId)) {
    throw new BadRequestError("Invalid workerId", "INVALID_WORKER_ID");
  }

  const existsingWorker = await User.findOne({
    _id: workerId,
    role: "worker",
  });

  if (!existsingWorker) {
    throw new NotFoundError("Worker not found", "WORKER_NOT_FOUND");
  }

  const existingRequest = await ServiceRequest.findOne({
    customerId,
    workerId,
    status: "pending",
  });

  if (existingRequest) {
    throw new ConflictError(
      "You already have a pending request with this worker",
      "ALREADY_PENDING_REQUEST",
    );
  }

  const newRequest = await ServiceRequest.create({
    customerId,
    workerId,
    message: (message || "").trim(),
    addressText: (addressText || "").trim(),
    location: {
      type: "Point",
      coordinates: [Number(lng), Number(lat)],
    },
    status: "pending",
    chatId: null,
  });

  return res.status(201).json({ success: true, data: newRequest, error: null });
});

export const cancelServiceRequest = asyncHandler(async (req, res) => {
  const userId = req.user._id;
  const { cancelReason } = req.body ?? {};

  const { id } = req.params;
  const request = await ServiceRequest.findById(id);

  if (!request) {
    throw new NotFoundError("Service request not found", "REQUEST_NOT_FOUND");
  }
  if (request.customerId.toString() !== userId.toString()) {
    throw new ForbiddenError(
      "Not authorized to cancel this request",
      "FORBIDDEN_CANCEL_REQUEST",
    );
  }
  if (request.status !== "pending") {
    throw new BadRequestError(
      "Only pending requests can be cancelled",
      "INVALID_CANCEL_STATUS",
    );
  }
  request.status = "cancelled";
  request.cancelledAt = new Date();
  cancelReason ? (request.cancelReason = cancelReason.trim()) : null;

  await request.save();

  return res.status(200).json({ success: true, data: request, error: null });
});

export const acceptServiceRequest = asyncHandler(async (req, res) => {
  if (req.user.currentRole !== "worker") {
    throw new ForbiddenError("Must be Worker", "ROLE_FORBIDDEN");
  }
  const requestId = req.params.id;
  if (!mongoose.Types.ObjectId.isValid(requestId)) {
    throw new BadRequestError("Invalid request id", "INVALID_REQUEST_ID");
  }

  const request = await ServiceRequest.findById(requestId);
  if (!request)
    throw new NotFoundError("Service request not found", "REQUEST_NOT_FOUND");

  if (request.workerId.toString() !== req.user._id.toString()) {
    throw new ForbiddenError(
      "Not authorized to accept this request",
      "FORBIDDEN_ACCEPT_REQUEST",
    );
  }

  if (request.status !== "pending") {
    throw new BadRequestError(
      `Cannot accept request with status '${request.status}'`,
      "INVALID_ACCEPT_STATUS",
    );
  }

  let chat = await Chat.findOne({
    customerId: request.customerId,
    workerId: request.workerId,
  });

  if (!chat) {
    chat = await Chat.create({
      customerId: request.customerId,
      workerId: request.workerId,
      createdFromRequestId: request._id,
    });
  }

  request.status = "accepted";
  request.acceptedAt = new Date();
  request.chatId = chat._id;

  await request.save();

  return res.status(200).json({ success: true, data: request, error: null });
});

export const rejectServiceRequest = asyncHandler(async (req, res) => {
  if (req.user.currentRole !== "worker") {
    throw new ForbiddenError("Must be Worker", "ROLE_FORBIDDEN");
  }

  const requestId = req.params.id;
  const { rejectReason } = req.body;

  if (!mongoose.Types.ObjectId.isValid(requestId)) {
    throw new BadRequestError("Invalid request id", "INVALID_REQUEST_ID");
  }

  const request = await ServiceRequest.findById(requestId);
  if (!request)
    throw new NotFoundError("Service request not found", "REQUEST_NOT_FOUND");

  if (request.workerId.toString() !== req.user._id.toString()) {
    throw new ForbiddenError(
      "Not authorized to reject this request",
      "FORBIDDEN_REJECT_REQUEST",
    );
  }

  if (request.status !== "pending") {
    throw new BadRequestError(
      `Cannot reject request with status '${request.status}'`,
      "INVALID_REJECT_STATUS",
    );
  }

  request.status = "rejected";
  request.rejectedAt = new Date();
  request.rejectReason = rejectReason ? rejectReason.trim() : null;

  await request.save();

  return res.status(200).json({ success: true, data: request, error: null });
});

export const getServiceRequestsForCustomer = getServiceRequestsByRole(
  "customer",
  "customerId",
);
export const getServiceRequestsForWorker = getServiceRequestsByRole(
  "worker",
  "workerId",
);
