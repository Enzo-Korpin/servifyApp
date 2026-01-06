import Joi from "joi";

export const searchTextValidator = (data, options) => {
  const schema = Joi.object({
    search: Joi.string().trim().min(2).max(100).required().messages({
      "string.base": "Search text must be a string",
      "string.empty": "Search text is required",
      "string.min": "Search text must be at least {#limit} characters",
      "string.max": "Search text must be at most {#limit} characters",
      "any.required": "Search text is required",
    }),
  }).unknown(false);
  return schema.validate(data, options);
};
