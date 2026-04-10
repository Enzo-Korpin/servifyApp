import Joi from "joi";

export const resetPasswordValidator = (data, options) => {
  const schema = Joi.object({
    newPassword: Joi.string()
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

    confirmPassword: Joi.string()
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
    token: Joi.string().hex().length(64).required().messages({
      "string.empty": "token is required",
      "string.hex": "token must be a valid hexadecimal string",
    }),
  }).unknown(false);

  return schema.validate(data, options);
};
