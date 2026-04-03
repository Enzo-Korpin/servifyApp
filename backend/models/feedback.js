import mongoose from "mongoose";

const feedbackSchema = new mongoose.Schema(
  {
    requestId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ServiceRequest",
      required: true,
    },
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
    rate: {
      type: Number,
      required: true,
      min: 0,
      max: 5,
    },
    comment: {
      type: String,
      default: "",
    },
  },
  { timestamps: true },
);

feedbackSchema.index({ requestId: 1 }, { unique: true });

const Feedback = mongoose.model("Feedback", feedbackSchema);
export default Feedback;
