import Joi from "joi";

export const sendMessageValidator = (data, options) => {
  const schema = Joi.object({
    text: Joi.string().trim().max(2000).allow("").messages({
      "string.max": "text must be at most {#limit} characters",
    }),
    image: Joi.string()
      .trim()
      .pattern(/^data:image\/(png|jpe?g|webp);base64,[A-Za-z0-9+/=]+$/)
      .allow("")
      .messages({
        "string.pattern.base":
          "image must be a valid base64 data URL (png/jpg/webp)",
      }),
  })
    .custom((value, helpers) => {
      const hasText = value.text && value.text.trim().length > 0;
      const hasImage = value.image && value.image.trim().length > 0;
      if (!hasText && !hasImage) return helpers.error("any.custom");
      return value;
    })
    .messages({
      "any.custom": "Message must contain text or image",
    })
    .unknown(false);

  return schema.validate(data, options);
};
