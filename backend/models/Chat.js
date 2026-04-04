import mongoose from "mongoose";

const chatSchema = new mongoose.Schema(
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
    createdFromRequestId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ServiceRequest",
      required: true,
    },
  },
  { timestamps: true },
);
chatSchema.index({ customerId: 1, workerId: 1 }, { unique: true });
chatSchema.index({ customerId: 1, updatedAt: -1 });
chatSchema.index({ workerId: 1, updatedAt: -1 });

const Chat = mongoose.model("Chat", chatSchema);
export default Chat;
