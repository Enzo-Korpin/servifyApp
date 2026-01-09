import ServiceRequest from "../models/serviceRequest.js";
import Chat from "../models/Chat.js";
import mongoose from "mongoose";

const getServiceRequestsByRole = (requiredRole, fieldName) => {
  return async (req, res) => {
    try {
      const userId = req.user._id;

      if (req.user.currentRole !== requiredRole) {
        return res.status(403).json({ message: `Must be ${requiredRole}` });
      }

      const { status } = req.query; // optional filter
      const filter = { [fieldName]: userId };
      if (status) filter.status = status;

      const requests = await ServiceRequest.find(filter).sort({
        createdAt: -1,
      });

      return res.status(200).json({ data: requests });
    } catch (err) {
      return res
        .status(500)
        .json({ message: "Server error", error: err.message });
    }
  };
};

export const createServiceRequest = async (req, res) => {
  try {
    const customerId = req.user._id;
    const { workerId, message, addressText, location } = req.body;

    if (req.user.currentRole !== "customer") {
      return res
        .status(403)
        .json({ message: "Only customers can create service requests" });
    }

    if (!workerId) {
      return res.status(400).json({ message: "workerId are required" });
    }
    if (!location || location.lng == null || location.lat == null) {
      return res
        .status(400)
        .json({ message: "location.lng and location.lat are required" });
    }

    const existingRequest = await ServiceRequest.findOne({
      customerId,
      workerId,
      status: "pending",
    });

    if (existingRequest) {
      return res.status(409).json({
        message: "You already have a pending request with this worker",
        requestId: existingRequest._id,
      });
    }

    const newRequest = await ServiceRequest.create({
      customerId,
      workerId,
      // requestedSkill: skill,
      message: (message || "").trim(),
      addressText: (addressText || "").trim(),
      location: {
        type: "Point",
        coordinates: [Number(location.lng), Number(location.lat)], // [lng, lat]
      },
      status: "pending",
      chatId: null,
    });

    return res.status(201).json({ message: "Request sent", data: newRequest });
  } catch (err) {
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};

export const getServiceRequestsForCustomer = getServiceRequestsByRole(
  "customer",
  "customerId"
);
export const getServiceRequestsForWorker = getServiceRequestsByRole(
  "worker",
  "workerId"
);

export const cancelServiceRequest = async (req, res) => {
  try {
    const userId = req.user._id;
    const { cancelReason } = req.body;

    const { id } = req.params;
    const request = await ServiceRequest.findById(id);

    if (!request) {
      return res.status(404).json({ message: "Service request not found" });
    }
    if (request.customerId.toString() !== userId.toString()) {
      return res
        .status(403)
        .json({ message: "Not authorized to cancel this request" });
    }
    if (request.status !== "pending") {
      return res
        .status(400)
        .json({ message: "Only pending requests can be cancelled" });
    }
    request.status = "cancelled";
    request.cancelReason = cancelReason ? cancelReason.trim() : null;
    request.cancelledAt = new Date();

    await request.save();

    return res
      .status(200)
      .json({ message: "Service request cancelled", data: request });
  } catch (err) {
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};

export const acceptServiceRequest = async (req, res) => {
  try {
    if (req.user.currentRole !== "worker") {
      return res.status(403).json({ message: "Must be Worker" });
    }
    const requestId = req.params.id;
    if (!mongoose.Types.ObjectId.isValid(requestId)) {
      return res.status(400).json({ message: "Invalid request id" });
    }

    const request = await ServiceRequest.findById(requestId);
    if (!request)
      return res.status(404).json({ message: "Service request not found" });

    if (request.workerId.toString() !== req.user._id.toString()) {
      return res
        .status(403)
        .json({ message: "Not authorized to accept this request" });
    }

    if (request.status !== "pending") {
      return res.status(400).json({
        message: `Cannot accept request with status '${request.status}'`,
      });
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

    return res.status(200).json({
      message: "Request accepted",
      data: request,
      chat,
    });
  } catch (err) {
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};

export const rejectServiceRequest = async (req, res) => {
  try {
    if (req.user.currentRole !== "worker") {
      return res.status(403).json({ message: "Must be Worker" });
    }

    const requestId = req.params.id;
    const { rejectReason } = req.body;

    if (!mongoose.Types.ObjectId.isValid(requestId)) {
      return res.status(400).json({ message: "Invalid request id" });
    }

    const request = await ServiceRequest.findById(requestId);
    if (!request)
      return res.status(404).json({ message: "Service request not found" });

    if (request.workerId.toString() !== req.user._id.toString()) {
      return res
        .status(403)
        .json({ message: "Not authorized to reject this request" });
    }

    if (request.status !== "pending") {
      return res.status(400).json({
        message: `Cannot reject request with status '${request.status}'`,
      });
    }

    request.status = "rejected";
    request.rejectedAt = new Date();
    request.rejectReason = rejectReason ? rejectReason.trim() : null;

    await request.save();

    return res.status(200).json({ message: "Request rejected", data: request });
  } catch (err) {
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};

export const completeServiceRequest = async (req, res) => {
  try {
    if (req.user.currentRole !== "worker") {
      return res.status(403).json({ message: "Must be worker" });
    }

    const requestId = req.params.id;

    if (!mongoose.Types.ObjectId.isValid(requestId)) {
      return res.status(400).json({ message: "Invalid request id" });
    }

    const request = await ServiceRequest.findById(requestId);

    if (!request) {
      return res.status(404).json({ message: "Service request not found" });
    }

    if (request.workerId.toString() !== req.user._id.toString()) {
      return res
        .status(403)
        .json({ message: "Not authorized to complete this request" });
    }

    if (request.status !== "accepted") {
      return res.status(400).json({
        message: `Cannot complete request with status "${request.status}"`,
      });
    }

    request.status = "completed";
    request.completedAt = new Date();

    await request.save();

    return res
      .status(200)
      .json({ message: "Service request completed", data: request });
  } catch (err) {
    return res.status(500).json({ message: "Server error", error: err.message });
  }
};
