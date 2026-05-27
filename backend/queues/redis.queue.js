import { Queue } from "bullmq";

import { getRedisClient } from "../lib/redis.js";

/**
 * BullMQ requires its own ioredis client with maxRetriesPerRequest: null.
 * Our shared `getRedisClient()` is already configured that way, so we can
 * pass it directly — no second connection.
 *
 * When REDIS_ENABLED=false the client is null. We export `null` in that case
 * and producers must check before calling .add(). Today the queue is unused;
 * keeping the scaffold in place so background jobs (email sends, batched FCM
 * notifications, etc.) have a ready home.
 */
const connection = getRedisClient();

export const ridesQueue = connection
  ? new Queue("rides", { connection })
  : null;
