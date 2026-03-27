import { sendChatMessage, getConversationMessages} from "./ai.service.js";
import AiConversation from "./aiConversation.model.js";

export async function sendMessage(req, res) {
  try {
    const userId = req.user._id || req.user.id;
    const { conversationId, message } = req.body;

    const result = await sendChatMessage({
      userId,
      conversationId,
      message,
    });

    return res.status(200).json(result);
  } catch (error) {
    const statusCode =
      error.message === "Invalid conversationId"
        ? 400
        : error.message === "Conversation not found"
        ? 404
        : 500;

    return res.status(statusCode).json({
      message: error.message,
    });
  }
}

export async function getMessages(req, res) {
  try {
    const userId = req.user._id || req.user.id;
    const { conversationId } = req.params;

    const result = await getConversationMessages({
      conversationId,
      userId,
    });

    return res.status(200).json(result);
  } catch (error) {
    const statusCode =
      error.message === "Invalid conversationId"
        ? 400
        : error.message === "Conversation not found"
        ? 404
        : 500;

    return res.status(statusCode).json({
      message: error.message,
    });
  }
  
}
export async function getUserConversations(req, res) {
  try {
    const userId = req.user._id || req.user.id;

    const conversations = await AiConversation.find({ userId })
      .sort({ updatedAt: -1 })
      .select("_id title updatedAt");

    res.json(conversations);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
}