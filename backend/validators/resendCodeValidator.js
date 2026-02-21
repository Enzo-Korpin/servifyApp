import Joi from "joi";

export const resendCodeValidator = (data, options) => {
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
  }).unknown(false);

  return schema.validate(data, options);
};
