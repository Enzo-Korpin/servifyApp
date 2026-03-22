import Joi from "joi";

export const submitFeedbackValidator = (data, options) => {
  const schema = Joi.object({
    rate: Joi.number().min(1).max(5).required().messages({
      "number.base": "Rating must be a number",
      "number.min": "Rating must be between 1 and 5",
      "number.max": "Rating must be between 1 and 5",
      "any.required": "Rating is required",
    }),

    comment: Joi.string().trim().max(1000).allow("").default(""),
  }).unknown(false);

  return schema.validate(data, options);
};
