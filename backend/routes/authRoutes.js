const express = require("express");
const router = express.Router();
const { registerUser, loginUser, verifyEmail, checkAuth, switchRole  } = require("../controller/userController");
const { verifyToken} = require("../middleware/verifyToken");

router.post("/register", registerUser);
router.post("/login", loginUser);
router.post("/verify-email", verifyEmail);
router.get("/check-auth", verifyToken, checkAuth);
router.post("/switch-role", verifyToken, switchRole);
module.exports = router;

