import { workerProfileValidator } from "../validators/WorkerProfileValidator.js";

export const workerProfileValidation = (req, res, next) => {
  if (Array.isArray(req.body.skills)) {
    req.body.skills = [
      ...new Set(
        req.body.skills
          .map((skill) => String(skill).toLowerCase().trim())
          .filter(Boolean),
      ),
    ];
  }
  const { error, value } = workerProfileValidator(req.body ?? {}, {
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