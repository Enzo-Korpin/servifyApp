import { VERIFICATION_EMAIL_TEMPLATE } from "./emailTemplates.js";
import { sender, mailtrapClient } from "./mailtrap.js";

const sendVereficationEmail = async (email, verificationCode) => {
  const recipient = [{ email }];
  try {
    const response = await mailtrapClient.send({
      from: sender,
      to: recipient,
      subject: "Verify your Servify account",
      html: VERIFICATION_EMAIL_TEMPLATE.replace(
        "{verificationCode}",
        verificationCode
      ),
      category: "Verification Emails",
    });
    console.log("Verification email sent:", response);
  } catch (error) {
    console.error("Error sending verification email:", error);
  }
};

const sendWelcomeEmail = async (email, fullName) => {
  const recipient = [{ email }];
  try {
    const response = await mailtrapClient.send({
      from: sender,
      to: recipient,
      template_uuid: "f4d717bd-47ef-42aa-9ad2-dd97c5310ea8",
      template_variables: {
        company_info_name: "Servify app",
        name: fullName,
      },
    });
    console.log("Welcome email sent:", response);
  } catch (error) {
    console.error("Error sending welcome email:", error);
  }
};

export { sendVereficationEmail, sendWelcomeEmail };
