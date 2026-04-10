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

export const getCustomerProfile = asyncHandler(async (req, res) => { 
  const userId = req.user._id;
  if (req.user.currentRole !== "customer") {
    throw new ForbiddenError("Must be Customer", "ROLE_FORBIDDEN");
  }
  const customerProfile = await User.findById(userId).select("fullName email image");
  return res.status(200).json({ success: true, data: customerProfile, error: null });
});

export const updateCustomerProfile = asyncHandler(async (req, res) => {
  const userId = req.user._id;
  const {fullName, image} = req.body;
  if (req.user.currentRole !== "customer") {
    throw new ForbiddenError("Must be Customer", "ROLE_FORBIDDEN");
  }
  if (!fullName) {
    throw new BadRequestError("Full name is required", "MISSING_FULL_NAME");
  }
  const updatedCustomer = await User.findByIdAndUpdate(
    userId,
    { fullName, image },
    { new: true, runValidators: true },
  ).select("fullName image");
  return res.status(200).json({ success: true, data: updatedCustomer, error: null });
});


export const getFilteredWorkers = asyncHandler(async (req, res) => {
  const { skill, radiusKm = 5, sort = "distance", lat, lng } = req.validateQuery;

  const limit = Math.min(parseInt(req.query.limit || "10", 10), 10);
  const after = req.query.after;

  let customerLat;
  let customerLng;

  const hasTempLat = lat !== undefined && lat !== null;
  const hasTempLng = lng !== undefined && lng !== null;

  if (hasTempLat || hasTempLng) {
    if (!hasTempLat || !hasTempLng) {
      throw new BadRequestError(
        "Both lat and lng are required together",
        "INVALID_TEMP_LOCATION",
      );
    }

    customerLat = Number(lat);
    customerLng = Number(lng);

    if (
      !Number.isFinite(customerLat) ||
      !Number.isFinite(customerLng) ||
      customerLat < -90 ||
      customerLat > 90 ||
      customerLng < -180 ||
      customerLng > 180
    ) {
      throw new BadRequestError(
        "Invalid temporary location coordinates",
        "INVALID_TEMP_LOCATION",
      );
    }
  } else {
    const coords = req.user?.location?.coordinates;

    if (!coords || coords.length !== 2) {
      throw new BadRequestError(
        "Customer location is required",
        "MISSING_LOCATION",
      );
    }

    customerLng = coords[0];
    customerLat = coords[1];
  }

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
      "workerProfile.ratingCount": -1,
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
          { "workerProfile.ratingCount": { $lt: count } },
          {
            "workerProfile.ratingCount": count,
            distanceMeters: { $gt: distance },
          },
          {
            "workerProfile.ratingCount": count,
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
        location: 1,
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
      nextCursor = `${last.workerProfile.ratingCount}|${last.distanceMeters}|${last._id}`;
    }
  }

  return res.status(200).json({
    success: true,
    data: {
      workers,
      nextCursor,
      sourceLocation: {
        lat: customerLat,
        lng: customerLng,
        temporary: hasTempLat && hasTempLng,
      },
    },
    error: null,
  });
});


export const searchWorkersByName = asyncHandler(async (req, res) => {
  const { search, after, limit: rawLimit = 10 } = req.validateQuery;

  const limit = Math.min(Number(rawLimit), 10);

  const escaped = search.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const regex = new RegExp(`^${escaped}`, "i");

  const match = {
    role: "worker",
    fullName: { $regex: regex },
  };

  if (after) {
    const [afterName, afterId] = String(after).split("|");

    if (!afterName || !mongoose.Types.ObjectId.isValid(afterId)) {
      throw new BadRequestError("Invalid cursor", "INVALID_CURSOR");
    }

    match.$or = [
      { fullName: { $gt: afterName } },
      {
        fullName: afterName,
        _id: { $gt: new mongoose.Types.ObjectId(afterId) },
      },
    ];
  }

  const workers = await User.aggregate([
    { $match: match },
    { $sort: { fullName: 1, _id: 1 } },
    { $limit: limit + 1 },
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
        _id: 1,
        fullName: 1,
        image: 1,
        rate: { $ifNull: ["$profile.rate", 0] },
      },
    },
  ]);

  const hasNextPage = workers.length > limit;
  const slicedWorkers = hasNextPage ? workers.slice(0, limit) : workers;

  const nextCursor = hasNextPage
    ? `${slicedWorkers[slicedWorkers.length - 1].fullName}|${slicedWorkers[slicedWorkers.length - 1]._id}`
    : null;

  return res.status(200).json({
    success: true,
    data: {
      workers: slicedWorkers,
      nextCursor,
    },
    error: null,
  });
});

