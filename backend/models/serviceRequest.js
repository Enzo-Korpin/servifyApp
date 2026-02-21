import mongoose from "mongoose";

const serviceRequestSchema = new mongoose.Schema(
  {
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    workerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    message: {
      type: String,
      trim: true,
      maxlength: 1000,
      default: "",
    },

    addressText: {
      type: String,
      trim: true,
      default: "",
    },

    location: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
        required: true,
      },
      coordinates: {
        type: [Number],
        required: true,
        validate: {
          validator: (v) => Array.isArray(v) && v.length === 2,
          message: "coordinates must be [lng, lat]",
        },
      },
    },

    status: {
      type: String,
      enum: ["pending", "accepted", "rejected", "cancelled"],
      default: "pending",
    },

    acceptedAt: { type: Date, default: null },
    rejectedAt: { type: Date, default: null },
    cancelledAt: { type: Date, default: null },
    completedAt: { type: Date, default: null },

    chatId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Chat",
      default: null,
    },

    rejectReason: { type: String, trim: true, default: null },
    cancelReason: { type: String, trim: true, default: null },
  },
  { timestamps: true },
);

serviceRequestSchema.index({ location: "2dsphere" });

serviceRequestSchema.index({
  customerId: 1,
  status: 1,
  createdAt: -1,
  _id: -1,
});
serviceRequestSchema.index({ workerId: 1, status: 1, createdAt: -1, _id: -1 });

serviceRequestSchema.index({ status: 1, expiresAt: 1 });
export default mongoose.model("ServiceRequest", serviceRequestSchema);
