import mongoose from "mongoose";

const aiProposalSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: true,
    },

    proposalType: {
      type: String,
      enum: ["create_request_and_shortlist_workers"],
      required: true,
    },

    status: {
      type: String,
      enum: [
        "pending_confirmation",
        "confirmed",
        "cancelled",
        "expired",
        "executed",
        "failed_execution",
      ],
      default: "pending_confirmation",
    },

    messageToUser: {
      type: String,
      required: true,
    },

    actionData: {
      type: mongoose.Schema.Types.Mixed,
      required: true,
    },

    expiresAt: {
      type: Date,
      required: true,
    },

    confirmedAt: {
      type: Date,
      default: null,
    },

    cancelledAt: {
      type: Date,
      default: null,
    },

    executedAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);


const AiProposal = mongoose.model("AiProposal", aiProposalSchema);
export default AiProposal;