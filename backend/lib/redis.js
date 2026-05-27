import IORedis from "ioredis";

/**
 * Single shared Redis connection for the entire backend.
 *
 * Why one client (not three):
 *  - BullMQ already uses ioredis under the hood — having three independent
 *    connections wastes file descriptors and complicates shutdown.
 *  - One client = one place to wire logging, error handlers, and the
 *    REDIS_ENABLED kill-switch.
 *
 * Connection rules:
 *  - If REDIS_ENABLED=false the client is never created — every helper that
 *    depends on Redis will degrade gracefully (cache miss / no rate limit).
 *  - Connection accepts REDIS_URL first (e.g. redis://default:pass@host:6379)
 *    then falls back to REDIS_HOST/REDIS_PORT for the Docker Compose setup.
 *  - lazyConnect = true so importing this module never throws if Redis is down;
 *    we explicitly call .connect() during server startup and log the outcome.
 *  - maxRetriesPerRequest = null is required by BullMQ; we set it here too so
 *    a long-lived command doesn't fail spuriously after a brief drop.
 */

const enabled = String(process.env.REDIS_ENABLED ?? "true").toLowerCase() !== "false";

let redis = null;
let ready = false;

const buildClient = () => {
  const url = process.env.REDIS_URL;

  const common = {
    lazyConnect: true,
    maxRetriesPerRequest: null,
    enableReadyCheck: true,
    // Don't spam reconnect attempts — exponential up to 5s.
    retryStrategy: (times) => Math.min(times * 200, 5000),
  };

  return url
    ? new IORedis(url, common)
    : new IORedis({
        host: process.env.REDIS_HOST || "127.0.0.1",
        port: Number(process.env.REDIS_PORT) || 6379,
        password: process.env.REDIS_PASSWORD || undefined,
        ...common,
      });
};

if (enabled) {
  redis = buildClient();

  redis.on("ready", () => {
    ready = true;
    console.log("[redis] ready");
  });

  redis.on("error", (err) => {
    // Don't crash — just log. Caching/rate-limit helpers will short-circuit
    // while ready === false.
    if (ready) {
      ready = false;
      console.error("[redis] connection error:", err.message);
    }
  });

  redis.on("end", () => {
    ready = false;
    console.warn("[redis] connection closed");
  });
}

/**
 * Establish the Redis connection (call once during boot).
 * Resolves regardless of outcome — never rejects, so the API server starts
 * even if Redis is unreachable.
 */
export const connectRedis = async () => {
  if (!enabled) {
    console.log("[redis] disabled (REDIS_ENABLED=false)");
    return;
  }

  try {
    await redis.connect();
  } catch (err) {
    console.error("[redis] initial connect failed:", err.message);
    // Don't rethrow — server stays up; ready stays false; cache/limit fall back.
  }
};

/**
 * Cleanly close the Redis connection on SIGTERM/SIGINT.
 */
export const disconnectRedis = async () => {
  if (!redis) return;
  try {
    await redis.quit();
  } catch {
    redis.disconnect();
  }
};

/** True only when the client is connected AND ready to accept commands. */
export const isRedisReady = () => ready;

/** Raw client — exported for BullMQ and any low-level needs. Always check isRedisReady() before commanding. */
export const getRedisClient = () => redis;
