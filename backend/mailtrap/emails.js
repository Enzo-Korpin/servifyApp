import { VERIFICATION_EMAIL_TEMPLATE } from "./emailTemplates.js";
import { transporter, sender } from "./nodemailer.js";
import { checkCanSend, markSent } from "./emailLimiter.js";

import { TooManyRequestsError } from "../errors/httpErrors.js";

const sendVerificationEmail = async (email, verificationCode) => {
  const gate = checkCanSend(email);
  if (!gate.ok)
    throw new TooManyRequestsError(
      "Too many emails sent. Please try again later.",
      "EMAIL_RATE_LIMIT_EXCEEDED",
    );

  const info = await transporter.sendMail({
    from: sender.from,
    to: email,
    subject: "Verify your Servify account",
    html: VERIFICATION_EMAIL_TEMPLATE.replace(
      "{verificationCode}",
      verificationCode,
    ),
  });

  markSent(email);
  console.log("[MAIL] verification sent:", {
    to: email,
    messageId: info.messageId,
  });
  return info;
};

const sendWelcomeEmail = async (email, fullName) => {
  const info = await transporter.sendMail({
    from: sender.from,
    to: email,
    subject: "Welcome to Servify 🎉",
    html: `
      <div style="font-family: Arial, sans-serif">
        <h2>Welcome, ${fullName} 👋</h2>
        <p>Thanks for joining <b>Servify</b>.</p>
      </div>
    `,
  });

  markSent(email);
  console.log("[MAIL] welcome sent:", { to: email, messageId: info.messageId });
  return info;
};

const sendResetPasswordEmail = async (email, resetLink) => {
  const gate = checkCanSend(email);
  if (!gate.ok)
    throw new TooManyRequestsError(
      "Too many emails sent. Please try again later.",
      "EMAIL_RATE_LIMIT_EXCEEDED",
    );

  const info = await transporter.sendMail({
    from: sender.from,
    to: email,
    subject: "Reset your Servify password",
    html: `
      <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #222;">
        <h2>Reset your password</h2>
        <p>We received a request to reset your <b>Servify</b> password.</p>
        <p>Click the button below to set a new password:</p>

        <a
          href="${resetLink}"
          style="
            display: inline-block;
            padding: 12px 20px;
            background-color: #2563eb;
            color: #ffffff;
            text-decoration: none;
            border-radius: 8px;
            font-weight: bold;
          "
        >
          Reset Password
        </a>

        <p style="margin-top: 16px;">
          This link will expire soon. If you did not request a password reset,
          you can safely ignore this email.
        </p>

        <p style="word-break: break-all; color: #555;">
          If the button does not work, copy and paste this link into your browser:<br />
          <a href="${resetLink}">${resetLink}</a>
        </p>
      </div>
    `,
  });

  markSent(email);
  console.log("[MAIL] reset password sent:", {
    to: email,
    messageId: info.messageId,
  });

  return info;
};

export { sendVerificationEmail, sendWelcomeEmail, sendResetPasswordEmail };
