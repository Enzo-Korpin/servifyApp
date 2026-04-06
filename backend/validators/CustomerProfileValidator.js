import Joi from "joi";

export const customerProfileValidator = (data, options) => {
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

    image: Joi.string().trim().uri().optional().allow("").messages({
      "string.base": "image must be a string",
      "string.uri": "image must be a valid URL",
    }),
  }).unknown(false);

  return schema.validate(data, options);
};