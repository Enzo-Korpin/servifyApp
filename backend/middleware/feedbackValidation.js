import { submitFeedbackValidator } from "../validators/feedbackValidator.js";

export const submitFeedbackValidation = (req, res, next) => {
  const { requestId } = req.params ?? {};

  const { error, value } = submitFeedbackValidator(
    req.body ?? {
      abortEarly: false,
      stripUnknown: true,
      convert: true,
    },
  );

  if (error) {
    return res.status(400).json({
      message: error.details.map((d) => d.message.replace(/['"]/g, "")),
    });
  }

  req.body = value;

  next();
};
