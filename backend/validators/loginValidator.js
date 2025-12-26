import Joi from "joi";

export const loginValidator = (data, options) => {
  const schema = Joi.object({
    email: Joi.string()
      .trim()
      .lowercase()
      .email({ tlds: { allow: false } })
      .required()
      .messages({
        "string.email": "Please provide a valid email",
        "any.required": "Email is required",
        "string.empty": "Email is required",
      }),

    password: Joi.string().trim().min(8).max(64).required().messages({
      "any.required": "Password is required",
      "string.empty": "Password is required",
      "string.min": "Password must be at least {#limit} characters",
    }),
  }).unknown(false);

  return schema.validate(data, options);
};
