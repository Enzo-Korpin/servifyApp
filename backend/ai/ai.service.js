import mongoose from "mongoose";
import callOpenRouter from "./openrouter.js";
import {buildPromptFromHistory} from "./aiPrompt.service.js";
import AiMessage from "./aiMessage.model.js";
import AiConversation from "./aiConversation.model.js";

function normalizeAiOutput(parsed) {
  return {
    reply:
      typeof parsed.reply === "string" && parsed.reply.trim()
        ? parsed.reply.trim()
        : "I need a little more detail to help you properly.",

    category: [
      "plumbing",
      "electrical",
      "ac_repair",
      "painting",
      "carpentry",
      "appliance_repair",
      "cleaning",
      "general_maintenance",
      "unknown",
    ].includes(parsed.category)
      ? parsed.category
      : "unknown",

    workerType: [
      "plumber",
      "electrician",
      "ac_technician",
      "painter",
      "carpenter",
      "appliance_repair_technician",
      "cleaner",
      "handyman",
      "unknown",
    ].includes(parsed.workerType)
      ? parsed.workerType
      : "unknown",

    urgency: ["low", "medium", "high"].includes(parsed.urgency)
      ? parsed.urgency
      : "medium",

    canUserFix: ["yes", "limited", "no"].includes(parsed.canUserFix)
      ? parsed.canUserFix
      : "limited",

    steps: Array.isArray(parsed.steps)
      ? parsed.steps.filter((step) => typeof step === "string" && step.trim())
      : [],

    safetyNotes: Array.isArray(parsed.safetyNotes)
      ? parsed.safetyNotes.filter(
          (note) => typeof note === "string" && note.trim()
        )
      : [],

    needsMoreInfo:
      typeof parsed.needsMoreInfo === "boolean" ? parsed.needsMoreInfo : false,
  };
}

async function createConversationIfNeeded({ conversationId, userId, firstMessage }) {
  if (conversationId) {
    if (!mongoose.Types.ObjectId.isValid(conversationId)) {
      throw new Error("Invalid conversationId");
    }

    const existingConversation = await AiConversation.findOne({
      _id: conversationId,
      userId,
      status: "active",
    });

    if (!existingConversation) {
      throw new Error("Conversation not found");
    }

    return existingConversation;
  }

  let title = "New AI Chat";
  if (typeof firstMessage === "string" && firstMessage.trim()) {
    title = firstMessage.trim().slice(0, 60);
  }

  const newConversation = await AiConversation.create({
    userId,
    title,
  });

  return newConversation;
}

async function getRecentConversationMessages(conversationId, limit = 12) {
  const messages = await AiMessage.find({ conversationId })
    .sort({ createdAt: -1 })
    .limit(limit)
    .lean();

  return messages.reverse();
}

export async function sendChatMessage({ userId, conversationId, message }) {
  const trimmedMessage = message?.trim();

  if (!trimmedMessage) {
    throw new Error("Message is required");
  }

  const conversation = await createConversationIfNeeded({
    conversationId,
    userId,
    firstMessage: trimmedMessage,
  });

  await AiMessage.create({
    conversationId: conversation._id,
    userId,
    role: "user",
    content: trimmedMessage,
  });

  const history = await getRecentConversationMessages(conversation._id, 12);

  const promptMessages = buildPromptFromHistory(history);

  const aiResponse = await callOpenRouter(promptMessages);

  const rawContent = aiResponse?.choices?.[0]?.message?.content;

  if (!rawContent) {
    throw new Error("AI returned empty content");
  }

  let parsed;
  try {
    parsed = JSON.parse(rawContent);
  } catch (error) {
    throw new Error("AI returned invalid JSON");
  }

  const normalized = normalizeAiOutput(parsed);

  await AiMessage.create({
    conversationId: conversation._id,
    userId,
    role: "assistant",
    content: normalized.reply,
    category: normalized.category,
    workerType: normalized.workerType,
    urgency: normalized.urgency,
    canUserFix: normalized.canUserFix,
    steps: normalized.steps,
    safetyNotes: normalized.safetyNotes,
    needsMoreInfo: normalized.needsMoreInfo,
  });

  return {
    conversationId: conversation._id,
    reply: normalized.reply,
    category: normalized.category,
    workerType: normalized.workerType,
    urgency: normalized.urgency,
    canUserFix: normalized.canUserFix,
    steps: normalized.steps,
    safetyNotes: normalized.safetyNotes,
    needsMoreInfo: normalized.needsMoreInfo,
  };
}

export async function getConversationMessages({ conversationId, userId }) {
  if (!mongoose.Types.ObjectId.isValid(conversationId)) {
    throw new Error("Invalid conversationId");
  }

  const conversation = await AiConversation.findOne({
    _id: conversationId,
    userId,
  });

  if (!conversation) {
    throw new Error("Conversation not found");
  }

  const messages = await AiMessage.find({
    conversationId,
    userId,
  }).sort({ createdAt: 1 });

  return {
    conversationId: conversation._id,
    title: conversation.title,
    status: conversation.status,
    messages,
  };
}