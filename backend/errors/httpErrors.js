import { AppError } from "./appError.js";

export class BadRequestError extends AppError {
  constructor(message = "Bad request", code = "BAD_REQUEST", details = null) {
    super(message, 400, code, details);
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = "Unauthorized", code = "UNAUTHORIZED", details = null) {
    super(message, 401, code, details);
  }
}

export class ForbiddenError extends AppError {
  constructor(message = "Forbidden", code = "FORBIDDEN", details = null) {
    super(message, 403, code, details);
  }
}

export class NotFoundError extends AppError {
  constructor(message = "Not found", code = "NOT_FOUND", details = null) {
    super(message, 404, code, details);
  }
}

export class ConflictError extends AppError {
  constructor(message = "Conflict", code = "CONFLICT", details = null) {
    super(message, 409, code, details);
  }
}

export class PayloadTooLargeError extends AppError {
  constructor(message = "Payload too large", code = "PAYLOAD_TOO_LARGE", details = null) {
    super(message, 413, code, details);
  }
}
