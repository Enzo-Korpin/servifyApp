import { aj } from "../lib/arcjet.js";
import { asyncHandler } from "../middleware/asyncHandler.js";
import { BadRequestError, UnauthorizedError, ForbiddenError, NotFoundError, ConflictError, PayloadTooLargeError } from "../errors/httpErrors.js";
export const arcjetProtection = async (req, res, next) => {
  try {
    const decision = await aj.protect(req, {
      requested: 1,
    });

    if (decision.isDenied()) {
      if (decision.reason.isRateLimit()) {
        throw new PayloadTooLargeError("Rate limit exceeded", "RATE_LIMIT_EXCEEDED");
      }

      if (decision.reason.isBot()) {
        throw new ForbiddenError("Bot access denied", "BOT_ACCESS_DENIED");
      }

      throw new ForbiddenError("Access denied", "ACCESS_DENIED");
    }

    // Spoofed bot check
    if (
      decision.results.some(
        (result) => result.reason.isBot() && result.reason.isSpoofed()
      )
    ) {
      throw new ForbiddenError("Spoofed bot detected", "SPOOFED_BOT_DETECTED");
    }

    next();
  } catch (error) {
    console.error("Arcjet error", error);
    next(error);
  }
};
