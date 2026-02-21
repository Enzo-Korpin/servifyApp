export const RouteNotFound = (req, res) => {
  return res.status(404).json({
    success: false,
    data: null,
    error: {
      code: "ROUTE_NOT_FOUND",
      message: `Route not found: ${req.method} ${req.originalUrl}`,
      details: null,
    },
  });
};
