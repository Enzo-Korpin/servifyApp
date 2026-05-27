import dotenv from "dotenv";
import { Worker } from "bullmq";

dotenv.config();

import { connectRedis, getRedisClient } from "../lib/redis.js";

/**
 * Background worker process. Run with `npm run worker` (separate container in
 * docker-compose). Shares the same Redis client config as the API.
 *
 * If REDIS_ENABLED=false the worker exits cleanly — there's nothing to do.
 */
const start = async () => {
  await connectRedis();
  const connection = getRedisClient();

  if (!connection) {
    console.log("[worker] REDIS_ENABLED=false — worker has nothing to do, exiting.");
    process.exit(0);
  }

  const worker = new Worker(
    "rides",
    async (job) => {
      console.log("[worker] received job:", job.name, job.data);
      // TODO: real business logic — email sends, FCM batches, etc.
      return { status: "processed" };
    },
    { connection },
  );

  worker.on("ready", () => console.log("[worker] ready"));
  worker.on("failed", (job, err) =>
    console.error(`[worker] job ${job?.id} failed:`, err.message),
  );

  console.log("[worker] running");
};

start().catch((err) => {
  console.error("[worker] failed to start:", err);
  process.exit(1);
});
