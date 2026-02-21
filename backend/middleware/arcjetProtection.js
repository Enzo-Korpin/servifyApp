import { aj } from "../lib/arcjet.js";
import dotenv from "dotenv";
dotenv.config();

import { asyncHandler } from "../middleware/asyncHandler.js";
import { ForbiddenError, PayloadTooLargeError } from "../errors/httpErrors.js";
export const arcjetProtection = asyncHandler(async (req, res, next) => {
  if (process.env.NODE_ENV === "test") {
    return next();
  }

  const decision = await aj.protect(req, {
    requested: 1,
  });

  if (decision.isDenied()) {
    if (decision.reason.isRateLimit()) {
      throw new PayloadTooLargeError(
        "Rate limit exceeded",
        "RATE_LIMIT_EXCEEDED",
      );
    }

    if (decision.reason.isBot()) {
      throw new ForbiddenError("Bot access denied", "BOT_ACCESS_DENIED");
    }

    throw new ForbiddenError("Access denied", "ACCESS_DENIED");
  }

  // Spoofed bot check
  if (
    decision.results.some(
      (result) => result.reason.isBot() && result.reason.isSpoofed(),
    )
  ) {
    throw new ForbiddenError("Spoofed bot detected", "SPOOFED_BOT_DETECTED");
  }

  next();
});
