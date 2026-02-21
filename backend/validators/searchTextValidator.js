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
    after: Joi.string().trim().optional().messages({
      "string.base": "Cursor must be a string",
    }),
    limit: Joi.number().integer().min(1).max(50).optional().messages({
      "number.base": "Limit must be a number",
      "number.integer": "Limit must be an integer",
      "number.min": "Limit must be at least {#limit}",
      "number.max": "Limit must be at most {#limit}",
    }),
  }).unknown(false);
  return schema.validate(data, options);
};
