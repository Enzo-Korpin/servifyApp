import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
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
      required: function () {
        return this.authProvider === "local";
      },
      select: false,
    },

    role: {
      type: String,
      enum: ["customer", "worker", "admin"],
      required: true,
    },

    currentRole: {
      type: String,
      enum: ["customer", "worker", "admin"],
      default: function () {
        return this.role;
      },
    },

    // Admin can block any user; blocked users cannot log in (enforced in loginUser/protectRoute layers as needed).
    isBlocked: {
      type: Boolean,
      default: false,
    },

    blockedAt: {
      type: Date,
      default: null,
    },

    blockedReason: {
      type: String,
      default: null,
    },

    location: {
      type: {
        type: String,
        enum: ["Point"],
        // Admins don't need a geo location; only required for customer/worker.
        required: function () {
          return this.role !== "admin";
        },
        default: "Point",
      },
      coordinates: {
        type: [Number], // [lng, lat]
        required: function () {
          return this.role !== "admin";
        },
      },
    },

    image: {
      type: String,
    },

    isVerified: {
      type: Boolean,
      default: false,
    },

    // Store Firebase Cloud Messaging tokens for push notifications
    // Array because one user can login from more than one device
    fcmTokens: [
      {
        type: String,
      },
    ],

    resetPasswordCodeHash: {
      type: String,
      default: null,
    },

    resetPasswordCodeExpiry: {
      type: Date,
      default: null,
    },

    // resetPasswordResendCount: {
    //   type: Number,
    //   default: 0,
    // },

    resetPasswordLastSentAt: {
      type: Date,
      default: null,
    },

    authProvider: {
      type: String,
      enum: ["local", "google"],
      default: "local",
      index: true,
    },

    googleSub: {
      type: String,
      unique: true,
      sparse: true,
      index: true,
    },

    onboardingStatus: {
      type: String,
      enum: ["complete", "worker_profile_required"],
      default: "complete",
    },
  },
  { timestamps: true }
);

userSchema.index({ location: "2dsphere" });
userSchema.index({ role: 1, fullName: 1, _id: 1 });

// Admin dashboard indexes — server-side pagination/filter/sort speed.
userSchema.index({ createdAt: -1 });
userSchema.index({ role: 1, createdAt: -1 });
userSchema.index({ isVerified: 1, createdAt: -1 });
userSchema.index({ isBlocked: 1 });
userSchema.index({ fullName: "text", email: "text" });

const User = mongoose.model("User", userSchema);

export default User;