import { aj } from "../lib/arcjet.js";
import dotenv from "dotenv";
dotenv.config();

export const arcjetProtection = async (req, res, next) => {
  try {
    if (process.env.NODE_ENV === "test") {
      return next();
    }

    const decision = await aj.protect(req, {
      requested: 1,
    });

    if (decision.isDenied()) {
      if (decision.reason.isRateLimit()) {
        return res.status(429).json({ error: "Too Many Requests" });
      }

      if (decision.reason.isBot()) {
        return res.status(403).json({ error: "Bot access denied" });
      }

      return res.status(403).json({ error: "Forbidden" });
    }

    // Spoofed bot check
    if (
      decision.results.some(
        (result) => result.reason.isBot() && result.reason.isSpoofed()
      )
    ) {
      return res.status(403).json({ error: "Spoofed bot detected" });
    }

    next();
  } catch (error) {
    console.error("Arcjet error", error);
    next(error);
  }
};
