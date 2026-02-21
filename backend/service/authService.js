import mongoose from "mongoose";
import bcrypt from "bcrypt";
import crypto from "crypto";
import User from "../models/user.js";
import PendingUser from "../models/PendingUser.js";
import WorkerProfile from "../models/workerProfile.js";
import { generateVerificationCode } from "../utils/generateVerficationCode.js";
import { generateTokenAndSetCookie } from "../utils/generateTokenAndSetCookie.js";
import { sendVerificationEmail, sendWelcomeEmail } from "../mailtrap/emails.js";
import { asyncHandler } from "../middleware/asyncHandler.js";
import {
  BadRequestError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  PayloadTooLargeError,
} from "../errors/httpErrors.js";
import { error } from "console";

const hashCode = (code) =>
  crypto.createHash("sha256").update(String(code)).digest("hex");

const COOLDOWN_SECONDS = 60;
const CODE_TTL_MINUTES = 15;
const PENDING_TTL_MINUTES = 30;

export const signupUser = asyncHandler(async (req, res) => {
  const session = await mongoose.startSession();

  try {
    const {
      fullName,
      email,
      password,
      lat,
      lng,
      image,
      role,
      bio,
      yearsOfExperience,
      skills,
    } = req.body;

    const exists = await User.exists({ email });
    const pendingExists = await PendingUser.exists({ email });

    if (exists || pendingExists) {
      throw new ConflictError("User already exists");
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const verificationCode = generateVerificationCode();

    const verificationCodeHash = hashCode(verificationCode);

    let imageUrl;
    if (image) {
      const MAX_IMAGE_BYTES = 3 * 1024 * 1024; // 3MB
      const MAX_BASE64_LENGTH = Math.ceil((MAX_IMAGE_BYTES * 4) / 3);

      if (image.length > MAX_BASE64_LENGTH) {
        throw new PayloadTooLargeError("Image too large");
      }

      const uploadResponse = await cloudinary.uploader.upload(image, {
        folder: "avatar",
        resource_type: "image",
        allowed_formats: ["jpg", "jpeg", "png", "webp"],
      });

      imageUrl = uploadResponse.secure_url;
    }

    let createdPendingUser;

    await session.withTransaction(async () => {
      const [pendingUser] = await PendingUser.create(
        [
          {
            fullName,
            email,
            password: hashedPassword,
            location: {
              type: "Point",
              coordinates: [lng, lat],
            },
            image: imageUrl ?? null,
            role,
            currentRole: role,

            bio: role === "worker" ? (bio ?? "") : undefined,
            yearsOfExperience:
              role === "worker" ? yearsOfExperience || 0 : undefined,
            rate: role === "worker" ? 0 : undefined,
            numberOfRatings: role === "worker" ? 0 : undefined,
            skills: role === "worker" ? (skills ?? []) : undefined,

            verificationCodeHash,
            verificationCodeHashExpiry: new Date(
              Date.now() + CODE_TTL_MINUTES * 60 * 1000,
            ),
            expiresAt: new Date(Date.now() + PENDING_TTL_MINUTES * 60 * 1000),
            lastResendAt: new Date(Date.now()),
          },
        ],
        { session },
      );

      createdPendingUser = pendingUser;
    });

    sendVerificationEmail(createdPendingUser.email, verificationCode).catch(
      console.error,
    );

    const safeUser = createdPendingUser.toObject();
    safeUser.password = undefined;
    safeUser.verificationCodeHash = undefined;
    safeUser.verificationCodeHashExpiry = undefined;
    safeUser.expiresAt = undefined;
    safeUser.resendCount = undefined;

    return res.status(202).json({ success: true, data: safeUser, error: null });
  } finally {
    session.endSession();
  }
});

export const loginUser = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  const user = await User.findOne({ email });
  if (!user) {
    throw new NotFoundError("User not found", "INVALID_CREDENTIALS");
  }
  const isPasswordValid = await bcrypt.compare(password, user.password);
  if (!isPasswordValid) {
    throw new UnauthorizedError("Invalid credentials", "INVALID_CREDENTIALS");
  }
  if (!user.isVerified) {
    throw new ForbiddenError("Email not verified", "EMAIL_NOT_VERIFIED");
  }
  generateTokenAndSetCookie(res, user._id);
  const safeUser = user.toObject();
  safeUser.password = undefined;
  return res.status(200).json({ success: true, data: safeUser, error: null });
});