export const searchFilteredWorkers = asyncHandler(async (req, res) => {
  const {
    lat,
    lng,
    radiusKm = 5,
    skill,
    search,
    sort = "distance",
    order = "asc",
    after,
  } = req.validateQuery;

  const LIMIT = 15;

  const pipeline = [
    {
      $geoNear: {
        near: {
          type: "Point",
          coordinates: [Number(lng), Number(lat)],
        },
        distanceField: "distanceMeters",
        maxDistance: Number(radiusKm) * 1000,
        spherical: true,
        query: { role: "worker" },
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
    {
      $unwind: {
        path: "$workerProfile",
        preserveNullAndEmptyArrays: true,
      },
    },
    {
      $addFields: {
        ratingValue: { $ifNull: ["$workerProfile.rate", 0] },
        ratingCountValue: { $ifNull: ["$workerProfile.ratingCount", 0] },
        skillsValue: { $ifNull: ["$workerProfile.skills", []] },
      },
    },
  ];

  const matchStage = {};

  if (skill) {
    matchStage.skillsValue = skill;
  }

  if (search) {
    const escaped = search.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    matchStage.fullName = { $regex: new RegExp(`^${escaped}`, "i") };
  }

  if (Object.keys(matchStage).length > 0) {
    pipeline.push({ $match: matchStage });
  }

  if (after) {
    const [afterValueRaw, afterId] = String(after).split("|");

    if (
      !afterValueRaw ||
      !mongoose.Types.ObjectId.isValid(afterId) ||
      Number.isNaN(Number(afterValueRaw))
    ) {
      throw new BadRequestError("Invalid cursor", "INVALID_CURSOR");
    }

    const afterValue = Number(afterValueRaw);
    const afterObjectId = new mongoose.Types.ObjectId(afterId);

    if (sort === "distance") {
      pipeline.push({
        $match: order === "asc"
          ? {
              $or: [
                { distanceMeters: { $gt: afterValue } },
                {
                  distanceMeters: afterValue,
                  _id: { $gt: afterObjectId },
                },
              ],
            }
          : {
              $or: [
                { distanceMeters: { $lt: afterValue } },
                {
                  distanceMeters: afterValue,
                  _id: { $gt: afterObjectId },
                },
              ],
            },
      });
    } else {
      pipeline.push({
        $match: order === "asc"
          ? {
              $or: [
                { ratingValue: { $gt: afterValue } },
                {
                  ratingValue: afterValue,
                  _id: { $gt: afterObjectId },
                },
              ],
            }
          : {
              $or: [
                { ratingValue: { $lt: afterValue } },
                {
                  ratingValue: afterValue,
                  _id: { $gt: afterObjectId },
                },
              ],
            },
      });
    }
  }

  const sortStage =
    sort === "distance"
      ? { distanceMeters: order === "asc" ? 1 : -1, _id: 1 }
      : { ratingValue: order === "asc" ? 1 : -1, _id: 1 };

  pipeline.push(
    { $sort: sortStage },
    { $limit: LIMIT + 1 },
    {
      $project: {
        _id: 1,
        fullName: 1,
        image: 1,
        location: 1,
        distanceMeters: 1,
        workerProfile: {
          skills: "$skillsValue",
          rate: "$ratingValue",
          ratingCount: "$ratingCountValue",
        },
      },
    }
  );

  const workers = await User.aggregate(pipeline);

  const hasNextPage = workers.length > LIMIT;
  const slicedWorkers = hasNextPage ? workers.slice(0, LIMIT) : workers;

  const lastWorker = slicedWorkers[slicedWorkers.length - 1] ?? null;

  let nextCursor = null;
  if (hasNextPage && lastWorker) {
    const cursorValue =
      sort === "distance"
        ? lastWorker.distanceMeters ?? 0
        : lastWorker.workerProfile?.rate ?? 0;

    nextCursor = `${cursorValue}|${lastWorker._id}`;
  }

  return res.status(200).json({
    success: true,
    data: {
      workers: slicedWorkers,
      nextCursor,
    },
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
