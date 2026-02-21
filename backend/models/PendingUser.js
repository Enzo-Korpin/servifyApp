import mongoose from "mongoose";

const pendingUserSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
    },
    password: {
      type: String,
      required: true,
    },
    role: {
      type: String,
      enum: ["customer", "worker"],
      required: true,
    },
    currentRole: {
      type: String,
      enum: ["customer", "worker"],
      default: function () {
        return this.role;
      },
    },
    location: {
      type: {
        type: String,
        enum: ["Point"],
        required: true,
        default: "Point",
      },
      coordinates: {
        type: [Number], // [lng, lat]
        required: true,
      },
    },

    image: {
      type: String,
    },

    bio: {
      type: String,
      trim: true,
      maxlength: 500,
    },

    yearsOfExperience: {
      type: Number,
      min: 0,
      required: function () {
        return this.role === "worker";
      },
    },

    skills: {
      type: [String],
      required: function () {
        return this.role === "worker";
      },
      set: (skills) =>
        Array.isArray(skills)
          ? skills.map((s) => s.toLowerCase().trim())
          : skills,
      validate: {
        validator: function (v) {
          if (this.role !== "worker") return true;
          return Array.isArray(v) && v.length > 0;
        },
        message: "Worker must have at least one skill",
      },
    },

    verificationCodeHash: {
      type: String,
    },
    verificationCodeHashExpiry: {
      type: Date,
    },
    expiresAt: {
      type: Date,
      required: true,
      index: { expires: 0 },
    },
    resendCount: {
      type: Number,
      default: 0,
    },
    lastResendAt: {
      type: Date,
    },
  },
  { timestamps: true },
);

const PendingUserModel = mongoose.model("PendingUser", pendingUserSchema);
export default PendingUserModel;
