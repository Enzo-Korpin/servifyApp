import express from "express";
import {
  signupUser,
  loginUser,
  verifyEmail,
  checkAuth,
} from "../controller/authController.js";

import { loginValidation } from "../middleware/loginValidation.js";

import { protectRoute } from "../middleware/protecteRoute.js";
import { signupValidation } from "../middleware/signupValidation.js";
import { verifyEmailValidation } from "../middleware/verifyEmailValidation.js";
import { arcjetProtection } from "../middleware/arcjetProtection.js";

const router = express.Router();

router.post("/signup", arcjetProtection, signupValidation, signupUser);
router.post("/login", arcjetProtection, loginValidation, loginUser);
router.post(
  "/verify-email",
  arcjetProtection,
  verifyEmailValidation,
  verifyEmail
);
router.get("/check-auth", protectRoute, checkAuth);

export default router;
