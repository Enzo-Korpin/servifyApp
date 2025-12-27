import { sendVerificationEmail } from "./emails.js";

await sendVerificationEmail("karam.taher56@gmail.com", "123456");
console.log("done");
process.exit(0);
