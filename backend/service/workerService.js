import serviceRequest from "../models/serviceRequest.js";
import WorkerProfile from "../models/workerProfile.js";
import User from "../models/user.js";
import mongoose from "mongoose";
import cloudinary from "../lib/cloudinary.js";
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

export const getWorkerProfile = asyncHandler(async (req, res) => {
  const userId = req.user._id;
  if (req.user.currentRole !== "worker") {
    throw new ForbiddenError("Must be Worker", "MUST_BE_WORKER");
  }
  const workerProfile = await WorkerProfile.findById(userId)
    .select("bio yearsOfExperience skills")
    .populate("_id", "fullName image ");
  if (!workerProfile) {
    throw new NotFoundError("Worker profile not found", "WORKER_PROFILE_NOT_FOUND");
  }
  return res.status(200).json({ success: true, data: workerProfile, error: null });
});

const uploadProfileImageIfNeeded = async (image) => {
  if (!image || typeof image !== "string") return image;

  const trimmedImage = image.trim();

  if (!trimmedImage.startsWith("data:image")) {
    return trimmedImage;
  }

  const MAX_IMAGE_BYTES = 3 * 1024 * 1024;
  const MAX_BASE64_LENGTH = Math.ceil((MAX_IMAGE_BYTES * 4) / 3);

  if (trimmedImage.length > MAX_BASE64_LENGTH) {
    throw new PayloadTooLargeError("Image too large");
  }

  const uploadResponse = await cloudinary.uploader.upload(trimmedImage, {
    folder: "avatar",
    resource_type: "image",
    allowed_formats: ["jpg", "jpeg", "png", "webp"],
  });

  return uploadResponse.secure_url;
};

export const updateWorkerProfile = asyncHandler(async (req, res) => {
  const userId = req.user._id;

  if (req.user.currentRole !== "worker") {
    throw new ForbiddenError("Must be Worker", "MUST_BE_WORKER");
  }

  const { fullName, image, bio, yearsOfExperience, skills } = req.body;

  const safeFullName = typeof fullName === "string" ? fullName.trim() : "";
  const safeImage = await uploadProfileImageIfNeeded(image);
  const safeBio = typeof bio === "string" ? bio.trim() : "";

  if (!safeFullName) {
    throw new BadRequestError("fullName is required", "MISSING_FULL_NAME");
  }

  if (!Array.isArray(skills)) {
    throw new BadRequestError("skills must be an array", "INVALID_SKILLS");
  }

  const cleanedSkills = skills
    .map((skill) => (typeof skill === "string" ? skill.trim().toLowerCase() : ""))
    .filter((skill) => skill.length > 0);

  if (cleanedSkills.length === 0) {
    throw new BadRequestError(
      "Skills must contain at least one valid non-empty skill",
      "INVALID_SKILLS"
    );
  }

  const session = await mongoose.startSession();

  let updatedWorkerProfile;

  try {
    await session.withTransaction(async () => {
      const user = await User.findByIdAndUpdate(
        userId,
        {
          fullName: safeFullName,
          image: safeImage,
        },
        {
          new: true,
          runValidators: true,
          session,
        }
      ).select("fullName image");

      if (!user) {
        throw new NotFoundError("User not found", "USER_NOT_FOUND");
      }

      updatedWorkerProfile = await WorkerProfile.findByIdAndUpdate(
        userId,
        {
          bio: safeBio,
          yearsOfExperience,
          skills: cleanedSkills,
        },
        {
          new: true,
          runValidators: true,
          session,
        }
      )
        .select("bio yearsOfExperience skills")
        .populate("_id", "fullName image");

      if (!updatedWorkerProfile) {
        throw new NotFoundError(
          "Worker profile not found",
          "WORKER_PROFILE_NOT_FOUND"
        );
      }
    });
  } finally {
    await session.endSession();
  }

  return res.status(200).json({
    success: true,
    data: updatedWorkerProfile,
    error: null,
  });
});

export const getAllWorker = asyncHandler(async (req, res) => {
  const workers = await WorkerProfile.find().populate("_id");
  return res.status(200).json({ success: true, data: workers, error: null });
});

export const getWorkerById = asyncHandler(async (req, res) => {
  const workerId = req.params.id;
  if (!mongoose.Types.ObjectId.isValid(workerId)) {
    throw new BadRequestError("Invalid worker ID", "INVALID_WORKER_ID");
  }
  const worker = await WorkerProfile.findById(workerId).populate("_id", "-password");
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
        status: { $in: ["pending", "accepted", "rejected", "cancelled"] },
      },
    },
    {
      $group: {
        _id: "$status",
        count: { $sum: 1 },
      },
    },
  ]);

  const stats = {
    pending: 0,
    accepted: 0,
    rejected: 0,
    cancelled: 0,
  };

  rows.forEach((row) => {
    stats[row._id] = row.count;
  });

  return res.status(200).json({
    success: true,
    data: stats,
    error: null,
  });
});
