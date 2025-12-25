const { MailtrapClient } = require("mailtrap");
require("dotenv").config();

const TOKEN = process.env.MAILTRAP_API_TOKEN;
const ENDPOINT = process.env.MAILTRAP_API_ENDPOINT;

const mailtrapClient = new MailtrapClient({
    endpoint: ENDPOINT,
    token: TOKEN,
});

const sender = {
    
    email: "servify@demomailtrap.co",
    name: "Servify Team",
};

module.exports = {
    mailtrapClient,
    sender,
};