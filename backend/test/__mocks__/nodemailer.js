// Manual mock for "nodemailer" package
export default {
  createTransport: () => ({
    sendMail: async () => ({ messageId: "test-message-id" }),
  }),
};
