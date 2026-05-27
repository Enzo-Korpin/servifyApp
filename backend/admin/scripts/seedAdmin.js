/**
 * Idempotent admin seeder. Reads ADMIN_* env vars and:
 *   - if no user with that email exists → creates one with role:"admin", isVerified:true
 *   - if a user exists but is not admin → upgrades role to admin (so you can promote yourself)
 *   - if already admin → no-op
 *
 * Usage:
 *   ADMIN_EMAIL=admin@servify.local \
 *   ADMIN_PASSWORD='Str0ng!Pass' \
 *   ADMIN_FULL_NAME='Servify Admin' \
 *   node backend/admin/scripts/seedAdmin.js
 */
import dotenv from "dotenv";
import bcrypt from "bcrypt";
import mongoose from "mongoose";

dotenv.config();

import { connectDB } from "../../db/connectDB.js";
import User from "../../models/user.js";

const required = (name) => {
  const v = process.env[name];
  if (!v) {
    console.error(`Missing required env var: ${name}`);
    process.exit(1);
  }
  return v;
};

const run = async () => {
  const email = required("ADMIN_EMAIL").toLowerCase().trim();
  const password = required("ADMIN_PASSWORD");
  const fullName = process.env.ADMIN_FULL_NAME?.trim() || "Servify Admin";

  await connectDB();

  const existing = await User.findOne({ email });

  if (existing && existing.role === "admin") {
    console.log(`[seedAdmin] Admin already exists: ${email}`);
    await mongoose.disconnect();
    return;
  }

  if (existing) {
    existing.role = "admin";
    existing.currentRole = "admin";
    existing.isVerified = true;
    existing.isBlocked = false;
    existing.blockedAt = null;
    existing.blockedReason = null;
    await existing.save();
    console.log(`[seedAdmin] Promoted existing user to admin: ${email}`);
    await mongoose.disconnect();
    return;
  }

  const hashed = await bcrypt.hash(password, 10);

  // Admins don't need a real geo location — model now makes it optional for role: admin,
  // but we still pass a dummy Point to keep the schema happy across Mongoose versions.
  await User.create({
    fullName,
    email,
    password: hashed,
    role: "admin",
    currentRole: "admin",
    isVerified: true,
    isBlocked: false,
    authProvider: "local",
    location: { type: "Point", coordinates: [0, 0] },
  });

  console.log(`[seedAdmin] Created new admin: ${email}`);
  await mongoose.disconnect();
};

run().catch((err) => {
  console.error("[seedAdmin] Failed:", err);
  process.exit(1);
});
