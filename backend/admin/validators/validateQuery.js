import Joi from "joi";
import { BadRequestError } from "../../errors/httpErrors.js";

/**
 * Validates req.query against a Joi schema and exposes the cleaned values.
 * Uses { convert: true, stripUnknown: true } so query strings like "page=2" become numbers.
 *
 * Express 5 changed `req.query` to a getter-only property — we can't reassign it.
 * We redefine it as a writable property so existing controllers can keep reading
 * `req.query` without any code changes.
 */
export const validateQuery = (schema) => (req, _res, next) => {
  const { value, error } = schema.validate(req.query, {
    abortEarly: false,
    convert: true,
    stripUnknown: true,
  });

  if (error) {
    const details = error.details.map((d) => ({
      field: d.path.join("."),
      message: d.message,
    }));
    return next(new BadRequestError("Invalid query parameters", "INVALID_QUERY", details));
  }

  Object.defineProperty(req, "query", {
    value,
    writable: true,
    configurable: true,
    enumerable: true,
  });
  return next();
};

// Reusable building blocks
export const objectIdRegex = /^[0-9a-fA-F]{24}$/;

export const paginationSchema = {
  page: Joi.number().integer().min(1).default(1),
  // Hard cap at 50 — protects DB and frontend rendering.
  limit: Joi.number().integer().min(1).max(50).default(20),
};

export const sortOrderSchema = Joi.string().valid("asc", "desc").default("desc");
