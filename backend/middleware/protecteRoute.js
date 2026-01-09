import jwt from "jsonwebtoken";
import User from "../models/user.js";

export const protectRoute = async (req, res, next) => {
  try {
    // 1) cookie token (web)
    let token = req.cookies?.token;

    // 2) bearer token (mobile / Postman / tests)
    if (!token) {
      const auth = req.headers.authorization;

      if (auth?.startsWith("Bearer ")) {
        token = auth.split(" ")[1];
      }
    }

    if (!token) {
      return res
        .status(401)
        .json({ message: "Unauthorized - No Token Provided" });
    }

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      return res
        .status(401)
        .json({ message: "Unauthorized - Invalid or Expired Token" });
    }

    const user = await User.findById(decoded.userId).select("-password");
    if (!user) {
      return res.status(401).json({ message: "Unauthorized - User Not Found" });
    }

    req.user = user;
    next();
  } catch (error) {
    console.log("Error in protectRoute middleware:", error.message);
    return res.status(500).json({ message: "Internal server error" });
  }
};
