import mongoose from "mongoose";
import User from "../models/user.js";

export const getCustomerProfile = async (req, res) => {};

export const updateCustomerProfile = async (req, res) => {};

export const getFilteredWorkers = async (req, res) => {
  try {
    const { skill, radiusKm = 5, sort = "distance" } = req.validateQuery;

    const coords = req.user?.location?.coordinates;
    if (!coords || coords.length !== 2) {
      return res.status(400).json({ message: "Set your location first." });
    }
    const [customerLng, customerLat] = coords;

    const radiusMeters = Number(radiusKm) * 1000;
    if (!Number.isFinite(radiusMeters) || radiusMeters <= 0) {
      return res.status(400).json({ message: "Invalid radiusKm" });
    }

    const match = { role: "worker" };

    const sortStage =
      sort === "distance"
        ? { distanceMeters: 1 }
        : sort === "rating"
        ? { "workerProfile.ratingAvg": -1, distanceMeters: 1 }
        : sort === "ratingCount"
        ? { "workerProfile.ratingCount": -1, distanceMeters: 1 }
        : null;

    if (!sortStage) {
      return res.status(400).json({
        message: "Invalid sort. Use: distance | rating | ratingCount",
      });
    }

    const workers = await User.aggregate([
      {
        $geoNear: {
          near: { type: "Point", coordinates: [customerLng, customerLat] },
          key: "location",
          spherical: true,
          maxDistance: radiusMeters,
          distanceField: "distanceMeters",
          query: match,
        },
      },
      {
        $lookup: {
          from: "workerprofiles",
          localField: "_id",
          foreignField: "_id",
          as: "workerProfile",
        },
      },
      { $unwind: "$workerProfile" },
      ...(skill
        ? [{ $match: { "workerProfile.skills": { $in: [skill] } } }]
        : []),
      { $sort: sortStage },
      { $limit: 50 },
      {
        $project: {
          fullName: 1,
          image: 1,
          workerProfile: 1,
          distanceMeters: 1,
        },
      },
    ]);

    return res.status(200).json({ workers });
  } catch (err) {
    console.log("getWorkers error:", err.message);
    return res.status(500).json({ message: "Internal server error" });
  }
};

export const searchWorkersByName = async (req, res) => {
  try {
    const { search } = req.validateQuery;
    const escaped = search.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const regex = new RegExp(escaped, "i");

    const workers = await User.find({
      role: "worker",
      fullName: { $regex: regex },
    })
      .select("fullName image")
      .limit(20)
      .lean();

    return res.status(200).json({ workers });
  } catch (error) {
    console.log("searchWorkersByName error:", error.message);
    return res.status(500).json({ message: "Internal server error" });
  }
};
