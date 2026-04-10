import Joi from "joi";

export const searchFilteredWorkersValidator = (data, options) => {
  const schema = Joi.object({
    lat: Joi.number().required().messages({
      "number.base": "Latitude must be a number",
      "any.required": "Latitude is required",
    }),
    lng: Joi.number().required().messages({
      "number.base": "Longitude must be a number",
      "any.required": "Longitude is required",
    }),
    radiusKm: Joi.number().min(1).max(50).default(5).messages({
      "number.base": "Radius must be a number",
      "number.min": "Radius must be at least {#limit} km",
      "number.max": "Radius must be at most {#limit} km",
    }),
    skill: Joi.string().trim().lowercase().optional().messages({
      "string.base": "Skill must be a string",
    }),
    search: Joi.string().trim().min(2).max(100).optional().messages({
      "string.base": "Search text must be a string",
      "string.min": "Search text must be at least {#limit} characters",
      "string.max": "Search text must be at most {#limit} characters",
    }),
    sort: Joi.string().valid("distance", "rating").default("distance"),
    order: Joi.string().valid("asc", "desc").default("asc"),
    after: Joi.string().trim().optional().messages({
      "string.base": "Cursor must be a string",
    }),
  }).unknown(false);

  return schema.validate(data, options);
};