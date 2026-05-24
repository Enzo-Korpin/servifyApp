import Joi from "joi";
import { BadRequestError } from "../../errors/httpErrors.js";

/**
 * Validates req.query against a Joi schema. Reassigns req.query to the coerced/cleaned values.
 * Uses { convert: true, stripUnknown: true } so query strings like "page=2" become numbers.
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

  req.query = value;
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
