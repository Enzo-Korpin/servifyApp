import mongoose from "mongoose";

const aiMessageSchema = new mongoose.Schema(
  {
    conversationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "AiConversation",
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    role: {
      type: String,
      enum: ["user", "assistant"],
      required: true,
    },
    content: {
      type: String,
      required: true,
      trim: true,
    },
    category: {
      type: String,
      enum: [
        "plumbing",
        "electrical",
        "ac_repair",
        "painting",
        "carpentry",
        "appliance_repair",
        "cleaning",
        "general_maintenance",
        "unknown",
      ],
      default: null,
    },
    workerType: {
      type: String,
      enum: [
        "plumber",
        "electrician",
        "ac_technician",
        "painter",
        "carpenter",
        "appliance_repair_technician",
        "cleaner",
        "handyman",
        "unknown",
      ],
      default: null,
    },
    urgency: {
      type: String,
      enum: ["low", "medium", "high"],
      default: null,
    },
    canUserFix: {
      type: String,
      enum: ["yes", "limited", "no"],
      default: null,
    },
    steps: {
      type: [String],
      default: [],
    },
    safetyNotes: {
      type: [String],
      default: [],
    },
    needsMoreInfo: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);
const AiMessage = mongoose.model("AiMessage", aiMessageSchema);
export default AiMessage;