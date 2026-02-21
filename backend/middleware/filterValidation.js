import { filterValidator } from "../validators/filterValidator.js";

export const filterValidation = (req, res, next) => {
  const { error, value } = filterValidator(req.query ?? {}, {
    abortEarly: false,
    stripUnknown: true,
    convert: true,
  });
  if (error)
    return res.status(400).json({
      success: false,
      data: null,
      error: error.details.map((detail) => detail.message.replace(/['"]/g, "")),
    });
  req.validateQuery = value;
  next();
};
