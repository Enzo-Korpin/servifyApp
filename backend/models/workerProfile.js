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
      require: true,
      default: 0,
    },
    rate: {
      type: Number,
      default: 0,
    },
    numberOfRatings: {
      type: Number,
      default: 0,
    },
    skills: {
      type: [String],
      required: true,
      set: (skills) => skills.map(s => s.toLowerCase().trim()),
      validate: {
        validator: (v) => Array.isArray(v) && v.length > 0,
        message: "Worker must have at least one skill"
      }
    },
  },
  { timestamps: true }
);

const WorkerProfile = mongoose.model("WorkerProfile", workerProfileSchema);
export default WorkerProfile;
