import mongoose from "mongoose";
import bcrypt from "bcrypt";
import crypto from "crypto";
import User from "../models/user.js";
import WorkerProfile from "../models/workerProfile.js";
import { generateVerificationCode } from "../utils/generateVerficationCode.js";
import { generateTokenAndSetCookie } from "../utils/generateTokenAndSetCookie.js";
import { sendVereficationEmail, sendWelcomeEmail } from "../mailtrap/emails.js";

const hashCode = (code) =>
  crypto.createHash("sha256").update(String(code)).digest("hex");

export const signupUser = async (req, res) => {
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

    if (exists) {
      return res.status(409).json({ message: "User already exists" });
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
        return res.status(413).json({ message: "Image too large" });
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
            lat,
            lng,
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

    // generateTokenAndSetCookie(res, createdUser._id);
    // sendVereficationEmail(createdUser.email, verificationCode).catch(
    //   console.error
    // );

    const safeUser = createdUser.toObject();
    safeUser.password = undefined;
    safeUser.verificationCodeHash = undefined;
    safeUser.verificationCodeExpiry = undefined;

    return res.status(201).json({
      message: "User created successfully",
      user: safeUser,
    });
  } catch (error) {
    console.error("Error in registerUser:", error);
    return res.status(500).json({ message: "Failed to create user", error });
  } finally {
    session.endSession();
  }
};

export const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: "Invalid credentials" });
    }
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: "Invalid credentials" });
    }
    if (!user.isVerified) {
      return res
        .status(403)
        .json({ message: "Login failed Email not verified" });
    }
    generateTokenAndSetCookie(res, user._id);
    res.status(200).json({
      message: "Login successful",
      user: {
        ...user._doc,
        password: undefined,
      },
    });
  } catch (error) {
    res.status(500).json({ message: "Login failed", error });
  }
};

export const verifyEmail = async (req, res) => {
  try {
    const { verificationCode, email } = req.body;

    const codeHash = hashCode(verificationCode);
    console.log(codeHash);

    const user = await User.findOne({
      email,
      verificationCodeHash: codeHash,
      verificationCodeExpiry: { $gt: new Date() },
    });

    if (!user) {
      return res
        .status(400)
        .json({ message: "Invalid or expired verification code" });
    }
    user.isVerified = true;
    user.verificationCodeHash = undefined;
    user.verificationCodeExpiry = undefined;

    await user.save();

    await sendWelcomeEmail(user.email, user.fullName);

    res.status(200).json({
      message: "Email verified successfully",
      user: {
        ...user._doc,
        password: undefined,
      },
    });
  } catch (error) {
    res.status(500).json({ message: "Email verification failed", error });
  }
};

export const checkAuth = (req, res) => {
  try {
    res.status(200).json(req.user);
  } catch (error) {
    console.log("Error in checkAuth controller", error.message);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

export const switchRole = async (req, res) => {
  try {
    const userId = req.user._id;
    const { targetRole } = req.body;

    if (!["customer", "worker"].includes(targetRole)) {
      return res.status(400).json({ message: "Invalid target role" });
    }

    if (req.user.role === "customer" && targetRole === "worker") {
      return res.status(403).json({
        message: "Customers are not allowed to switch to worker",
      });
    }

    if (targetRole === "worker") {
      const hasProfile = await WorkerProfile.exists({ _id: userId });
      if (!hasProfile) {
        return res
          .status(409)
          .json({ message: "Worker profile does not exist" });
      }
    }

    if (req.user.currentRole === targetRole) {
      return res.status(200).json({
        message: "Already in this role",
        currentRole: req.user.currentRole,
      });
    }

    req.user.currentRole = targetRole;
    await req.user.save();

    return res.status(200).json({
      message: "Role switched successfully",
      currentRole: req.user.currentRole,
    });
  } catch (error) {
    console.error("switchRole error:", error);
    return res.status(500).json({ message: "Failed to switch role" });
  }
};
