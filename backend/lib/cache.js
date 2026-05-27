import { getRedisClient, isRedisReady } from "./redis.js";

/**
 * JSON-safe cache helpers with graceful degradation.
 *
 *  - Every helper wraps Redis calls in try/catch so the app survives Redis
 *    outages: cache miss → caller falls back to the DB.
 *  - Values are JSON-encoded on the way in and parsed on the way out. Never
 *    store binary or sensitive material here.
 *  - All keys must include a TTL. Pass `ttl` in seconds.
 *
 * Key convention (enforced by callers — these helpers don't validate names):
 *   admin:stats               → dashboard summary cards
 *   admin:stats:growth:30     → users-growth charts (parametric by days)
 *   admin:stats:by-status     → requests pie chart
 *   admin:stats:top-workers:5 → top-rated workers
 *   admin:stats:active:5      → most-active customers
 *   rate:admin:{userId}:{action} → admin rate limits
 *   rate:login:{ip}           → (reserved if you ever replace arcjet)
 *   otp:reset:{email}         → (reserved — not used yet, see README)
 */

const safeStringify = (value) => {
  try {
    return JSON.stringify(value);
  } catch (err) {
    console.error("[cache] failed to stringify value:", err.message);
    return null;
  }
};

const safeParse = (raw) => {
  if (raw === null || raw === undefined) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
};

/**
 * Read a key. Returns the parsed value, or null on miss / error / Redis down.
 */
export const getCache = async (key) => {
  if (!isRedisReady()) return null;
  try {
    const raw = await getRedisClient().get(key);
    return safeParse(raw);
  } catch (err) {
    console.error(`[cache] get(${key}) failed:`, err.message);
    return null;
  }
};

/**
 * Write a key with a mandatory TTL (seconds). Silently no-ops if Redis is down
 * or if the value can't be serialized.
 */
export const setCache = async (key, value, ttlSeconds) => {
  if (!isRedisReady()) return false;
  if (!ttlSeconds || ttlSeconds <= 0) {
    console.warn(`[cache] refusing to set ${key} without TTL`);
    return false;
  }
  const payload = safeStringify(value);
  if (payload === null) return false;
  try {
    await getRedisClient().set(key, payload, "EX", ttlSeconds);
    return true;
  } catch (err) {
    console.error(`[cache] set(${key}) failed:`, err.message);
    return false;
  }
};

/**
 * Delete one or more exact keys. Safe to call with a single string or an array.
 */
export const deleteCache = async (keys) => {
  if (!isRedisReady()) return 0;
  const list = Array.isArray(keys) ? keys : [keys];
  if (list.length === 0) return 0;
  try {
    return await getRedisClient().del(...list);
  } catch (err) {
    console.error(`[cache] del failed:`, err.message);
    return 0;
  }
};

/**
 * Delete every key matching a glob pattern (e.g. "admin:stats*").
 * Uses SCAN — never KEYS — so it's safe on large datasets.
 */
export const deleteCachePattern = async (pattern) => {
  if (!isRedisReady()) return 0;
  const client = getRedisClient();
  let removed = 0;
  try {
    const stream = client.scanStream({ match: pattern, count: 200 });
    const pipeline = client.pipeline();
    await new Promise((resolve, reject) => {
      stream.on("data", (batch) => {
        for (const k of batch) {
          pipeline.del(k);
          removed += 1;
        }
      });
      stream.on("end", resolve);
      stream.on("error", reject);
    });
    if (removed > 0) await pipeline.exec();
    return removed;
  } catch (err) {
    console.error(`[cache] deletePattern(${pattern}) failed:`, err.message);
    return removed;
  }
};

/**
 * Read-through cache convenience wrapper.
 *
 *   const stats = await withCache("admin:stats", 60, () => buildStats());
 *
 * If the key exists → returns it. Otherwise calls `compute()`, stores the
 * result for `ttlSeconds`, and returns it. If Redis is down → just calls
 * `compute()` directly so the request still succeeds.
 */
export const withCache = async (key, ttlSeconds, compute) => {
  const hit = await getCache(key);
  if (hit !== null) return hit;

  const fresh = await compute();
  // Never cache null/undefined — that would mask real data on the next hit.
  if (fresh !== null && fresh !== undefined) {
    await setCache(key, fresh, ttlSeconds);
  }
  return fresh;
};

// Centralized key builders — keep names consistent across the codebase.
export const cacheKeys = {
  adminStats: () => "admin:stats",
  adminStatsGrowth: (days) => `admin:stats:growth:${days}`,
  adminStatsByStatus: () => "admin:stats:by-status",
  adminStatsTopWorkers: (limit) => `admin:stats:top-workers:${limit}`,
  adminStatsActiveCustomers: (limit) => `admin:stats:active:${limit}`,
  adminReportsOverview: () => "admin:reports:overview",
  // Public worker reads — read by every customer browsing the marketplace.
  workerProfilePublic: (id) => `worker:profile:${id}`,
  // Rate-limit buckets (in addition to admin:sensitive defined in rateLimit.js).
  rateUser: (userId, action) => `rate:user:${userId}:${action}`,
};

/**
 * Wipe every admin-stats key. Call this from mutation controllers
 * (block/delete user, delete request, delete feedback).
 */
export const invalidateAdminStats = () =>
  deleteCachePattern("admin:stats*").catch(() => 0);

/**
 * Wipe cached public worker data after a profile edit, feedback submission,
 * admin block/delete, etc. Safe to call without awaiting if you don't need to
 * block on it — the helper already swallows errors.
 *
 *   - drops worker:profile:{id} for the specific worker
 */
export const invalidateWorkerPublic = async (workerId) => {
  if (!workerId) return 0;
  return deleteCache(cacheKeys.workerProfilePublic(workerId.toString()));
};
