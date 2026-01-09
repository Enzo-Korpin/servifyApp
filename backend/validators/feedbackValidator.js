// import Joi from "joi";

// export const submitFeedbackValidator = (data) => {
//   const schema = Joi.object({
//     rating: Joi.number()
//       .min(1)
//       .max(5)
//       .required()
//       .custom((value, helpers) => {
//         if (!Number.isInteger(value * 2)) return helpers.error("any.invalid");
//         return value;
//       })
//       .messages({
//         "number.base": "Rating must be a number",
//         "number.min": "Rating must be between 1 and 5",
//         "number.max": "Rating must be between 1 and 5",
//         "any.invalid": "Rating must be in 0.5 steps (1, 1.5, 2, 2.5, ... 5)",
//         "any.required": "Rating is required",
//       }),

//     comment: Joi.string().trim().max(1000).allow("").default(""),
//   }).unknown(false);

//   return schema.validate(data, options);
// };
import Joi from "joi";

export const submitFeedbackValidator = (data) =>
  Joi.object({
    rating: Joi.number()
      .min(1)
      .max(5)
      .required()
      // allow 0.5 steps: 1,1.5,2,...,5
      .custom((value, helpers) => {
        if (!Number.isInteger(value * 2)) return helpers.error("any.invalid");
        return value;
      })
      .messages({
        "number.base": "Rating must be a number",
        "number.min": "Rating must be between 1 and 5",
        "number.max": "Rating must be between 1 and 5",
        "any.required": "rating is required",
        "any.invalid": "Rating must be in 0.5 increments",
      }),

    comment: Joi.string().trim().max(500).allow("").optional(),
  }).validate(data, {
    abortEarly: false,
    stripUnknown: true,
  });
