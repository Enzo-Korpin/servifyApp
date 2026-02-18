import mongoose from "mongoose";
import bcrypt from "bcrypt";
import crypto from "crypto";
import User from "../models/user.js";
import WorkerProfile from "../models/workerProfile.js";
import { generateVerificationCode } from "../utils/generateVerficationCode.js";
import { generateTokenAndSetCookie } from "../utils/generateTokenAndSetCookie.js";
import { sendVerificationEmail, sendWelcomeEmail } from "../mailtrap/emails.js";
import { asyncHandler } from "../middleware/asyncHandler.js";
import { BadRequestError, UnauthorizedError, ForbiddenError, NotFoundError, ConflictError, PayloadTooLargeError } from "../errors/httpErrors.js";
import { error } from "console";

const hashCode = (code) =>
  crypto.createHash("sha256").update(String(code)).digest("hex");

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

    if (!fullName || !email || !password || lat == null || lng == null || !role) {
      throw new BadRequestError("Missing required fields");
    }

    if (!["customer", "worker"].includes(role)) {
      throw new BadRequestError("Invalid role");
    }

    const exists = await User.exists({ email });

    if (exists) {
      throw new ConflictError("User already exists");
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const verificationCode = generateVerificationCode();
    const verificationCodeHash = hashCode(verificationCode);
    const verificationCodeExpiry = new Date(Date.now() + 15 * 60 * 1000);

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

    let createdUser;

    await session.withTransaction(async () => {
      const [user] = await User.create(
        [
          {
            fullName,
            email,
            password: hashedPassword,
            location: { type: "Point", coordinates: [lng, lat] },
            image: imageUrl ?? null,
            role,
            currentRole: role,
            isVerified: false,
            verificationCodeHash,
            verificationCodeExpiry,
          },
        ],
        { session }
      );

      createdUser = user;

      if (role === "worker") {
        await WorkerProfile.create(
          [
            {
              _id: createdUser._id,
              bio: bio ?? "",
              yearsOfExperience: yearsOfExperience || 0,
              rate: 0,
              numberOfRatings: 0,
              skills: skills ?? [],
            },
          ],
          { session }
        );
      }
    });

    sendVerificationEmail(createdUser.email, verificationCode).catch(console.error);

    const safeUser = createdUser.toObject();
    safeUser.password = undefined;
    safeUser.verificationCodeHash = undefined;
    safeUser.verificationCodeExpiry = undefined;

    return res.status(201).json({ success: true, data: safeUser, error: null });
  } finally {
    session.endSession();
  }
});

export const loginUser = asyncHandler(async (req, res) => {

  const { email, password } = req.body;

  if (!email || !password) {
    throw new BadRequestError("Missing email or password", "MISSING_CREDENTIALS");
  }

  const user = await User.findOne({ email });
  if (!user) {
    throw new NotFoundError("User not found - Invalid credentials", "INVALID_CREDENTIALS");
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

  const { verificationCode } = req.body;
  if (!verificationCode) {
    throw new BadRequestError("verificationCode is required", "MISSING_VERIFICATION_CODE");
  }
  const codeHash = hashCode(verificationCode);


  const user = await User.findOne({
    verificationCodeHash: codeHash,
    verificationCodeExpiry: { $gt: new Date() },
  });

  if (!user) {
    throw new BadRequestError("Invalid or expired verification code", "INVALID_OR_EXPIRED_CODE");
  }
  user.isVerified = true;
  user.verificationCodeHash = undefined;
  user.verificationCodeExpiry = undefined;

  await user.save();

  await sendWelcomeEmail(user.email, user.fullName);

  return res.status(200).json({ success: true, data: user, error: null });
});

export const checkAuth = (req, res) => {
  try {
    res.status(200).json(req.user);
  } catch (error) {
    console.log("Error in checkAuth controller", error.message);
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
    throw new ForbiddenError("Customers are not allowed to switch to worker", "ROLE_SWITCH_FORBIDDEN");
  }

  if (targetRole === "worker") {
    const hasProfile = await WorkerProfile.exists({ _id: userId });

    if (!hasProfile) {
      throw new ConflictError("Worker profile does not exist", "WORKER_PROFILE_NOT_FOUND");
    }
  }

  if (req.user.currentRole === targetRole) {
    return res.status(200).json({success: true, data: { currentRole: req.user.currentRole, changed: false }, error: null});
  }

  req.user.currentRole = targetRole;
  await req.user.save();

  return res.status(200).json({ success: true, data: { currentRole: req.user.currentRole, changed: true }, error: null });

});
