import User from "../models/user.js";
import Chat from "../models/Chat.js";
import Message from "../models/message.js";
import cloudinary from "../lib/cloudinary.js";
import mongoose from "mongoose";
import { asyncHandler } from "../middleware/asyncHandler.js";
import {
  BadRequestError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  PayloadTooLargeError,
} from "../errors/httpErrors.js";

// import { getReceiverSocketId, io } from "../lib/socket.js";

export const getUsersForSidebar = asyncHandler(async (req, res) => {
  const myId = req.user._id;

  const chats = await Chat.find({
    $or: [{ customerId: myId }, { workerId: myId }],
  });

  if (!chats) {
    return res.status(200).json({ success: true, data: [], error: null });
  }

  const otherUserIds = [];
  for (const c of chats) {
    const otherId =
      String(c.customerId) === String(myId) ? c.workerId : c.customerId;

    if (otherId) otherUserIds.push(otherId);
  }

  const users = await User.find({ _id: { $in: otherUserIds } })
    .select("_id fullName image role currentRole")
    .lean();

  const chatOrder = new Map(
    chats
      .sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt))
      .map((c, idx) => {
        const otherId =
          String(c.customerId) === String(myId)
            ? String(c.workerId)
            : String(c.customerId);
        return [otherId, idx];
      }),
  );

  users.sort(
    (a, b) =>
      (chatOrder.get(String(a._id)) ?? 999999) -
      (chatOrder.get(String(b._id)) ?? 999999),
  );

  return res.status(200).json({ success: true, data: users, error: null });
});

export const getMessages = asyncHandler(async (req, res) => {
  const { id: userToChatId } = req.params;
  const myId = req.user._id;

  if (!mongoose.Types.ObjectId.isValid(userToChatId)) {
    throw new BadRequestError("Invalid user ID", "INVALID_USER_ID");
  }

  const limit = Math.min(parseInt(req.query.limit || "20", 10), 10);
  const before = req.query.before;

  const query = {
    $or: [
      { senderId: myId, receiverId: userToChatId },
      { senderId: userToChatId, receiverId: myId },
    ],
  };

  if (before) {
    const [beforeDateStr, beforeId] = String(before).split("|");
    const beforeDate = new Date(beforeDateStr);

    if (
      !beforeDateStr ||
      Number.isNaN(beforeDate.getTime()) ||
      !mongoose.Types.ObjectId.isValid(beforeId)
    ) {
      throw new BadRequestError(
        "Invalid 'before' cursor",
        "INVALID_BEFORE_CURSOR",
      );
    }

    query.$and = [
      {
        $or: [
          { createdAt: { $lt: beforeDate } },
          { createdAt: beforeDate, _id: { $lt: beforeId } },
        ],
      },
    ];
  }

  const docs = await Message.find(query)
    .sort({ createdAt: -1, _id: -1 })
    .limit(limit);

  const messages = docs.reverse();

  const nextCursor =
    messages.length > 0
      ? `${messages[0].createdAt.toISOString()}|${messages[0]._id}`
      : null;

  return res
    .status(200)
    .json({ success: true, data: { messages, nextCursor }, error: null });
});

export const sendMessage = asyncHandler(async (req, res) => {
  const { text, image } = req.body;
  const { id: receiverId } = req.params;
  const senderId = req.user._id;

  if (!mongoose.Types.ObjectId.isValid(receiverId)) {
    throw new BadRequestError("Invalid receiverId", "INVALID_RECEIVER_ID");
  }

  if (String(senderId) === String(receiverId)) {
    throw new BadRequestError("Cannot message yourself", "CANNOT_MESSAGE_SELF");
  }

  const existsUser = await User.exists({ _id: receiverId });
  if (!existsUser) {
    throw new NotFoundError("Receiver user not found", "RECEIVER_NOT_FOUND");
  }

  const chat = await Chat.findOne({
    $or: [
      { customerId: senderId, workerId: receiverId },
      { customerId: receiverId, workerId: senderId },
    ],
  }).select("_id");

  if (!chat) {
    throw new ForbiddenError(
      "No chat exists between these users",
      "NO_CHAT_FOR_USERS",
    );
  }

  let imageUrl;
  if (image) {
    const MAX_IMAGE_BYTES = 3 * 1024 * 1024; // 3MB
    const MAX_BASE64_LENGTH = Math.ceil((MAX_IMAGE_BYTES * 4) / 3);

    if (image.length > MAX_BASE64_LENGTH) {
      throw new PayloadTooLargeError("Image too large", "IMAGE_TOO_LARGE");
    }

    const uploadResponse = await cloudinary.uploader.upload(image, {
      folder: "chat",
      resource_type: "image",
      allowed_formats: ["jpg", "jpeg", "png", "webp"],
    });

    imageUrl = uploadResponse.secure_url;
  }

  const newMessage = await Message.create({
    chatId: chat._id,
    senderId,
    receiverId,
    text: text ?? null,
    image: imageUrl ?? null,
  });

  await Chat.updateOne({ _id: chat._id }, { $set: { updatedAt: new Date() } });

  return res.status(201).json({ success: true, data: newMessage, error: null });
});