export const verifyEmail = asyncHandler(async (req, res) => {
  const session = await mongoose.startSession();
  try {
    const { verificationCode, email } = req.body;

    const codeHash = hashCode(verificationCode);

    const pendingUser = await PendingUser.findOne({
      email,
      verificationCodeHash: codeHash,
      verificationCodeHashExpiry: { $gt: new Date() },
    });

    if (!pendingUser) {
      throw new BadRequestError(
        "Invalid or expired verification code",
        "INVALID_OR_EXPIRED_CODE",
      );
    }

    let createdUser;

    await session.withTransaction(async () => {
      const [user] = await User.create(
        [
          {
            fullName: pendingUser.fullName,
            email: pendingUser.email,
            password: pendingUser.password,
            location: {
              type: "Point",
              coordinates: [
                pendingUser.location.coordinates[0],
                pendingUser.location.coordinates[1],
              ],
            },
            image: pendingUser.image ?? null,
            role: pendingUser.role,
            currentRole: pendingUser.currentRole,
            isVerified: true,
          },
        ],
        { session },
      );

      createdUser = user;

      if (pendingUser.role === "worker") {
        await WorkerProfile.create(
          [
            {
              _id: createdUser._id,
              bio: pendingUser.bio ?? "",
              yearsOfExperience: pendingUser.yearsOfExperience || 0,
              rate: 0,
              numberOfRatings: 0,
              skills: pendingUser.skills ?? [],
            },
          ],
          { session },
        );
      }
      await PendingUser.deleteOne({ _id: pendingUser._id }).session(session);
    });

    const safeUser = createdUser.toObject();
    safeUser.password = undefined;

    await sendWelcomeEmail(safeUser.email, safeUser.fullName);

    return res.status(200).json({ success: true, data: safeUser, error: null });
  } catch (error) {
    res.status(500).json({ message: "Email verification failed", error });
  } finally {
    session.endSession();
  }
});

export const resendVerificationCode = asyncHandler(async (req, res) => {
  const { email } = req.body;

  const MAX_RESENDS = 2;

  const verificationCode = generateVerificationCode();
  const verificationCodeHash = hashCode(verificationCode);

  const pending = await PendingUser.findOneAndUpdate(
    {
      email,
      expiresAt: { $gt: new Date() },
      resendCount: { $lt: MAX_RESENDS },
      $or: [
        { lastResendAt: null },
        {
          lastResendAt: {
            $lte: new Date(Date.now() - COOLDOWN_SECONDS * 1000),
          },
        },
      ],
    },
    {
      $set: {
        verificationCodeHash,
        verificationCodeHashExpiry: new Date(
          Date.now() + CODE_TTL_MINUTES * 60 * 1000,
        ),
        expiresAt: new Date(Date.now() + PENDING_TTL_MINUTES * 60 * 1000),
        lastResendAt: new Date(),
      },
      $inc: { resendCount: 1 },
    },
    { new: true },
  );

  if (!pending) {
    const exists = await PendingUser.findOne({ email }).select(
      "expiresAt resendCount lastResendAt",
    );

    if (!exists)
      throw new NotFoundError("User not found", "INVALID_CREDENTIALS");

    if ((exists.resendCount ?? 0) >= MAX_RESENDS)
      throw new TooManyRequestsError(
        "Resend limit reached",
        "RESEND_LIMIT_REACHED",
      );

    if (
      exists.lastResendAt &&
      exists.lastResendAt > new Date(Date.now() - COOLDOWN_SECONDS * 1000)
    )
      throw new TooManyRequestsError(
        `Please wait ${COOLDOWN_SECONDS}s before resending`,
        "TOO_MANY_RESEND_REQUESTS",
      );
    throw new BadRequestError(
      "Can not resend verification code",
      "CANNOT_RESEND_CODE",
    );
  }

  sendVerificationEmail(pending.email, verificationCode);
  return res.status(200).json({ success: true, data: null, error: null });
});

export const checkAuth = (req, res) => {
  try {
    const safeUser = req.user.toObject();
    safeUser.password = undefined;
    return res.status(200).json({ success: true, data: safeUser, error: null });
  } catch (error) {
    res.status(500).json({ message: "Internal Server Error" });
  }
};

export const switchRole = asyncHandler(async (req, res) => {
  const userId = req.user._id;
  const { targetRole } = req.body;

  if (!["customer", "worker"].includes(targetRole)) {
    throw new BadRequestError("Invalid target role", "INVALID_TARGET_ROLE");
  }

  if (req.user.role === "customer" && targetRole === "worker") {
    throw new ForbiddenError(
      "Customers are not allowed to switch to worker",
      "ROLE_SWITCH_FORBIDDEN",
    );
  }

  if (targetRole === "worker") {
    const hasProfile = await WorkerProfile.exists({ _id: userId });
    if (!hasProfile) {
      throw new ConflictError(
        "Worker profile does not exist",
        "WORKER_PROFILE_NOT_FOUND",
      );
    }
  }

  if (req.user.currentRole === targetRole) {
    return res.status(200).json({
      success: true,
      data: { currentRole: req.user.currentRole, changed: false },
      error: null,
    });
  }

  req.user.currentRole = targetRole;
  await req.user.save();

  return res
    .status(200)
    .json({
      success: true,
      data: { currentRole: req.user.currentRole, changed: true },
      error: null,
    });
});
