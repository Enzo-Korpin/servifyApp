import ServiceRequest from "../models/serviceRequest.js";
import User from "../models/user.js";
import WorkerProfile from "../models/workerProfile.js";
import Chat from "../models/Chat.js";
import mongoose from "mongoose";
import { asyncHandler } from "../middleware/asyncHandler.js";
import { BadRequestError, UnauthorizedError, ForbiddenError, NotFoundError, ConflictError, PayloadTooLargeError } from "../errors/httpErrors.js";

const getServiceRequestsByRole = (requiredRole, fieldName) => 
  asyncHandler(async (req, res) => {

    const userId = req.user._id;

    if (req.user.currentRole !== requiredRole) {
      throw new ForbiddenError(`Must be ${requiredRole}`, "ROLE_FORBIDDEN");
    }

    const { status } = req.query; // optional filter
    const filter = { [fieldName]: userId };
    if (status) filter.status = status;

    const requests = await ServiceRequest.find(filter).sort({
      createdAt: -1,
    });

    return res.status(200).json({ success: true, data: requests, error: null });

  });


  export const createServiceRequest = asyncHandler(async (req, res) => {

    const customerId = req.user._id;
    const { workerId, message, addressText, location } = req.body;

    if (req.user.currentRole !== "customer") {
      throw new ForbiddenError("Must be Customer", "ROLE_FORBIDDEN");
    }

    if (!workerId) {
      throw new BadRequestError("workerId is required", "WORKER_ID_REQUIRED");
    }
    if (!location || location.lng == null || location.lat == null) {
      throw new BadRequestError("location.lng and location.lat are required", "LOCATION_REQUIRED");
    }

    const existingRequest = await ServiceRequest.findOne({
      customerId,
      workerId,
      status: "pending",
    });

    if (existingRequest) {
      throw new ConflictError("You already have a pending request with this worker", "ALREADY_PENDING_REQUEST");
    }

    const newRequest = await ServiceRequest.create({
      customerId,
      workerId,
      message: (message || "").trim(),
      addressText: (addressText || "").trim(),
      location: {
        type: "Point",
        coordinates: [Number(location.lng), Number(location.lat)], // [lng, lat]
      },
      status: "pending",
      chatId: null,
    });

    return res.status(201).json({ success: true, data: newRequest, error: null });

  });

  export const getServiceRequestsForCustomer = getServiceRequestsByRole(
    "customer",
    "customerId"
  );
  export const getServiceRequestsForWorker = getServiceRequestsByRole(
    "worker",
    "workerId"
  );

  export const cancelServiceRequest = asyncHandler(async (req, res) => {

    const userId = req.user._id;
    const { cancelReason } = req.body;

    const { id } = req.params;
    const request = await ServiceRequest.findById(id);

    if (!request) {
      throw new NotFoundError("Service request not found", "SERVICE_REQUEST_NOT_FOUND");
    }

    if (request.customerId.toString() !== userId.toString()) {
      throw new ForbiddenError("Not authorized to cancel this request", "NOT_AUTHORIZED");

    }

    if (request.status !== "pending") {
      throw new BadRequestError("Only pending requests can be cancelled", "INVALID_REQUEST_STATUS");
    }

    request.status = "cancelled";
    request.cancelReason = cancelReason ? cancelReason.trim() : null;
    request.cancelledAt = new Date();

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
      throw new NotFoundError("Service request not found", "SERVICE_REQUEST_NOT_FOUND");

    if (request.workerId.toString() !== req.user._id.toString()) {
      throw new ForbiddenError("Not authorized to accept this request", "NOT_AUTHORIZED");
    }

    if (request.status !== "pending") {
      throw new BadRequestError(`Cannot accept request with status '${request.status}'`, "INVALID_REQUEST_STATUS");
    }

    if (request.expiresAt && request.expiresAt <= new Date()) {
      request.status = "expired";
      await request.save();
      throw new BadRequestError("Request expired", "REQUEST_EXPIRED");
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
      throw new NotFoundError("Service request not found", "SERVICE_REQUEST_NOT_FOUND");

    if (request.workerId.toString() !== req.user._id.toString()) {
      throw new ForbiddenError("Not authorized to reject this request", "NOT_AUTHORIZED");
    }

    if (request.status !== "pending") {
      throw new BadRequestError(`Cannot reject request with status '${request.status}'`, "INVALID_REQUEST_STATUS");
    }

    if (request.expiresAt && request.expiresAt <= new Date()) {
      request.status = "expired";
      await request.save();
      throw new BadRequestError("Request expired", "REQUEST_EXPIRED");
    }

    request.status = "rejected";
    request.rejectedAt = new Date();
    request.rejectReason = rejectReason ? rejectReason.trim() : null;

    await request.save();

    return res.status(200).json({ success: true, data: request, error: null });

  });
