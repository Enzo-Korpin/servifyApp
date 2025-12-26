import Joi from "joi";

export const signupValidator = (data, options) => {
  const schema = Joi.object({
    fullName: Joi.string()
      .trim()
      .min(3)
      .max(50)
      .pattern(/^[\p{L}][\p{L}\s'.-]*$/u)
      .required()
      .messages({
        "string.base": "fullName must be a string",
        "string.empty": "fullName is required",
        "string.min": "fullName must be at least {#limit} characters long",
        "string.max": "fullName must be at most {#limit} characters long",
        "string.pattern.base": "fullName contains invalid characters",
        "any.required": "fullName is required",
      }),

    email: Joi.string()
      .trim()
      .lowercase()
      .email({ tlds: { allow: false } })
      .required()
      .messages({
        "string.email": "Please provide a valid email",
        "string.empty": "email is required",
        "any.required": "email is required",
      }),

    password: Joi.string()
      .trim()
      .min(8)
      .max(64)
      .pattern(/[a-z]/, "lowercase")
      .pattern(/[A-Z]/, "uppercase")
      .pattern(/[0-9]/, "number")
      .required()
      .messages({
        "string.empty": "password is required",
        "string.min": "password must be at least {#limit} characters long",
        "string.max": "password must be at most {#limit} characters long",
        "string.pattern.name":
          "password must contain at least one {#name} character",
        "any.required": "password is required",
      }),

    lat: Joi.number().min(-90).max(90).optional().messages({
      "number.base": "lat must be a number",
      "number.min": "lat must be >= -90",
      "number.max": "lat must be <= 90",
    }),

    lng: Joi.number().min(-180).max(180).optional().messages({
      "number.base": "lng must be a number",
      "number.min": "lng must be >= -180",
      "number.max": "lng must be <= 180",
    }),

    image: Joi.string().trim().uri().optional().messages({
      "string.uri": "image must be a valid URL",
    }),

    role: Joi.string().valid("customer", "worker").required().messages({
      "any.only": "role must be either customer or worker",
    }),

    bio: Joi.string().trim().max(500).optional().messages({
      "string.max": "bio must be at most {#limit} characters long",
    }),

    yearsOfExperience: Joi.number()
      .integer()
      .min(1)
      .max(60)
      .required()
      .when("role", {
        is: "worker",
        then: Joi.number().integer().min(1).max(60).required(),
        otherwise: Joi.optional().default(0),
      })
      .messages({
        "number.base": "yearsOfExperience must be a number",
        "number.integer": "yearsOfExperience must be an integer",
        "number.min": "yearsOfExperience must be >= 1",
        "number.max": "yearsOfExperience must be <= 60",
      }),

    skills: Joi.array()
      .min(1)
      .max(30)
      .unique()
      .when("role", {
        is: "worker",
        then: Joi.array().min(1).required(),
        otherwise: Joi.optional().default([]),
      })
      .messages({
        "array.min": "skills must contain at least one skill",
        "any.required": "skills is required for worker",
        "array.unique": "skills must not contain duplicates",
        "array.max": "skills must contain at most {#limit} items",
      }),
  }).unknown(false);

  return schema.validate(data, options);
};
