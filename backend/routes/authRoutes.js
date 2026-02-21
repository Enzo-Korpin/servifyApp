import express from "express";
import {
  signupUser,
  loginUser,
  verifyEmail,
  checkAuth,
  switchRole,
  resendVerificationCode,
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
router.post("/switch-role", protectRoute, switchRole);

export default router;
