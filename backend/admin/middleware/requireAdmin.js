import { ForbiddenError } from "../../errors/httpErrors.js";

/**
 * Must run AFTER protectRoute. Verifies req.user.role === "admin".
 * Never trust the frontend — every admin endpoint must compose protectRoute + requireAdmin.
 */
export const requireAdmin = (req, _res, next) => {
  if (!req.user || req.user.role !== "admin") {
    return next(new ForbiddenError("Admin access required", "ADMIN_ONLY"));
  }
  return next();
};
