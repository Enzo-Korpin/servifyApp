import Joi from "joi";

export const filterValidator = (data, options) => {
  const schema = Joi.object({
    skill: Joi.string().trim().min(1).max(64).required().messages({
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
  }).unknown(false);

  return schema.validate(data, options);
};
