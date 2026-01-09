import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import cookieParser from "cookie-parser";

import authRoutes from "./routes/authRoutes.js";
import messageRoutes from "./routes/messageRoutes.js";
import requestRoutes from "./routes/requestRoutes.js";
import followRoutes from "./routes/followRoutes.js";
import customerRoutes from "./routes/customerRoutes.js";

if (process.env.NODE_ENV !== "test") {
  dotenv.config();
}

export const app = express();

app.use(cors());
app.use(express.json());
app.use(cookieParser());

app.use("/api/auth", authRoutes);
app.use("/api/message", messageRoutes);
app.use("/api/request", requestRoutes);
app.use("/api", followRoutes);
app.use("/api/customer", customerRoutes);

  // "test": "echo \"Error: no test specified\" && exit 1"