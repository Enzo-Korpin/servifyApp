/**
 * Build a consistent paginated response envelope.
 *
 *   {
 *     success: true,
 *     data: [...],
 *     pagination: { page, limit, total, totalPages, hasNextPage, hasPrevPage },
 *     error: null,
 *   }
 *
 * Page/limit are assumed to have already been validated/clamped upstream by Joi.
 */
export const buildPagination = ({ page, limit, total }) => {
  const totalPages = total === 0 ? 0 : Math.ceil(total / limit);
  return {
    page,
    limit,
    total,
    totalPages,
    hasNextPage: page < totalPages,
    hasPrevPage: page > 1,
  };
};

export const paginatedResponse = (res, { status = 200, data, page, limit, total }) =>
  res.status(status).json({
    success: true,
    data,
    pagination: buildPagination({ page, limit, total }),
    error: null,
  });

export const okResponse = (res, data = null, status = 200) =>
  res.status(status).json({ success: true, data, error: null });
