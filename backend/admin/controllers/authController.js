import { asyncHandler } from "../../middleware/asyncHandler.js";
import { okResponse } from "../utils/paginate.js";

/**
 * GET /api/admin/auth/me
 * Returns the authenticated admin's safe profile. The frontend uses this to:
 *   - bootstrap the auth context on hard refresh
 *   - render the Topbar/profile menu
 *
 * Auth/role checks are enforced by the chain: protectRoute + requireAdmin.
 */
export const getCurrentAdmin = asyncHandler((req, res) => {
  const u = req.user;
  return okResponse(res, {
    _id: u._id,
    fullName: u.fullName,
    email: u.email,
    role: u.role,
    image: u.image,
    isVerified: u.isVerified,
    isBlocked: u.isBlocked,
    createdAt: u.createdAt,
  });
});
