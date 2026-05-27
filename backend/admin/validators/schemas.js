import Joi from "joi";
import { paginationSchema, sortOrderSchema, objectIdRegex } from "./validateQuery.js";
import { BadRequestError } from "../../errors/httpErrors.js";

export const listUsersSchema = Joi.object({
  ...paginationSchema,
  search: Joi.string().trim().max(120).allow("").default(""),
  role: Joi.string().valid("customer", "worker", "admin", "all").default("all"),
  isVerified: Joi.string().valid("true", "false", "all").default("all"),
  isBlocked: Joi.string().valid("true", "false", "all").default("all"),
  sortBy: Joi.string().valid("createdAt", "fullName", "email").default("createdAt"),
  sortOrder: sortOrderSchema,
});

export const listWorkersSchema = Joi.object({
  ...paginationSchema,
  search: Joi.string().trim().max(120).allow("").default(""),
  minRating: Joi.number().min(0).max(5).default(0),
  minExperience: Joi.number().integer().min(0).default(0),
  sortBy: Joi.string().valid("createdAt", "rate", "ratingCount", "yearsOfExperience").default("createdAt"),
  sortOrder: sortOrderSchema,
});

export const listRequestsSchema = Joi.object({
  ...paginationSchema,
  status: Joi.string().valid("pending", "accepted", "rejected", "cancelled", "all").default("all"),
  customerId: Joi.string().pattern(objectIdRegex).optional(),
  workerId: Joi.string().pattern(objectIdRegex).optional(),
  sortBy: Joi.string().valid("createdAt").default("createdAt"),
  sortOrder: sortOrderSchema,
});

export const listFeedbackSchema = Joi.object({
  ...paginationSchema,
  minRating: Joi.number().min(0).max(5).default(0),
  maxRating: Joi.number().min(0).max(5).default(5),
  search: Joi.string().trim().max(120).allow("").default(""),
  workerId: Joi.string().pattern(objectIdRegex).optional(),
  customerId: Joi.string().pattern(objectIdRegex).optional(),
  sortBy: Joi.string().valid("createdAt", "rate").default("createdAt"),
  sortOrder: sortOrderSchema,
});

export const listNotificationsSchema = Joi.object({
  ...paginationSchema,
  type: Joi.string().valid("request_accepted", "request_rejected", "all").default("all"),
  isRead: Joi.string().valid("true", "false", "all").default("all"),
});

export const blockUserSchema = Joi.object({
  isBlocked: Joi.boolean().required(),
  reason: Joi.string().trim().max(500).allow("").optional(),
});

export const idParamSchema = Joi.object({
  id: Joi.string().pattern(objectIdRegex).required(),
});

export const validateParams = (schema) => (req, _res, next) => {
  const { error, value } = schema.validate(req.params, {
    abortEarly: false,
    stripUnknown: true,
  });
  if (error) {
    const details = error.details.map((d) => ({
      field: d.path.join("."),
      message: d.message,
    }));
    return next(new BadRequestError("Invalid path parameters", "INVALID_PARAMS", details));
  }
  req.params = value;
  return next();
};

export const validateBody = (schema) => (req, _res, next) => {
  const { error, value } = schema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true,
    convert: true,
  });
  if (error) {
    const details = error.details.map((d) => ({
      field: d.path.join("."),
      message: d.message,
    }));
    return next(new BadRequestError("Invalid request body", "INVALID_BODY", details));
  }
  req.body = value;
  return next();
};
