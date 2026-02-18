import { VERIFICATION_EMAIL_TEMPLATE } from "./emailTemplates.js";
import { transporter, sender } from "./nodemailer.js";
import { checkCanSend, markSent } from "./emailLimiter.js";

const sendVerificationEmail = async (email, verificationCode) => {
  const gate = checkCanSend(email);
  if (!gate.ok) throw new Error(gate.reason);

  const info = await transporter.sendMail({
    from: sender.from,
    to: email,
    subject: "Verify your Servify account",
    html: VERIFICATION_EMAIL_TEMPLATE.replace("{verificationCode}", verificationCode),
  });

  markSent(email);
  console.log("[MAIL] verification sent:", { to: email, messageId: info.messageId });
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

export { sendVerificationEmail, sendWelcomeEmail };
