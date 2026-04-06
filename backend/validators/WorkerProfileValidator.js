import Joi from "joi";

export const workerProfileValidator = (data, options) => {
  const schema = Joi.object({
    fullName: Joi.string().trim().min(2).max(100).required().messages({
      "string.base": "fullName must be a string",
      "string.empty": "fullName is required",
      "string.min": "fullName must be at least {#limit} characters long",
      "string.max": "fullName must be at most {#limit} characters long",
      "any.required": "fullName is required",
    }),

    image: Joi.string().trim().uri().optional().allow("").messages({
      "string.base": "image must be a string",
      "string.uri": "image must be a valid URL",
    }),

    bio: Joi.string().trim().max(500).optional().allow("").messages({
      "string.base": "bio must be a string",
      "string.max": "bio must be at most {#limit} characters long",
    }),

    yearsOfExperience: Joi.number().integer().min(0).max(60).required().messages({
      "number.base": "yearsOfExperience must be a number",
      "number.integer": "yearsOfExperience must be an integer",
      "number.min": "yearsOfExperience must be >= 0",
      "number.max": "yearsOfExperience must be <= 60",
      "any.required": "yearsOfExperience is required",
    }),

    skills: Joi.array()
      .items(
        Joi.string().trim().min(1).max(50).messages({
          "string.base": "each skill must be a string",
          "string.empty": "skill cannot be empty",
          "string.min": "skill cannot be empty",
          "string.max": "skill must be at most {#limit} characters long",
        }),
      )
      .min(1)
      .max(30)
      .unique((a, b) => a.trim().toLowerCase() === b.trim().toLowerCase())
      .required()
      .messages({
        "array.base": "skills must be an array",
        "array.min": "skills must contain at least one skill",
        "array.max": "skills must contain at most {#limit} items",
        "array.unique": "skills must not contain duplicates",
        "any.required": "skills is required",
      }),
  }).unknown(false);

  return schema.validate(data, options);
};