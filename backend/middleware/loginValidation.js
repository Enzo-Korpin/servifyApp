import { loginValidator } from "../validators/loginValidator.js";

export const loginValidation = (req, res, next) => {
  const { error } = loginValidator(req.body ?? {}, {
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
