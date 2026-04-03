import Joi from "joi";

export const filterValidator = (data, options) => {
  const schema = Joi.object({
    skill: Joi.string().trim().min(1).max(64).optional().messages({
      "string.base": "Skill must be a string",
      "string.empty": "Skill is required",
      "string.min": "Skill must be at least {#limit} characters",
      "any.required": "Skill is required",
    }),

    radiusKm: Joi.number().integer().min(1).max(10).required().messages({
      "number.base": "Radius must be a number",
      "number.integer": "Radius must be an integer",
      "number.min": "Radius must be at least {#limit} km",
      "number.max": "Radius cannot exceed {#limit} km",
      "any.required": "Radius is required",
    }),

    sort: Joi.string()
      .trim()
      .valid("distance", "rating", "ratingCount")
      .default("distance")
      .messages({
        "string.base": "Sort must be a string",
        "any.only": "Sort must be one of: distance, rating, ratingCount",
      }),
    limit: Joi.number().integer().min(1).max(50).optional().messages({
      "number.base": "Limit must be a number",
      "number.integer": "Limit must be an integer",
      "number.min": "Limit must be at least {#limit}",
      "number.max": "Limit must be at most {#limit}",
    }),
    after: Joi.string().trim().optional().messages({
      "string.base": "Cursor must be a string",
    }),
    lat: Joi.number().min(-90).max(90).optional().messages({
      "number.base": "Latitude must be a number",
      "number.min": "Latitude must be at least {#limit}",
      "number.max": "Latitude must be at most {#limit}",
    }),

    lng: Joi.number().min(-180).max(180).optional().messages({
      "number.base": "Longitude must be a number",
      "number.min": "Longitude must be at least {#limit}",
      "number.max": "Longitude must be at most {#limit}",
    }),
  })
    .custom((value, helpers) => {
      const hasLat = value.lat !== undefined;
      const hasLng = value.lng !== undefined;

      if (hasLat !== hasLng) {
        return helpers.error("any.invalid");
      }

      return value;
    })
    .messages({
      "any.invalid": "lat and lng must be provided together",
    }).unknown(false);

  return schema.validate(data, options);
};
