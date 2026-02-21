import mongoose from "mongoose";
import User from "../models/user.js";
import { asyncHandler } from "../middleware/asyncHandler.js";
import {
  BadRequestError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  PayloadTooLargeError,
} from "../errors/httpErrors.js";

export const getCustomerProfile = asyncHandler(async (req, res) => {});

export const updateCustomerProfile = asyncHandler(async (req, res) => {});

export const getFilteredWorkers = asyncHandler(async (req, res) => {
  const { skill, radiusKm = 5, sort = "distance" } = req.validateQuery;

  const limit = Math.min(parseInt(req.query.limit || "20", 10), 10);
  const after = req.query.after;

  const coords = req.user?.location?.coordinates;
  if (!coords || coords.length !== 2) {
    throw new BadRequestError(
      "Customer location is required",
      "MISSING_LOCATION",
    );
  }

  const [customerLng, customerLat] = coords;
  const radiusMeters = Number(radiusKm) * 1000;

  if (!Number.isFinite(radiusMeters) || radiusMeters <= 0) {
    throw new BadRequestError("Invalid radiusKm", "INVALID_RADIUS");
  }

  const match = { role: "worker" };

  let sortStage;
  let cursorMatch = null;

  if (sort === "distance") {
    sortStage = { distanceMeters: 1, _id: 1 };

    if (after) {
      const [distanceStr, id] = after.split("|");
      const distance = Number(distanceStr);

      if (!mongoose.Types.ObjectId.isValid(id) || isNaN(distance)) {
        throw new BadRequestError("Invalid cursor", "INVALID_CURSOR");
      }

      cursorMatch = {
        $or: [
          { distanceMeters: { $gt: distance } },
          {
            distanceMeters: distance,
            _id: { $gt: new mongoose.Types.ObjectId(id) },
          },
        ],
      };
    }
  } else if (sort === "rating") {
    sortStage = { "workerProfile.rate": -1, distanceMeters: 1, _id: 1 };

    if (after) {
      const [ratingStr, distanceStr, id] = after.split("|");
      const rating = Number(ratingStr);
      const distance = Number(distanceStr);

      if (
        !mongoose.Types.ObjectId.isValid(id) ||
        isNaN(rating) ||
        isNaN(distance)
      ) {
        throw new BadRequestError("Invalid cursor", "INVALID_CURSOR");
      }

      cursorMatch = {
        $or: [
          { "workerProfile.rate": { $lt: rating } },
          {
            "workerProfile.rate": rating,
            distanceMeters: { $gt: distance },
          },
          {
            "workerProfile.rate": rating,
            distanceMeters: distance,
            _id: { $gt: new mongoose.Types.ObjectId(id) },
          },
        ],
      };
    }
  } else if (sort === "ratingCount") {
    sortStage = {
      "workerProfile.numberOfRatings": -1,
      distanceMeters: 1,
      _id: 1,
    };

    if (after) {
      const [countStr, distanceStr, id] = after.split("|");
      const count = Number(countStr);
      const distance = Number(distanceStr);

      if (
        !mongoose.Types.ObjectId.isValid(id) ||
        isNaN(count) ||
        isNaN(distance)
      ) {
        throw new BadRequestError("Invalid cursor", "INVALID_CURSOR");
      }

      cursorMatch = {
        $or: [
          { "workerProfile.numberOfRatings": { $lt: count } },
          {
            "workerProfile.numberOfRatings": count,
            distanceMeters: { $gt: distance },
          },
          {
            "workerProfile.numberOfRatings": count,
            distanceMeters: distance,
            _id: { $gt: new mongoose.Types.ObjectId(id) },
          },
        ],
      };
    }
  } else {
    throw new BadRequestError("Invalid sort value", "INVALID_SORT");
  }

  const pipeline = [
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
    ...(cursorMatch ? [{ $match: cursorMatch }] : []),
    { $sort: sortStage },
    { $limit: limit },
    {
      $project: {
        fullName: 1,
        image: 1,
        workerProfile: 1,
        distanceMeters: 1,
      },
    },
  ];

  const workers = await User.aggregate(pipeline);

  let nextCursor = null;

  if (workers.length > 0) {
    const last = workers[workers.length - 1];

    if (sort === "distance") {
      nextCursor = `${last.distanceMeters}|${last._id}`;
    } else if (sort === "rating") {
      nextCursor = `${last.workerProfile.rate}|${last.distanceMeters}|${last._id}`;
    } else if (sort === "ratingCount") {
      nextCursor = `${last.workerProfile.numberOfRatings}|${last.distanceMeters}|${last._id}`;
    }
  }

  return res.status(200).json({
    success: true,
    data: { workers: workers, nextCursor: nextCursor },
    error: null,
  });
});

export const searchWorkersByName = asyncHandler(async (req, res) => {
  const { search } = req.validateQuery;
  const limit = Math.min(parseInt(req.query.limit || "20", 10), 10);
  const after = req.query.after;

  const escaped = search.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const regex = new RegExp(escaped, "i");

  const query = {
    role: "worker",
    fullName: { $regex: regex },
  };

  if (after) {
    const [afterName, afterId] = String(after).split("|");

    if (!afterName || !mongoose.Types.ObjectId.isValid(afterId)) {
      throw new BadRequestError("Invalid cursor", "INVALID_CURSOR");
    }

    query.$or = [
      { fullName: { $gt: afterName } },
      { fullName: afterName, _id: { $gt: afterId } },
    ];
  }

  const workers = await User.aggregate([
    { $match: query },
    { $sort: { fullName: 1, _id: 1 } },
    { $limit: limit },
    {
      $lookup: {
        from: "workerprofiles",
        localField: "_id",
        foreignField: "_id",
        as: "profile",
      },
    },
    { $unwind: { path: "$profile", preserveNullAndEmptyArrays: true } },
    {
      $project: {
        fullName: 1,
        image: 1,
        rate: "$profile.rate",
      },
    },
  ]);

  const nextCursor =
    workers.length > 0
      ? `${workers[workers.length - 1].fullName}|${workers[workers.length - 1]._id}`
      : null;

  return res.status(200).json({
    success: true,
    data: { workers: workers, nextCursor: nextCursor },
    error: null,
  });
});

export const getLocation = asyncHandler(async (req, res) => {
  const coords = req.user?.location?.coordinates;
  if (!coords || coords.length !== 2) {
    throw new BadRequestError(
      "Customer location is Not set",
      "MISSING_LOCATION",
    );
  }
  res.status(200).json({
    success: true,
    data: { lng: coords[0], lat: coords[1] },
    error: null,
  });
});
