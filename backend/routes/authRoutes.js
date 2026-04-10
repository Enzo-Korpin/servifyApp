import express from "express";
import {
  signupUser,
  loginUser,
  verifyEmail,
  checkAuth,
  resendVerificationCode,
  forgotPassword,
  resetPassword,
} from "../service/authService.js";

import { loginValidation } from "../middleware/loginValidation.js";

import { protectRoute } from "../middleware/protecteRoute.js";
import { signupValidation } from "../middleware/signupValidation.js";
import { verifyEmailValidation } from "../middleware/verifyEmailValidation.js";
import { arcjetProtection } from "../middleware/arcjetProtection.js";
import { resendCodeValidation } from "../middleware/resendCodeValidation.js";

const router = express.Router();

router.post("/signup", arcjetProtection, signupValidation, signupUser);
router.post("/login", arcjetProtection, loginValidation, loginUser);
router.post(
  "/verify-email",
  arcjetProtection,
  verifyEmailValidation,
  verifyEmail,
);

router.post(
  "/resend-verification",
  arcjetProtection,
  resendCodeValidation,
  resendVerificationCode,
);

router.get("/check-auth", protectRoute, checkAuth);

router.post("/forgot-password", arcjetProtection, forgotPassword);

router.post("/reset-password/", arcjetProtection, resetPassword);

export default router;
