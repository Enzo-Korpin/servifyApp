// backend/utils/googleAuth.js
import { OAuth2Client } from "google-auth-library";
import { UnauthorizedError } from "../errors/httpErrors.js";
import { asyncHandler } from "../middleware/asyncHandler.js";

const googleClient = new OAuth2Client();

const GOOGLE_AUDIENCES = (process.env.GOOGLE_CLIENT_IDS || "")
  .split(",")
  .map((v) => v.trim())
  .filter(Boolean);

const VALID_ISSUERS = new Set([
  "accounts.google.com",
  "https://accounts.google.com",
]);

export const verifyGoogleIdToken = asyncHandler(async (idToken) => {
  if (!idToken) {
    throw new UnauthorizedError(
      "Google ID token is required",
      "GOOGLE_ID_TOKEN_REQUIRED",
    );
  }

  if (!GOOGLE_AUDIENCES.length) {
    throw new Error("GOOGLE_CLIENT_IDS is not configured");
  }

  let ticket;
  try {
    ticket = await googleClient.verifyIdToken({
      idToken,
      audience: GOOGLE_AUDIENCES,
    });
  } catch {
    throw new UnauthorizedError("Invalid Google token", "INVALID_GOOGLE_TOKEN");
  }

  const payload = ticket.getPayload();

  if (!payload) {
    throw new UnauthorizedError(
      "Invalid Google token payload",
      "INVALID_GOOGLE_TOKEN_PAYLOAD",
    );
  }

  if (!VALID_ISSUERS.has(payload.iss)) {
    throw new UnauthorizedError(
      "Invalid Google token issuer",
      "INVALID_GOOGLE_TOKEN_ISSUER",
    );
  }

  if (!payload.sub || !payload.email) {
    throw new UnauthorizedError(
      "Google account data is incomplete",
      "INVALID_GOOGLE_ACCOUNT_DATA",
    );
  }

  return {
    googleSub: payload.sub,
    email: payload.email.toLowerCase(),
    fullName: payload.name?.trim() || payload.email.split("@")[0],
    image: payload.picture || "",
    emailVerified: Boolean(payload.email_verified),
  };
});
