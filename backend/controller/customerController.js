import User from "../models/user.js";
import { asyncHandler } from "../middleware/asyncHandler.js";
import { BadRequestError, UnauthorizedError, ForbiddenError, NotFoundError, ConflictError, PayloadTooLargeError } from "../errors/httpErrors.js";
export const getCustomerProfile = asyncHandler(async (req, res) => {});

export const updateCustomerProfile = asyncHandler(async (req, res) => {});

export const getFilteredWorkers = asyncHandler(async (req, res) => {
  
    const { skill, radiusKm = 5, sort = "distance" } = req.validateQuery;

    const coords = req.user?.location?.coordinates;
    if (!coords || coords.length !== 2) {
       
    }
    const [customerLng, customerLat] = coords;

    const radiusMeters = Number(radiusKm) * 1000;
    if (!Number.isFinite(radiusMeters) || radiusMeters <= 0) {
      throw new BadRequestError("Invalid radiusKm", "INVALID_RADIUS");
    }

    const match = { role: "worker" };

    const sortStage =
      sort === "distance"
        ? { distanceMeters: 1 }
        : sort === "rating"
        ? { "workerProfile.rate": -1, distanceMeters: 1 }
        : sort === "ratingCount"
        ? { "workerProfile.numberOfRatings": -1, distanceMeters: 1 }
        : null;

    if (!sortStage) {
      throw new BadRequestError("Invalid sort. Use: distance | rating | ratingCount", "INVALID_SORT");  
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

    return res.status(200).json({ success: true, data: workers , error: null });
  
});

export const searchWorkersByName = asyncHandler(async (req, res) => {
  
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

    return res.status(200).json({ success: true, data: workers , error: null });
  
});
