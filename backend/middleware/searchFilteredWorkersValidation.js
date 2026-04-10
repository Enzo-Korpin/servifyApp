import { searchFilteredWorkersValidator } from "../validators/newFilterValidator.js";
import { BadRequestError } from "../errors/httpErrors.js";

export const searchFilteredWorkersValidation = (req, res, next) => {
  const { error, value } = searchFilteredWorkersValidator(req.query, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    throw new BadRequestError(
      error.details.map((d) => d.message).join(", "),
      "VALIDATION_ERROR"
    );
  }

  req.validateQuery = value;
  next();
};