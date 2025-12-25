const mongoose = require("mongoose");
const bcrypt = require("bcrypt");
const crypto = require("crypto");
const User = require("../models/user");
const WorkerProfile = require("../models/workerProfile");
const { generateVerificationCode } = require("../utils/generateVerficationCode");
const { generateTokenAndSetCookie } = require("../utils/generateTokenAndSetCookie");
const { sendVereficationEmail, sendWelcomeEmail } = require("../mailtrap/emails");

const normalizeEmail = (email) => String(email || "").trim().toLowerCase();
const hashCode = (code) => crypto.createHash("sha256").update(String(code)).digest("hex");
const registerUser = async (req, res) => {
    const session = await mongoose.startSession();

    try {
        const { fullName, email, password, lat, lng, image, role } = req.body;

        const selectedRole = String(role || "customer").toLowerCase();
        if (!["customer", "worker"].includes(selectedRole)) {
            return res.status(400).json({ message: "Invalid role specified" });
        }

        if (!fullName || !email || !password) {
            return res.status(400).json({ message: "Full name, email, and password are required" });
        }

        const emailValidate = normalizeEmail(email);
        const exists = await User.exists({ email: emailValidate });

        if (exists) {
            return res.status(409).json({ message: "Email already in use" });
        }


        const hashedPassword = await bcrypt.hash(password, 10);
        const verificationCode = generateVerificationCode();
        const verificationCodeHash = hashCode(verificationCode);
        const verificationCodeExpiry = new Date(Date.now() + 15 * 60 * 1000) // 15 minutes from now

        let createdUser;

        await session.withTransaction(async () => {
            const [u] = await User.create(
                [
                    {
                        fullName,
                        email: emailValidate,
                        password: hashedPassword,
                        lat,
                        lng,
                        image,
                        role: selectedRole,
                        currentRole: selectedRole,
                        isVerified: false,
                        verificationCodeHash,
                        verificationCodeExpiry,
                    },
                ],
                { session }
            );

            createdUser = u;

            if (selectedRole === "worker") {
                await WorkerProfile.create(
                    [
                        {
                            _id: createdUser._id,
                            bio: "",
                            yearsOfExperience: 0,
                            rate: 0,
                            skills: [],
                        },
                    ],
                    { session }
                );
            }
        });


        generateTokenAndSetCookie(res, createdUser._id);
        sendVereficationEmail(createdUser.email, verificationCode).catch(console.error);

        const safeUser = createdUser.toObject();
        delete safeUser.password;
        delete safeUser.verificationCodeHash;
        delete safeUser.verificationCodeExpiry;

        return res.status(201).json({
            message: "User created successfully",
            user: safeUser,
        });
    } catch (error) {

        if (error?.code === 11000) {
            return res.status(409).json({ message: "Email already in use" });
        }
        console.error("Error in registerUser:", error);
        return res.status(500).json({ message: "Failed to create user", error });
    } finally {
        session.endSession();
    }
};

const loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;
        const emailValidate = normalizeEmail(email);
        if (!email || !password) {
            return res.status(400).json({ message: "Email and password are required" });
        }
        const user = await User.findOne({ email: emailValidate });
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }
        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({ message: "Invalid password" });
        }
        if (!user.isVerified) {
            return res.status(403).json({ message: "Login failed Email not verified" });
        }
        generateTokenAndSetCookie(res, user._id);
        res.status(200).json({ message: "Login successful", user });
    } catch (error) {
        res.status(500).json({ message: "Login failed", error });
    }
};

const verifyEmail = async (req, res) => {

    try {
        const { verificationCode, email } = req.body;
        if (!verificationCode || !email) {
            return res.status(400).json({ message: "Email and verificationCode are required" });
        }
        const emailValidate = normalizeEmail(email);
        const codeHash = hashCode(verificationCode);

        const user = await User.findOne({
            email: emailValidate,
            verificationCodeHash: codeHash,
            verificationCodeExpiry: { $gt: new Date() },
        });

        if (!user) {
            return res.status(400).json({ message: "Invalid or expired verification code" });
        }
        user.isVerified = true;
        user.verificationCodeHash = undefined;
        user.verificationCodeExpiry = undefined;

        await user.save();

        await sendWelcomeEmail(user.email, user.fullName);

        res.status(200).json({ message: "Email verified successfully" });
    } catch (error) {
        res.status(500).json({ message: "Email verification failed", error });
    }
};

const checkAuth = async (req, res) => {
    try {
        const user = await User.findById(req.userId).select("-password");
        if (!user) {
            return res.status(401).json({ message: "Unauthorized" });
        }
        res.status(200).json({ message: "Authorized", user });
    } catch (error) {
        res.status(500).json({ message: "Authorization check failed", error });
    }
};

const switchRole = async (req, res) => {
  try {
    const userId = req.userId; 
    const { targetRole } = req.body;

    if (!["customer", "worker"].includes(targetRole)) {
      return res.status(400).json({ message: "Invalid target role" });
    }

    const user = await User.findById(userId).select("role currentRole");
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    
    if (user.role === "customer" && targetRole === "worker") {
      return res.status(403).json({
        message: "Customers are not allowed to switch to worker",
      });
    }

    if (targetRole === "worker") {
      const hasProfile = await WorkerProfile.exists({ _id: userId });
      if (!hasProfile) {
        return res.status(409).json({ message: "Worker profile does not exist"});
      }
    }

    if (user.currentRole === targetRole) {
      return res.status(200).json({message: "Already in this role", currentRole: user.currentRole});
    }

    user.currentRole = targetRole;
    await user.save();

    return res.status(200).json({
      message: "Role switched successfully", currentRole: user.currentRole});
  } catch (error) {
    console.error("switchRole error:", error);
    return res.status(500).json({ message: "Failed to switch role" });
  }
};


module.exports = {
    registerUser,
    loginUser,
    verifyEmail,
    checkAuth,
    switchRole
};
