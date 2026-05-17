import jwt from "jsonwebtoken";
import mongoose from "mongoose";
import { Server } from "socket.io";

import User from "../models/user.js";
import Chat from "../models/Chat.js";
import { createMessage } from "../service/messageService.js";
import { sendMessageValidator } from "../validators/sendMessageValidator.js";
import { setSocketIO, userRoom, chatRoom, emitNewMessage } from "./socketEmitter.js";

const parseCookies = (cookieHeader = "") => {
  return cookieHeader.split(";").reduce((cookies, cookiePart) => {
    const [rawName, ...rawValueParts] = cookiePart.trim().split("=");
    if (!rawName || rawValueParts.length === 0) return cookies;

    const rawValue = rawValueParts.join("=");
    cookies[rawName] = decodeURIComponent(rawValue);
    return cookies;
  }, {});
};

const extractTokenFromSocket = (socket) => {
  const authToken = socket.handshake.auth?.token;
  if (authToken) return authToken;

  const cookies = parseCookies(socket.handshake.headers?.cookie);
  if (cookies.token) return cookies.token;

  const authHeader = socket.handshake.headers?.authorization;
  if (authHeader?.startsWith("Bearer ")) return authHeader.split(" ")[1];

  return null;
};

const authenticateSocket = async (socket, next) => {
  try {
    const token = extractTokenFromSocket(socket);
    console.log("DEBUG authenticateSocket: Extracted token:", token ? `${token.substring(0, 30)}...` : "NULL");

    if (!token) {
      const error = new Error("Unauthorized - No Token Provided");
      error.code = "NO_TOKEN";
      return next(error);
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log("DEBUG authenticateSocket: Token decoded, userId:", decoded.userId);

    const user = await User.findById(decoded.userId)
      .select("_id fullName image role currentRole onboardingStatus")
      .lean();

    if (!user) {
      const error = new Error("Unauthorized - User Not Found");
      error.code = "USER_NOT_FOUND";
      console.log("DEBUG authenticateSocket: User not found for userId:", decoded.userId);
      return next(error);
    }

    console.log("DEBUG authenticateSocket: SUCCESS - Authenticated as user:", user._id, user.fullName);
    socket.user = user;
    next();
  } catch (error) {
    console.log("DEBUG authenticateSocket: ERROR -", error.message);
    const authError = new Error("Unauthorized - Invalid or Expired Token");
    authError.code = "INVALID_TOKEN";
    next(authError);
  }
};

const ensureOnboardingComplete = (socket) => {
  if (socket.user?.onboardingStatus && socket.user.onboardingStatus !== "complete") {
    const error = new Error("Complete your onboarding first");
    error.code = "ONBOARDING_REQUIRED";
    throw error;
  }
};

const normalizeObjectId = (value) => {
  if (typeof value === "object" && value !== null) {
    value = value.chatId ?? value.receiverId ?? value.userId ?? value.id;
  }

  const id = String(value ?? "").trim();
  return mongoose.Types.ObjectId.isValid(id) ? id : null;
};

const socketErrorPayload = (error, fallbackCode = "SOCKET_ERROR") => ({
  success: false,
  data: null,
  error: {
    code: error?.code || fallbackCode,
    message: error?.message || "Socket operation failed",
    details: error?.details || null,
  },
});

const fail = (socket, eventName, ack, error, fallbackCode) => {
  const payload = socketErrorPayload(error, fallbackCode);

  if (typeof ack === "function") {
    ack(payload);
  }

  socket.emit(eventName, payload);
};

const findAuthorizedChat = async (chatId, userId) => {
  return Chat.findOne({
    _id: chatId,
    $or: [{ customerId: userId }, { workerId: userId }],
  })
    .select("_id customerId workerId")
    .lean();
};

const onlineUsers = new Map();

const markUserOnline = (userId, socketId) => {
  const socketIds = onlineUsers.get(userId) ?? new Set();
  const wasOffline = socketIds.size === 0;

  socketIds.add(socketId);
  onlineUsers.set(userId, socketIds);

  return wasOffline;
};

const markUserOffline = (userId, socketId) => {
  const socketIds = onlineUsers.get(userId);
  if (!socketIds) return false;

  socketIds.delete(socketId);

  if (socketIds.size === 0) {
    onlineUsers.delete(userId);
    return true;
  }

  return false;
};

export const initSocket = (httpServer, options = {}) => {
  const io = new Server(httpServer, {
    cors: options.cors ?? {
      origin: true,
      credentials: true,
    },
    pingTimeout: 60_000,
    serveClient: false,
  });

  setSocketIO(io);
  io.use(authenticateSocket);

  io.on("connection", (socket) => {
    const currentUserId = String(socket.user._id);
    console.log(`\n=== NEW SOCKET CONNECTION ===`);
    console.log(`Socket ID: ${socket.id}`);
    console.log(`User ID: ${currentUserId}`);
    console.log(`User Name: ${socket.user.fullName}`);
    console.log(`Role: ${socket.user.currentRole || socket.user.role}`);
    console.log(`=============================\n`);

    socket.join(userRoom(currentUserId));

    if (markUserOnline(currentUserId, socket.id)) {
      socket.broadcast.emit("user_online", { userId: currentUserId });
    }

    socket.on("join_chat", async (payload, ack) => {
      try {
        ensureOnboardingComplete(socket);

        const chatId = normalizeObjectId(payload);
        if (!chatId) {
          const error = new Error("Invalid chatId");
          error.code = "INVALID_CHAT_ID";
          throw error;
        }

        const chat = await findAuthorizedChat(chatId, currentUserId);
        if (!chat) {
          const error = new Error("Chat not found or not allowed");
          error.code = "CHAT_NOT_FOUND_OR_FORBIDDEN";
          throw error;
        }

        socket.join(chatRoom(chatId));

        if (typeof ack === "function") {
          ack({ success: true, data: { chatId }, error: null });
        }
      } catch (error) {
        fail(socket, "chat_error", ack, error, "JOIN_CHAT_FAILED");
      }
    });

    socket.on("leave_chat", (payload, ack) => {
      const chatId = normalizeObjectId(payload);

      if (chatId) {
        socket.leave(chatRoom(chatId));
      }

      if (typeof ack === "function") {
        ack({ success: true, data: { chatId }, error: null });
      }
    });

    socket.on("send_message", async (payload = {}, ack) => {
      try {
        ensureOnboardingComplete(socket);

        console.log("DEBUG socket send_message received payload:", payload);
        console.log("DEBUG socket currentUserId:", currentUserId);
        console.log("DEBUG socket.user._id:", socket.user._id);

        const receiverId = normalizeObjectId(payload.receiverId ?? payload.to ?? payload.userId ?? payload.id);
        console.log("DEBUG normalized receiverId:", receiverId);

        if (!receiverId) {
          const error = new Error("Invalid receiverId");
          error.code = "INVALID_RECEIVER_ID";
          throw error;
        }

        const { error: validationError, value } = sendMessageValidator(
          {
            text: payload.text,
            image: payload.image,
          },
          {
            abortEarly: false,
            stripUnknown: true,
            convert: true,
          },
        );

        if (validationError) {
          const error = new Error("Invalid message payload");
          error.code = "INVALID_MESSAGE_PAYLOAD";
          error.details = validationError.details.map((detail) => detail.message.replace(/[']/g, ""));
          throw error;
        }

        const normalizedSenderId = normalizeObjectId(currentUserId);
        console.log("DEBUG normalized senderId:", normalizedSenderId);
        if (String(normalizedSenderId) === String(receiverId)) {
          const error = new Error("Cannot send message to yourself");
          error.code = "SELF_MESSAGE_NOT_ALLOWED";
          throw error;
        }
        const message = await createMessage({
          senderId: normalizedSenderId,
          receiverId,
          text: value.text,
          image: value.image,
        });

        emitNewMessage(message);

        if (typeof ack === "function") {
          ack({ success: true, data: message, error: null });
        }
      } catch (error) {
        fail(socket, "message_error", ack, error, "SEND_MESSAGE_FAILED");
      }
    });

    socket.on("typing_start", async (payload = {}) => {
      try {
        const chatId = normalizeObjectId(payload.chatId ?? payload);
        if (!chatId) return;

        const chat = await findAuthorizedChat(chatId, currentUserId);
        if (!chat) return;

        socket.to(chatRoom(chatId)).emit("typing_start", {
          chatId,
          userId: currentUserId,
        });
      } catch {
        // Typing events are non-critical; do not crash the socket for them.
      }
    });

    socket.on("typing_stop", async (payload = {}) => {
      try {
        const chatId = normalizeObjectId(payload.chatId ?? payload);
        if (!chatId) return;

        const chat = await findAuthorizedChat(chatId, currentUserId);
        if (!chat) return;

        socket.to(chatRoom(chatId)).emit("typing_stop", {
          chatId,
          userId: currentUserId,
        });
      } catch {
        // Typing events are non-critical; do not crash the socket for them.
      }
    });

    socket.on("disconnect", () => {
      if (markUserOffline(currentUserId, socket.id)) {
        socket.broadcast.emit("user_offline", { userId: currentUserId });
      }
    });
  });

  return io;
};
