import jwt from "jsonwebtoken";
import User from "../models/user.js";
import { asyncHandler } from "./asyncHandler.js";
import { ForbiddenError, UnauthorizedError } from "../errors/httpErrors.js";

export const protectRoute = asyncHandler(async (req, res, next) => {
  let token = req.cookies?.token;

  if (!token) {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith("Bearer ")) {
      token = authHeader.split(" ")[1];
    }
  }

  if (!token) {
    throw new UnauthorizedError("Unauthorized - No Token Provided", "NO_TOKEN");
  }

  let decoded;
  try {
    decoded = jwt.verify(token, process.env.JWT_SECRET);
  } catch (err) {
    throw new UnauthorizedError(
      "Unauthorized - Invalid or Expired Token",
      "INVALID_TOKEN",
    );
  }

  const user = await User.findById(decoded.userId).select("-password");
  if (!user) {
    throw new UnauthorizedError(
      "Unauthorized - User Not Found",
      "USER_NOT_FOUND",
    );
  }

  if (user.isBlocked) {
    throw new ForbiddenError("Account is blocked", "ACCOUNT_BLOCKED");
  }

  req.user = user;
  next();
});
