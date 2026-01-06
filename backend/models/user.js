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
    isVerified: {
      type: Boolean,
      default: false,
    },
    verificationCodeHash: {
      type: String,
    },
    verificationCodeExpiry: {
      type: Date,
    },
  },
  { timestamps: true }
);

userSchema.index({ location: "2dsphere" });

const User = mongoose.model("User", userSchema);
export default User;
