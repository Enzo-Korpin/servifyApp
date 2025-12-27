import mongoose from "mongoose";
import { sendMessageValidator } from "../validators/sendMessageValidator.js";

export const sendMessageValidation = (req, res, next) => {
  const receiverId = req.params.id;

  if (!mongoose.Types.ObjectId.isValid(receiverId)) {
    return res.status(400).json({ message: "Invalid receiver id" });
  }

  const { error } = sendMessageValidator(req.body ?? {}, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    return res.status(400).json({
      message: error.details.map((d) => d.message.replace(/['"]/g, "")),
    });
  }

  next();
};
