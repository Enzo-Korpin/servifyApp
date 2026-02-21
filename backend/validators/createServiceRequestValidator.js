import Joi from "joi";

export const createServiceRequestValidator = (data, options) => {
  const schema = Joi.object({
    message: Joi.string().trim().max(256).optional().messages({
      "string.base": "message text must be a string",
      "string.empty": "Message is required",
      "string.max": "Message must be at most {#limit} characters",
    }),
    addressText: Joi.string().trim().max(256).optional().messages({
      "string.base": "Address text must be a string",
      "string.empty": "Address text is required",
      "string.max": "Address text must be at most {#limit} characters",
    }),
    lat: Joi.number().min(-90).max(90).required().messages({
      "number.base": "lat must be a number",
      "number.min": "lat must be >= -90",
      "number.max": "lat must be <= 90",
    }),

    lng: Joi.number().min(-180).max(180).required().messages({
      "number.base": "lng must be a number",
      "number.min": "lng must be >= -180",
      "number.max": "lng must be <= 180",
    }),
    workerId: Joi.string().required().messages({
      "string.base": "workerId must be a string",
      "string.empty": "workerId is required",
      "any.required": "workerId is required",
    }),
  }).unknown(false);
  return schema.validate(data, options);
};
