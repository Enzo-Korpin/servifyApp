import mongoose from "mongoose";
import bcrypt from "bcrypt";
import crypto from "crypto";
import User from "../models/user.js";
import PendingUser from "../models/PendingUser.js";
import WorkerProfile from "../models/workerProfile.js";
import cloudinary from "../lib/cloudinary.js";
import { generateVerificationCode } from "../utils/generateVerficationCode.js";
import {
  clearTokenCookieOptions,
  generateTokenAndSetCookie,
} from "../utils/generateTokenAndSetCookie.js";
import { sendVerificationEmail, sendWelcomeEmail } from "../mailtrap/emails.js";
import { asyncHandler } from "../middleware/asyncHandler.js";
import {
  BadRequestError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  PayloadTooLargeError,
  TooManyRequestsError,
} from "../errors/httpErrors.js";

import { verifyGoogleIdToken } from "../utils/googleAuth.js";
import { validateAndNormalizeLocation } from "../middleware/validateAndNormalizeLocation.js";

const hashCode = (code) =>
  crypto.createHash("sha256").update(String(code)).digest("hex");

const encryptPassword = async (password) => {
  const saltRounds = 10;
  return await bcrypt.hash(password, saltRounds);
};

const buildAuthUserResponse = (user) => ({
  _id: user._id,
  fullName: user.fullName,
  email: user.email,
  role: user.role,
  currentRole: user.currentRole,
  image: user.image,
  authProvider: user.authProvider,
  onboardingStatus: user.onboardingStatus,
  isVerified: user.isVerified,
  location: user.location
    ? {
        type: user.location.type,
        coordinates: user.location.coordinates,
      }
    : null,
});

const allowedRoles = new Set(["customer", "worker"]);

const COOLDOWN_SECONDS = 60;
const CODE_TTL_MINUTES = 15;
const PENDING_TTL_MINUTES = 30;

const RESET_CODE_TTL_MINUTES = 10;
const RESET_CODE_COOLDOWN_SECONDS = 60;
// const MAX_RESET_RESENDS = 3;

export const signupUser = asyncHandler(async (req, res) => {
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

  const hashedPassword = await encryptPassword(password);
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

  const [pendingUser] = await PendingUser.create([
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
      yearsOfExperience: role === "worker" ? yearsOfExperience || 0 : undefined,
      rate: role === "worker" ? 0 : undefined,
      ratingCount: role === "worker" ? 0 : undefined,
      skills: role === "worker" ? (skills ?? []) : undefined,

      verificationCodeHash,
      verificationCodeHashExpiry: new Date(
        Date.now() + CODE_TTL_MINUTES * 60 * 1000,
      ),
      expiresAt: new Date(Date.now() + PENDING_TTL_MINUTES * 60 * 1000),
      lastResendAt: new Date(Date.now()),
    },
  ]);

  createdPendingUser = pendingUser;

  await sendVerificationEmail(pendingUser.email, verificationCode);

  const safeUser = createdPendingUser.toObject();

  return res.status(201).json({
    success: true,
    data: buildAuthUserResponse(safeUser),
    error: null,
  });
});

export const loginUser = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  const user = await User.findOne({ email }).select("+password");

  if (!user) {
    throw new NotFoundError("User not found", "INVALID_CREDENTIALS");
  }

  if (user.authProvider !== "local") {
    throw new UnauthorizedError(
      "This account uses Google Sign-In",
      "GOOGLE_ONLY_ACCOUNT",
    );
  }

  const isPasswordValid = await bcrypt.compare(password, user.password);
  if (!isPasswordValid) {
    throw new UnauthorizedError("Invalid credentials", "INVALID_CREDENTIALS");
  }

  if (!user.isVerified) {
    throw new ForbiddenError("Email not verified", "EMAIL_NOT_VERIFIED");
  }

  console.log("DEBUG loginUser: Generating token for user:", user._id, user.email);
  const token = generateTokenAndSetCookie(res, user._id);
  console.log("DEBUG loginUser: Set-Cookie token:", token.substring(0, 50) + "...");

  const safeUser = user.toObject();
  return res.status(200).json({
    success: true,
    data: buildAuthUserResponse(safeUser),
    error: null,
  });
});

export const logoutUser = asyncHandler(async (req, res) => {
  res.clearCookie("token", clearTokenCookieOptions);

  return res.status(200).json({ success: true, data: null, error: null });
});

export const verifyEmail = asyncHandler(async (req, res) => {
  const session = await mongoose.startSession();
  try {
    const { verificationCode } = req.body;

    const codeHash = hashCode(verificationCode);

    const pendingUser = await PendingUser.findOne({
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
              ratingCount: 0,
              skills: pendingUser.skills ?? [],
            },
          ],
          { session },
        );
      }
      await PendingUser.deleteOne({ _id: pendingUser._id }).session(session);
    });

    const safeUser = createdUser.toObject();

    sendWelcomeEmail(safeUser.email, safeUser.fullName).catch((err) => {
      console.error("Failed to send welcome email:", err);
    });

    return res.status(200).json({
      success: true,
      data: buildAuthUserResponse(safeUser),
      error: null,
    });
  } finally {
    session.endSession();
  }
});

