import { signupValidator } from "../validators/signupValidator.js";

export const signupValidation = (req, res, next) => {
  const { error, value } = signupValidator(req.body ?? {}, {
    abortEarly: false,
    stripUnknown: true,
    convert: true,
  });
  if (error)
    return res
      .status(400)
      .json({
        success: false,
        data: null,
        error: error.details.map((detail) =>
          detail.message.replace(/['"]/g, ""),
        ),
      });
  req.body = value;
  next();
};
