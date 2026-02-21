import { searchTextValidator } from "../validators/searchTextValidator.js";

export const searchTextValidation = (req, res, next) => {
  const { error, value } = searchTextValidator(req.query ?? {}, {
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
