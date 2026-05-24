import { customerProfileValidation } from "../validators/customerProfileValidator.js";

export const customerProfileValidation = (req, res, next) => {
  const { error, value } = customerProfileValidation(req.body ?? {}, {
    abortEarly: false,
    stripUnknown: true,
    convert: true,
  });

  if (error) {
    return res.status(400).json({
      success: false,
      data: null,
      error: error.details.map((detail) => detail.message.replace(/['"]/g, "")),
    });
  }

  req.body = value;
  next();
};