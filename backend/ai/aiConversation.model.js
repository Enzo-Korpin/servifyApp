import mongoose from "mongoose";

const aiConversationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    title: {
      type: String,
      default: "New AI Chat",
      trim: true,
    },
    status: {
      type: String,
      enum: ["active", "closed"],
      default: "active",
    },
  },
  { timestamps: true }
);

const AiConversation = mongoose.model("AiConversation", aiConversationSchema);
export default AiConversation;