import Joi from "joi";

export const verifyEmailValidator = (data, options) => {
  const schema = Joi.object({
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

    verificationCode: Joi.string()
      .trim()
      .pattern(/^\d{6}$/)
      .required()
      .messages({
        "string.empty": "code is required",
        "any.required": "code is required",
        "string.pattern.base": "code must be exactly 6 digits",
      }),
  }).unknown(false);

  return schema.validate(data, options);
};
