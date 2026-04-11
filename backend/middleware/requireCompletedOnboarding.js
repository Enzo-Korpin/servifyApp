// backend/middlewares/requireCompletedOnboarding.js
import { ForbiddenError } from "../errors/httpErrors.js";

export const requireCompletedOnboarding = (req, _res, next) => {
  if (req.user?.onboardingStatus && req.user.onboardingStatus !== "complete") {
    throw new ForbiddenError(
      "Complete your onboarding first",
      "ONBOARDING_REQUIRED",
    );
  }

  next();
};
