import { AppError } from "../errors/appError.js";

// Optional: map some common library errors to proper HTTP responses
const normalizeError = (err) => {
  // Mongoose: invalid ObjectId, etc.
  if (err?.name === "CastError") {
    return new AppError("Invalid ID format", 400, "INVALID_ID", {
      path: err.path,
      value: err.value,
    });
  }

  // Mongoose validation errors
  if (err?.name === "ValidationError") {
    const details = Object.values(err.errors || {}).map((e) => ({
      field: e.path,
      message: e.message,
    }));
    return new AppError("Validation failed", 400, "VALIDATION_ERROR", details);
  }

  // Duplicate key error (Mongo)
  if (err?.code === 11000) {
    const fields = Object.keys(err.keyValue || {});
    return new AppError("Duplicate key", 409, "DUPLICATE_KEY", {
      fields,
      keyValue: err.keyValue,
    });
  }

  return err;
};

export const errorHandler = (err, req, res, next) => {
  console.error("[ERROR]", {
    method: req.method,
    path: req.originalUrl,
    message: err?.message,
    name: err?.name,
    code: err?.code,
    command: err?.command,
    response: err?.response,
    responseCode: err?.responseCode,
    stack: err?.stack,
  });
  const normalized = normalizeError(err);

  const isAppError = normalized instanceof AppError;

  const statusCode = isAppError ? normalized.statusCode : 500;
  const code = isAppError ? normalized.code : "INTERNAL_SERVER_ERROR";

  // Don’t leak stack/unknown errors in production
  const message = isAppError
    ? normalized.message
    : process.env.NODE_ENV === "production"
      ? "Something went wrong"
      : normalized?.message || "Something went wrong";

  return res.status(statusCode).json({
    success: false,
    data: null,
    error: {
      code,
      message,
      details: isAppError ? normalized.details : null,
      // Only include stack in dev
      ...(process.env.NODE_ENV !== "production" && !isAppError
        ? { stack: normalized?.stack }
        : {}),
    },
  });
};
