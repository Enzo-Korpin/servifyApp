// import mongoose from "mongoose";
// import { submitFeedbackValidator } from "../validators/feedbackValidator.js";

// export const submitFeedbackValidation = (req, res, next) => {
//   const { requestId } = req.params ?? {};

//   if (!mongoose.Types.ObjectId.isValid(requestId)) {
//     return res.status(400).json({ message: "Invalid requestId" });
//   }

//   const { error, value } = submitFeedbackValidator(
//     req.body ?? {
//       abortEarly: false,
//       stripUnknown: true,
//       convert: true,
//     }
//   );

//   if (error) {
//     return res.status(400).json({
//       message: error.details.map((d) => d.message.replace(/['"]/g, "")),
//     });
//   }

//   req.body = value;

//   next();
// };
import { submitFeedbackValidator } from "../validators/feedbackValidator.js";

export const submitFeedbackValidation = (req, res, next) => {
  const { error, value } = submitFeedbackValidator(req.body ?? {});

  if (error) {
    return res.status(400).json({
      message: error.details.map((d) => d.message.replace(/['"]/g, "")),
    });
  }

  req.body = value;
  next();
};
