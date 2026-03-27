import express, { request } from "express";
// import dotenv from "dotenv";
import cors from "cors";
import cookieParser from "cookie-parser";
import authRoutes from "./routes/authRoutes.js";
import messageRoutes from "./routes/messageRoutes.js";
import requestRoutes from "./routes/requestRoutes.js";
import followRoutes from "./routes/followRoutes.js";
import customerRoutes from "./routes/customerRoutes.js";
import feedbackRoutes from "./routes/feedbackRoutes.js";
import workerRoutes from "./routes/workerRoutes.js";
import aiRoutes from "./ai/ai.routes.js";
import { connectDB } from "./db/connectDB.js";
import { RouteNotFound } from "./middleware/routeNoteFound.js";
import { errorHandler } from "./middleware/errorHandler.js";

const app = express();
// dotenv.config();
app.use(cors());
app.use(express.json());
app.use(cookieParser());

app.use("/api/auth", authRoutes);
app.use("/api/message", messageRoutes);
app.use("/api/service-requests", requestRoutes);
app.use("/api", followRoutes);
app.use("/api/customer", customerRoutes);
app.use("/api/feedback", feedbackRoutes);
app.use("/api/worker", workerRoutes);
app.use("/api/ai", aiRoutes);

app.use(RouteNotFound);
app.use(errorHandler);

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  connectDB();
  console.log(`Server started on port ${PORT}`);
});
