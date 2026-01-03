
import mongoose from "mongoose";
const feedbackSchema = new mongoose.Schema(
  {
    requestId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ServiceRequest",
        required: true,
        unique: true,
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
        index: true,
    },
    ratingX2: {
      type: Number,
      required: true,
        min: 2,
        max: 10,
    },
    comment: {
      type: String,
        trim: true,
        maxlength: 1000,
        default: "",
    },
  },
  { timestamps: true }
);
const Feedback = mongoose.model("Feedback", feedbackSchema);
export default Feedback;