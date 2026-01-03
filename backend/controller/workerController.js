import serviceRequest from "../models/serviceRequest.js";
import WorkerProfile from "../models/workerProfile.js";
import mongoose from "mongoose";

export const switchRole = async (req, res) => {
  try {
    const userId = req.user._id;
    const { targetRole } = req.body;

    if (!["customer", "worker"].includes(targetRole)) {
      return res.status(400).json({ message: "Invalid target role" });
    }

    if (req.user.role === "customer" && targetRole === "worker") {
      return res.status(403).json({
        message: "Customers are not allowed to switch to worker",
      });
    }

    if (targetRole === "worker") {
      const hasProfile = await WorkerProfile.exists({ _id: userId });
      if (!hasProfile) {
        return res
          .status(409)
          .json({ message: "Worker profile does not exist" });
      }
    }

    if (req.user.currentRole === targetRole) {
      return res.status(200).json({
        message: "Already in this role",
        currentRole: req.user.currentRole,
      });
    }

    req.user.currentRole = targetRole;
    await req.user.save();

    return res.status(200).json({
      message: "Role switched successfully",
      currentRole: req.user.currentRole,
    });
  } catch (error) {
    console.error("switchRole error:", error);
    return res.status(500).json({ message: "Failed to switch role" });
  }
};

export const getWorkerStatus = async (req, res) => {
  try {
    const workerId = req.user._id;
    if (req.user.currentRole !== "worker") {
      return res.status(403).json({ message: "Must be Worker" });
    }
    const rows = await serviceRequest.aggregate([
      {
        $match: {
          workerId: new mongoose.Types.ObjectId(workerId),
          status: { $in: ["pending", "accepted", "completed"] },
        },
      },
      {
        $group: {
          _id: "$status",
          count: { $sum: 1 },
        },
      },
    ]);
    const stats = { pending: 0, accepted: 0, completed: 0 };
    rows.forEach((row) => {
      stats[row._id] = row.count;
    });
    return res.status(200).json({ stats });
    } catch (error) {
    console.error("getWorkerStatus error:", error);
    return res.status(500).json({ message: "Failed to get worker status" });
  }
};