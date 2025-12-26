import { signupValidator } from "../validators/signupValidator.js";

export const signupValidation = (req, res, next) => {
  const { error } = signupValidator(req.body ?? {}, {
    abortEarly: false,
    stripUnknown: true,
  });
  if (error)
    return res.status(400).json({
      success: false,
      message: error.details.map((detail) =>
        detail.message.replace(/['"]/g, "")
      ),
    });
  next();
};
