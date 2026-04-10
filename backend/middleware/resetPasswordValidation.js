import { resetPasswordValidator } from "../validators/resetPasswordValidator.js";

export const resetPasswordValidation = (req, res, next) => {
  const { error, value } = resetPasswordValidator(req.body ?? {}, {
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
  req.body = value;
  next();
};
