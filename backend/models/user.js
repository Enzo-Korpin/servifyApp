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
    isVerified: {
      type: Boolean,
      default: false,
    },
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
  },
  { timestamps: true },
);

userSchema.index({ location: "2dsphere" });
userSchema.index({ role: 1, fullName: 1, _id: 1 });

const User = mongoose.model("User", userSchema);
export default User;
