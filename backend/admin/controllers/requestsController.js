import { asyncHandler } from "../../middleware/asyncHandler.js";
import ServiceRequest from "../../models/serviceRequest.js";
import { NotFoundError } from "../../errors/httpErrors.js";
import { okResponse, paginatedResponse } from "../utils/paginate.js";

/**
 * GET /api/admin/service-requests
 * Server-side pagination + filter (status/customerId/workerId) + sort.
 */
export const listRequests = asyncHandler(async (req, res) => {
  const { page, limit, status, customerId, workerId, sortBy, sortOrder } = req.query;

  const filter = {};
  if (status !== "all") filter.status = status;
  if (customerId) filter.customerId = customerId;
  if (workerId) filter.workerId = workerId;

  const sort = { [sortBy]: sortOrder === "asc" ? 1 : -1 };
  const skip = (page - 1) * limit;

  const [items, total] = await Promise.all([
    ServiceRequest.find(filter)
      .select(
        "customerId workerId status message addressText location createdAt acceptedAt rejectedAt cancelledAt rejectReason cancelReason"
      )
      .populate({ path: "customerId", select: "fullName email image role" })
      .populate({ path: "workerId", select: "fullName email image role" })
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean(),
    ServiceRequest.countDocuments(filter),
  ]);

  return paginatedResponse(res, { data: items, page, limit, total });
});

/**
 * GET /api/admin/service-requests/:id
 */
export const getRequest = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const request = await ServiceRequest.findById(id)
    .populate({ path: "customerId", select: "fullName email image role location" })
    .populate({ path: "workerId", select: "fullName email image role location" })
    .lean();

  if (!request) throw new NotFoundError("Request not found", "REQUEST_NOT_FOUND");
  return okResponse(res, request);
});

/**
 * DELETE /api/admin/service-requests/:id
 * Hard delete. Confirmation enforced by the client.
 */
export const deleteRequest = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const deleted = await ServiceRequest.findByIdAndDelete(id).lean();
  if (!deleted) throw new NotFoundError("Request not found", "REQUEST_NOT_FOUND");

  return okResponse(res, { _id: id, deleted: true });
});