export const forgotPassword = asyncHandler(async (req, res) => {
  const { email } = req.body;

  const user = await User.findOne({ email });

  if (!user || user.authProvider !== "local") {
    return res.status(200).json({
      success: true,
      data: { email },
      error: null,
    });
  }

  if (
    user.resetPasswordLastSentAt &&
    user.resetPasswordLastSentAt >
      new Date(Date.now() - RESET_CODE_COOLDOWN_SECONDS * 1000)
  ) {
    throw new TooManyRequestsError(
      `Please wait ${RESET_CODE_COOLDOWN_SECONDS}s before requesting another code`,
      "RESET_CODE_COOLDOWN",
    );
  }

  // const activeResetWindow =
  //   user.resetPasswordCodeExpiry && user.resetPasswordCodeExpiry > new Date();

  // const currentResendCount = activeResetWindow
  //   ? (user.resetPasswordResendCount ?? 0)
  //   : 0;

  // if (currentResendCount >= MAX_RESET_RESENDS) {
  //   throw new TooManyRequestsError(
  //     "Resend limit reached",
  //     "RESET_RESEND_LIMIT_REACHED",
  //   );
  // }

  const resetCode = generateVerificationCode();
  const resetCodeHash = hashCode(resetCode);

  user.resetPasswordCodeHash = resetCodeHash;
  user.resetPasswordCodeExpiry = new Date(
    Date.now() + RESET_CODE_TTL_MINUTES * 60 * 1000,
  );
  // user.resetPasswordResendCount = currentResendCount + 1;
  user.resetPasswordLastSentAt = new Date();

  await user.save();

  await sendVerificationEmail(user.email, resetCode);

  return res.status(200).json({
    success: true,
    data: {
      email: user.email,
    },
    error: null,
  });
});

export const verifyResetCode = asyncHandler(async (req, res) => {
  const { email, code } = req.body;

  if (!email || !code) {
    throw new BadRequestError(
      "Email and verification code are required",
      "EMAIL_AND_CODE_REQUIRED",
    );
  }

  const codeHash = hashCode(code);

  const user = await User.findOne({
    email,
    resetPasswordCodeHash: codeHash,
    resetPasswordCodeExpiry: { $gt: new Date() },
  });

  if (!user) {
    throw new BadRequestError(
      "Invalid or expired verification code",
      "INVALID_OR_EXPIRED_CODE",
    );
  }

  return res.status(200).json({
    success: true,
    data: null,
    error: null,
  });
});

export const resetPassword = asyncHandler(async (req, res) => {
  const { email, code, newPassword, confirmPassword } = req.body;

  if (newPassword !== confirmPassword) {
    throw new BadRequestError(
      "Passwords do not match",
      "PASSWORDS_DO_NOT_MATCH",
    );
  }

  const codeHash = hashCode(code);
  const user = await User.findOne({
    email,
    resetPasswordCodeHash: codeHash,
    resetPasswordCodeExpiry: { $gt: new Date() },
  }).select("+password");

  if (!user) {
    throw new BadRequestError(
      "Invalid or expired verification code",
      "INVALID_OR_EXPIRED_CODE",
    );
  }

  user.password = await encryptPassword(newPassword);

  user.resetPasswordCodeHash = undefined;
  user.resetPasswordCodeExpiry = undefined;
  // user.resetPasswordResendCount = undefined;
  user.resetPasswordLastSentAt = undefined;

  await user.save();

  return res.status(200).json({
    success: true,
    data: null,
    error: null,
  });
});

export const resendVerificationCode = asyncHandler(async (req, res) => {
  const { email } = req.body;

  const MAX_RESENDS = 3;

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

    console.log(exists.resendCount);

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

  await sendVerificationEmail(pending.email, resetCode);
  return res.status(200).json({ success: true, data: null, error: null });
});

export const checkAuth = asyncHandler(async (req, res) => {
  const safeUser = req.user.toObject();

  return res.status(200).json({
    success: true,
    data: buildAuthUserResponse(safeUser),
    error: null,
  });
});

