import express, { request } from "express";
import dotenv from "dotenv";
import cors from "cors";
import cookieParser from "cookie-parser";
import authRoutes from "./routes/authRoutes.js";
import requestRoutes from "./routes/requestRoutes.js";
import { connectDB } from "./db/connectDB.js";

const app = express();
dotenv.config();
app.use(cors());
app.use(express.json());
app.use(cookieParser());

app.use("/api/auth", authRoutes);
app.use("/api/request", requestRoutes);

const PORT = process.env.PORT;

app.listen(PORT, () => {
  connectDB();
  console.log(`Server started on port ${PORT}`);
});
