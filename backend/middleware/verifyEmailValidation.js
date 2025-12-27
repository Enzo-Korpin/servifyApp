import { verifyEmailValidator } from "../validators/verifyEmailValidator.js";

export const verifyEmailValidation = (req, res, next) => {
  const { error } = verifyEmailValidator(req.body ?? {}, {
    abortEarly: false,
    stripUnknown: true,
  });
  if (error)
    return res.status(400).json({
      message: error.details.map((detail) =>
        detail.message.replace(/['"]/g, "")
      ),
    });
  next();
};
