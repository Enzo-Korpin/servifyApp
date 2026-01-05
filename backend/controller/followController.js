import mongoose from "mongoose";
import User from "../models/user.js";
import follow from "../models/follow.js";

export const followWorker = async (req, res) => {
  try {
    const { workerId } = req.params;
    const customerId = req.user._id;
    const worker = await User.findById(workerId);

    if (!worker || worker.role !== "worker") {
      return res.status(404).json({ message: "Worker not found" });
    }

    if (String(customerId) === String(workerId)) {
      return res.status(400).json({ message: "Cannot follow yourself" });
    }

    const alreadyFollowing = await follow.findOne({
      customerId: customerId,
      workerId: workerId,
    });
    if (alreadyFollowing) {
      return res.status(400).json({ message: "Already following this worker" });
    }
    const newFollow = new follow({
      customerId: customerId,
      workerId: workerId,
    });
    await newFollow.save();
    res.status(200).json({ message: "Successfully followed the worker" });
  } catch (error) {
    console.log("error message " + error.message);
    res.status(500).json({ message: "Server error" });
  }
};

export const unfollowWorker = async (req, res) => {
  try {
    const { workerId } = req.params;
    const customerId = req.user._id;

    const worker = await User.findById(workerId);

    if (!worker || worker.role !== "worker") {
      return res.status(404).json({ message: "Worker not found" });
    }

    const followRecord = await follow.findOne({
      customerId: customerId,
      workerId: workerId,
    });
    if (!followRecord) {
      return res.status(400).json({ message: "Not following this worker" });
    }

    await follow.deleteOne({ customerId: customerId, workerId: workerId });
    res.status(200).json({ message: "Successfully unfollowed the worker" });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};

export const getFollowingWorker = async (req, res) => {
  try {
    const { workerId } = req.params;
    const customerId = req.user._id;
    const isFollowing = await follow
      .findOne({
        customerId: customerId,
        workerId: workerId,
      })
      .populate("workerId", "fullName email")
      .select("-customerId");

    if (!isFollowing) {
      return res.status(404).json({ message: "Not following this worker" });
    } else {
      return res.status(200).json({ message: isFollowing });
    }
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};

export const getAllFollowingWorkers = async (req, res) => {
  try {
    const customerId = req.user._id;

    const limit = Math.min(parseInt(req.query.limit || "2", 10), 100);
    const before = req.query.before;

    const query = { customerId: customerId };

    if (before) {
      const [beforeDateStr, beforeId] = String(before).split("|");
      const beforeDate = new Date(beforeDateStr);

      if (
        !beforeDateStr ||
        Number.isNaN(beforeDate.getTime()) ||
        !mongoose.Types.ObjectId.isValid(beforeId)
      ) {
        return res.status(400).json({ message: "Invalid cursor" });
      }

      query.$and = [
        {
          $or: [
            { createdAt: { $lt: beforeDate } },
            { createdAt: beforeDate, _id: { $lt: beforeId } },
          ],
        },
      ];
    }

    const docs = await follow
      .find(query)
      .sort({ createdAt: -1, _id: -1 })
      .limit(limit)
      .populate("workerId", "fullName email")
      .select("-customerId");

    const following = docs.reverse();

    const nextCursor =
      following.length > 0
        ? `${following[0].createdAt.toISOString()}|${following[0]._id}`
        : null;

    return res.status(200).json({ following, nextCursor });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};
