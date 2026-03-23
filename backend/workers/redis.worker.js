import { Worker } from "bullmq";
import IORedis from "ioredis";

const connection = new IORedis({
  host: process.env.REDIS_HOST || "redis",
  port: process.env.REDIS_PORT || 6379,
  maxRetriesPerRequest: null,
});

const worker = new Worker(
  "rides",
  async (job) => {
    console.log("📦 Received job:", job.data);

    // TEMP: no business logic
    return { status: "processed" };
  },
  { connection },
);

console.log("🚀 Worker is running...");
