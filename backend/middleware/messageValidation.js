import mongoose from "mongoose";
import { sendMessageValidator } from "../validators/sendMessageValidator.js";

export const sendMessageValidation = (req, res, next) => {
  const { error, value } = sendMessageValidator(req.body ?? {}, {
    abortEarly: false,
    stripUnknown: true,
    convert: true,
  });

  if (error) {
    return res.status(400).json({
      success: false,
      data: null,
      error: error.details.map((detail) => detail.message.replace(/['"]/g, "")),
    });
  }
  req.body = value;
  next();
};
