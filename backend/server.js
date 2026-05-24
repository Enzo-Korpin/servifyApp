// import express, { request } from "express";
// // import dotenv from "dotenv";
// import cors from "cors";
// import cookieParser from "cookie-parser";
// import authRoutes from "./routes/authRoutes.js";
// import messageRoutes from "./routes/messageRoutes.js";
// import requestRoutes from "./routes/requestRoutes.js";
// import followRoutes from "./routes/followRoutes.js";
// import customerRoutes from "./routes/customerRoutes.js";
// import feedbackRoutes from "./routes/feedbackRoutes.js";
// import workerRoutes from "./routes/workerRoutes.js";
// import aiRoutes from "./ai/ai.routes.js";
// import notificationRoutes from "./routes/notificationRoutes.js";
// import { connectDB } from "./db/connectDB.js";
// import { RouteNotFound } from "./middleware/routeNoteFound.js";
// import { errorHandler } from "./middleware/errorHandler.js";

// const app = express();
// // dotenv.config();
// app.use(
//   cors({
//     origin: true,
//     credentials: true,
//   }),
// );
// app.use(express.json());
// app.use(cookieParser());

// app.use("/api/auth", authRoutes);
// app.use("/api/message", messageRoutes);
// app.use("/api/service-requests", requestRoutes);
// app.use("/api", followRoutes);
// app.use("/api/customer", customerRoutes);
// app.use("/api/feedback", feedbackRoutes);
// app.use("/api/worker", workerRoutes);
// app.use("/api/ai", aiRoutes);
// app.use("/api/notifications", notificationRoutes);
// app.use(RouteNotFound);
// app.use(errorHandler);

// const PORT = process.env.PORT || 5000;

// app.listen(PORT, () => {
//   connectDB();
//   console.log(`Server started on port ${PORT}`);
// });
import dotenv from "dotenv";
import express from "express";
import http from "http";
import cors from "cors";
import cookieParser from "cookie-parser";

dotenv.config();

import authRoutes from "./routes/authRoutes.js";
import messageRoutes from "./routes/messageRoutes.js";
import requestRoutes from "./routes/requestRoutes.js";
import followRoutes from "./routes/followRoutes.js";
import customerRoutes from "./routes/customerRoutes.js";
import feedbackRoutes from "./routes/feedbackRoutes.js";
import workerRoutes from "./routes/workerRoutes.js";
import aiRoutes from "./ai/ai.routes.js";
import notificationRoutes from "./routes/notificationRoutes.js";

import { connectDB } from "./db/connectDB.js";
import { initSocket } from "./lib/socket.js";
import { RouteNotFound } from "./middleware/routeNoteFound.js";
import { errorHandler } from "./middleware/errorHandler.js";

const app = express();
const server = http.createServer(app);

const allowedOrigins = process.env.CLIENT_ORIGINS
  ? process.env.CLIENT_ORIGINS.split(",").map((origin) => origin.trim()).filter(Boolean)
  : true;

const corsOptions = {
  origin: allowedOrigins,
  credentials: true,
};

app.use(cors(corsOptions));
app.use(express.json({ limit: "5mb" }));
app.use(cookieParser());

app.use("/api/auth", authRoutes);
app.use("/api/message", messageRoutes);
app.use("/api/service-requests", requestRoutes);
app.use("/api", followRoutes);
app.use("/api/customer", customerRoutes);
app.use("/api/feedback", feedbackRoutes);
app.use("/api/worker", workerRoutes);
app.use("/api/ai", aiRoutes);
app.use("/api/notifications", notificationRoutes);
app.get("/health", (req, res) => {
  res.status(200).json({ success: true, message: "OK" });
});
app.use(RouteNotFound);
app.use(errorHandler);

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  await connectDB();

  initSocket(server, { cors: corsOptions });

  server.listen(PORT, () => {
    console.log(`Server started on port ${PORT}`);
  });
};

startServer().catch((error) => {
  console.error("Failed to start server:", error.message);
  process.exit(1);
});
