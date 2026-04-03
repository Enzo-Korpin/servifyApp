import mongoose from "mongoose";

const followSchema = new mongoose.Schema(
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
  },
  { timestamps: true },
);

followSchema.index({ customerId: 1, workerId: 1 }, { unique: true });
followSchema.index({ customerId: 1, createdAt: -1, _id: -1 });

const Follow = mongoose.model("Follow", followSchema);
export default Follow;
