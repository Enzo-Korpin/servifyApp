import axios from "axios";

const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";

const MODELS = process.env.OPENROUTER_MODELS.split(",");

export default async function callOpenRouter(messages) {
  let lastError = null;

  for (const model of MODELS) {
    try {
      console.log(`Trying model: ${model}`);

      const response = await axios.post(
        OPENROUTER_API_URL,
        {
          model,
          messages,
        },
        {
          headers: {
            Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`,
            "Content-Type": "application/json",
          },
          timeout: 20000,
        }
      );

      console.log(`Success with model: ${model}`);

      return response.data;
    } catch (error) {
      console.error(
        `Model failed: ${model}`,
        error.response?.data || error.message
      );

      lastError = error;
    }
  }

  throw new Error("All AI models failed");
}

