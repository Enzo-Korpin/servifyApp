import { getRedisClient, isRedisReady } from "./redis.js";
import { TooManyRequestsError } from "../errors/httpErrors.js";

/**
 * Simple fixed-window rate limiter, atomic via Redis INCR+EXPIRE.
 *
 * Why fixed-window (not sliding/token bucket):
 *  - admin actions are bursty + low-volume (a human clicking "delete")
 *  - fixed-window is one round-trip and easy to reason about
 *  - if you need stricter shaping for public endpoints, arcjet already covers
 *    auth — leave that alone
 *
 * If Redis is down → the limiter quietly allows the request. That's the
 * correct failure mode for an internal admin tool: don't lock yourself out.
 *
 *   limit({ keyPrefix: "rate:admin", windowSec: 60, max: 5 })
 */
export const createRateLimiter = ({ keyPrefix, windowSec, max, scope }) => {
  if (!keyPrefix || !windowSec || !max) {
    throw new Error("createRateLimiter requires keyPrefix, windowSec, max");
  }

  return async (req, _res, next) => {
    try {
      if (!isRedisReady()) return next(); // fail-open

      const identifier = scope === "user" ? req.user?._id?.toString() : req.ip;
      if (!identifier) return next();

      const key = `${keyPrefix}:${identifier}`;
      const client = getRedisClient();

      // Atomic: increment, then set TTL only on the first hit of the window.
      const count = await client.incr(key);
      if (count === 1) await client.expire(key, windowSec);

      if (count > max) {
        const ttl = await client.ttl(key);
        return next(
          new TooManyRequestsError(
            `Too many requests. Try again in ${Math.max(ttl, 1)}s.`,
            "RATE_LIMITED",
            { retryAfterSeconds: Math.max(ttl, 1) },
          ),
        );
      }

      return next();
    } catch (err) {
      console.error("[rateLimit] error:", err.message);
      return next(); // fail-open
    }
  };
};

// Preset for sensitive admin actions: 10 calls / 60s per admin.
// Tweak per route if you need tighter limits (e.g. mass delete).
export const adminSensitiveLimiter = createRateLimiter({
  keyPrefix: "rate:admin:sensitive",
  windowSec: 60,
  max: 10,
  scope: "user",
});

// Prevent a single customer from spamming workers with requests.
// arcjet covers per-IP — this is per-userId, which is the right scope for
// authenticated abuse. 5 new requests / minute is generous for real usage,
// tight for scripted abuse.
export const createRequestLimiter = createRateLimiter({
  keyPrefix: "rate:user:create-request",
  windowSec: 60,
  max: 5,
  scope: "user",
});

// Feedback creation is heavily gated by business logic already (must own the
// request, request must be accepted, only one feedback per requestId), but a
// per-user limiter still helps if someone scripts mass-creation across
// multiple accepted requests.
export const submitFeedbackLimiter = createRateLimiter({
  keyPrefix: "rate:user:submit-feedback",
  windowSec: 60,
  max: 5,
  scope: "user",
});
