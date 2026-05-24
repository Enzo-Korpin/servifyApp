import { CustomerProfileValidation } from "../validators/CustomerProfileValidator.js";

export const CustomerProfileValidation = (req, res, next) => {
  const { error, value } = CustomerProfileValidation(req.body ?? {}, {
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