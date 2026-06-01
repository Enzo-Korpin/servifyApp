import nodemailer from "nodemailer";
import dotenv from "dotenv";

dotenv.config();

const { SMTP_SERVICE, SMTP_USER, SMTP_PASS, EMAIL_FROM } = process.env;

if (!SMTP_USER || !SMTP_PASS) {
  throw new Error("Missing SMTP_USER/SMTP_PASS in .env");
}

export const transporter = nodemailer.createTransport({
  service: SMTP_SERVICE || "gmail",
  auth: { user: SMTP_USER, pass: SMTP_PASS },
});

export const sender = {
  from: EMAIL_FROM || `Servify Team <${SMTP_USER}>`,
};