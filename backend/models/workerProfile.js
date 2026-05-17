import mongoose from "mongoose";

const workerProfileSchema = new mongoose.Schema(
  {
    _id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    bio: {
      type: String,
      default: "",
    },
    yearsOfExperience: {
      type: Number,
      required: true,
      default: 0,
    },
    ratingSum: {
      type: Number,
      default: 0,
    },
    ratingCount: {
      type: Number,
      default: 0,
    },
    rate: {
      type: Number,
      default: 0,
    },
    skills: {
      type: [String],
      default: [],
      set: (skills) =>
        Array.isArray(skills)
          ? [...new Set(
            skills
              .map((s) => String(s).toLowerCase().trim())
              .filter(Boolean)
          )]
          : [],
    },
  },
  { timestamps: true },
);

const WorkerProfile = mongoose.model("WorkerProfile", workerProfileSchema);
export default WorkerProfile;
