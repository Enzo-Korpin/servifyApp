import express from "express";
import {
  signupUser,
  loginUser,
  verifyEmail,
  checkAuth,
  resendVerificationCode,
  logoutUser,
  forgotPassword,
  verifyResetCode,
  resetPassword,
  googleSignIn,
  completeGoogleWorkerProfile,
} from "../service/authService.js";

import { loginValidation } from "../middleware/loginValidation.js";

import { protectRoute } from "../middleware/protecteRoute.js";
import { signupValidation } from "../middleware/signupValidation.js";
import { verifyEmailValidation } from "../middleware/verifyEmailValidation.js";
import { arcjetProtection } from "../middleware/arcjetProtection.js";
import { resendCodeValidation } from "../middleware/resendCodeValidation.js";
import { forgotPasswordValidation } from "../middleware/forgotPasswordValidation.js";
import { resetPasswordValidation } from "../middleware/resetPasswordValidation.js";

const router = express.Router();

router.post("/signup", arcjetProtection, signupValidation, signupUser);
router.post("/login", arcjetProtection, loginValidation, loginUser);
router.post("/logout", logoutUser);
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

router.post("/forgot-password", forgotPasswordValidation, forgotPassword);
router.post("/verify-reset-code", verifyResetCode);
router.post("/reset-password", resetPasswordValidation, resetPassword);

router.get("/check-auth", protectRoute, checkAuth);

router.post("/google", googleSignIn);

export default router;