export const googleSignIn = asyncHandler(async (req, res) => {
  const { idToken, requestedRole = "customer", location } = req.body;

  if (!allowedRoles.has(requestedRole)) {
    throw new BadRequestError("Invalid role", "INVALID_ROLE");
  }


  const googleUser = await verifyGoogleIdToken(idToken);

  let user = await User.findOne({ googleSub: googleUser.googleSub });

  if (user) {
    generateTokenAndSetCookie(res, user._id);

    return res.status(200).json({
      success: true,
      data: {
        user: buildAuthUserResponse(user),
        onboardingRequired: user.onboardingStatus !== "complete",
        nextAction:
          user.onboardingStatus === "worker_profile_required"
            ? "COMPLETE_WORKER_PROFILE"
            : "GO_TO_HOME",
      },
      error: null,
    });
  }
  
  const normalizedLocation = validateAndNormalizeLocation(location);


  const session = await mongoose.startSession();

  try {
    await session.withTransaction(async () => {
      const existingGoogleUser = await User.findOne({
        googleSub: googleUser.googleSub,
      }).session(session);

      if (existingGoogleUser) {
        user = existingGoogleUser;
        return;
      }

      const existingEmailUser = await User.findOne({
        email: googleUser.email,
      }).session(session);

      if (existingEmailUser) {
        throw new ConflictError(
          "An account with this email already exists. Sign in using your existing method first, then link Google securely from settings.",
          "ACCOUNT_LINK_REQUIRED",
        );
      }

      const createdUsers = await User.create(
        [
          {
            fullName: googleUser.fullName,
            email: googleUser.email,
            role: requestedRole,
            currentRole: requestedRole,
            authProvider: "google",
            googleSub: googleUser.googleSub,
            image: googleUser.image,
            isVerified: true,
            onboardingStatus:
              requestedRole === "worker"
                ? "worker_profile_required"
                : "complete",
            location: normalizedLocation,
          },
        ],
        { session },
      );

      user = createdUsers[0];

      if (requestedRole === "worker") {
        await WorkerProfile.create(
          [
            {
              _id: user._id,
              bio: "",
              yearsOfExperience: 0,
              skills: ["pending"],
            },
          ],
          { session },
        );
      }
    });
  } finally {
    await session.endSession();
  }

  generateTokenAndSetCookie(res, user._id);

  return res.status(201).json({
    success: true,
    data: {
      user: buildAuthUserResponse(user),
      onboardingRequired: user.onboardingStatus !== "complete",
      nextAction:
        user.onboardingStatus === "worker_profile_required"
          ? "COMPLETE_WORKER_PROFILE"
          : "GO_TO_HOME",
    },
    error: null,
  });
});

export const completeGoogleWorkerProfile = asyncHandler(async (req, res) => {
  const { bio, yearsOfExperience, skills } = req.body;

  if (req.user.authProvider !== "google") {
    throw new ForbiddenError(
      "This endpoint is only for Google-authenticated users",
      "GOOGLE_ONLY_ENDPOINT",
    );
  }

  if (req.user.role !== "worker") {
    throw new ForbiddenError(
      "Only workers can complete worker onboarding",
      "WORKER_ONLY",
    );
  }

  if (req.user.onboardingStatus !== "worker_profile_required") {
    throw new BadRequestError(
      "Worker onboarding is already complete",
      "ONBOARDING_ALREADY_COMPLETE",
    );
  }

  if (!bio?.trim()) {
    throw new BadRequestError("Bio is required", "BIO_REQUIRED");
  }

  if (!Number.isInteger(yearsOfExperience) || yearsOfExperience < 0) {
    throw new BadRequestError(
      "Years of experience must be a non-negative integer",
      "INVALID_YEARS_OF_EXPERIENCE",
    );
  }

  if (!Array.isArray(skills) || skills.length === 0) {
    throw new BadRequestError(
      "At least one skill is required",
      "SKILLS_REQUIRED",
    );
  }

  const normalizedSkills = [
    ...new Set(
      skills.map((skill) => String(skill).trim().toLowerCase()).filter(Boolean),
    ),
  ];

  if (!normalizedSkills.length) {
    throw new BadRequestError(
      "At least one valid skill is required",
      "VALID_SKILLS_REQUIRED",
    );
  }

  const session = await mongoose.startSession();

  try {
    await session.withTransaction(async () => {
      const alreadyExists = await WorkerProfile.exists({
        _id: req.user._id,
      }).session(session);

      if (alreadyExists) {
        await WorkerProfile.updateOne(
        { _id: req.user._id },
        {
          $set: {
            _id: req.user._id,
            bio: bio.trim(),
            yearsOfExperience,
            skills: normalizedSkills,
          },
        },
        { session },
      );
      } else {
        await WorkerProfile.create(
          [
            {
              _id: req.user._id,
              bio: bio.trim(),
              yearsOfExperience,
              skills: normalizedSkills,
            },
          ],
          { session },
        );
      }

      await User.updateOne(
        {
          _id: req.user._id,
          onboardingStatus: "worker_profile_required",
        },
        {
          $set: {
            onboardingStatus: "complete",
          },
        },
        { session },
      );
    });
  } finally {
    session.endSession();
  }

  const updatedUser = await User.findById(req.user._id);

  return res.status(201).json({
    success: true,
    data: {
      user: buildAuthUserResponse(updatedUser),
      onboardingRequired: false,
      nextAction: "GO_TO_WORKER_HOME",
    },
    error: null,
  });
});
