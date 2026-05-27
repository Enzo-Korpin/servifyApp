import mongoose from "mongoose";

import User from "../models/user.js";
import Chat from "../models/Chat.js";
import Message from "../models/Message.js";
import cloudinary from "../lib/cloudinary.js";
import { emitNewMessage } from "../lib/socketEmitter.js";
import { asyncHandler } from "../middleware/asyncHandler.js";
import {
  BadRequestError,
  ForbiddenError,
  NotFoundError,
  PayloadTooLargeError,
} from "../errors/httpErrors.js";

const MAX_IMAGE_BYTES = 3 * 1024 * 1024; // 3MB
const MAX_BASE64_LENGTH = Math.ceil((MAX_IMAGE_BYTES * 4) / 3);

const assertValidObjectId = (id, message, code) => {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new BadRequestError(message, code);
  }
};

const findChatBetweenUsers = async (senderId, receiverId) => {
  // Ensure both are proper ObjectIds for comparison
  const senderObjId = new mongoose.Types.ObjectId(senderId);
  const receiverObjId = new mongoose.Types.ObjectId(receiverId);
  
  return await Chat.findOne({
    $or: [
      { 
        customerId: senderObjId,
        workerId: receiverObjId
      },
      { 
        customerId: receiverObjId,
        workerId: senderObjId
      },
    ],
  }).select("_id");
};

const uploadMessageImage = async (image) => {
  if (!image) return null;

  if (image.length > MAX_BASE64_LENGTH) {
    throw new PayloadTooLargeError("Image too large", "IMAGE_TOO_LARGE");
  }

  try {
    const uploadResponse = await cloudinary.uploader.upload(image, {
      folder: "chat",
      resource_type: "image",
      allowed_formats: ["jpg", "jpeg", "png", "webp"],
      timeout: 60000,
    });

    if (!uploadResponse || !uploadResponse.secure_url) {
      throw new Error("No URL returned from Cloudinary");
    }

    return uploadResponse.secure_url;
  } catch (error) {
    const message = error.message || "Failed to upload image to Cloudinary";
    throw new PayloadTooLargeError(message, "IMAGE_UPLOAD_FAILED");
  }
};

export const createMessage = async ({ senderId, receiverId, text, image }) => {

  assertValidObjectId(senderId, "Invalid senderId", "INVALID_SENDER_ID");
  assertValidObjectId(receiverId, "Invalid receiverId", "INVALID_RECEIVER_ID");

  if (String(senderId) === String(receiverId)) {
    throw new BadRequestError("Cannot message yourself", "CANNOT_MESSAGE_SELF");
  }

  const existsUser = await User.exists({ _id: receiverId });

  if (!existsUser) {
    throw new NotFoundError("Receiver user not found", "RECEIVER_NOT_FOUND");
  }

  const chat = await findChatBetweenUsers(senderId, receiverId);

  if (!chat) {
    throw new ForbiddenError(
      "No chat exists between these users",
      "NO_CHAT_FOR_USERS",
    );
  }

  const imageUrl = await uploadMessageImage(image);

  const newMessage = await Message.create({
    chatId: chat._id,
    senderId,
    receiverId,
    text: text?.trim() || null,
    imageURL: imageUrl,
  });

  await Chat.updateOne({ _id: chat._id }, { $set: { updatedAt: new Date() } });

  return newMessage.toObject();
};

/**
 * GET /api/message/users
 *
 * Returns chat partners ordered by most-recent activity. Used by the sidebar
 * in the Flutter messaging tab.
 *
 * Pagination:
 *  - ?limit (default 30, hard-capped at 50) → page size
 *  - ?before (cursor "<updatedAt>|<chatId>") → next page
 *  - Response includes a top-level `nextCursor` (null when no more pages)
 *
 * Backward-compatibility: callers that don't pass cursor params get the most
 * recent `limit` chats — exactly the same `data: [...]` shape as before, just
 * size-bounded. Old Flutter builds that read response.data continue to work
 * unchanged; new builds can opt in to scroll by reading `nextCursor`.
 *
 * Query plan:
 *  - $or branches hit { customerId:1, updatedAt:-1 } and { workerId:1, updatedAt:-1 }
 *    indexes (defined on the Chat model). MongoDB's index union picks both up.
 *  - Cursor filter `(updatedAt < cur)` keeps the same index usable, so a user
 *    with 5,000 chats still pages in O(limit) work per call instead of O(N).
 */
export const getUsersForSidebar = asyncHandler(async (req, res) => {
  const myId = req.user._id;

  const limit = Math.min(parseInt(req.query.limit || "30", 10), 50);
  const before = req.query.before;

  const chatFilter = {
    $or: [{ customerId: myId }, { workerId: myId }],
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

    // Compound keyset cursor: stable even when many chats share updatedAt.
    chatFilter.$and = [
      {
        $or: [
          { updatedAt: { $lt: beforeDate } },
          { updatedAt: beforeDate, _id: { $lt: beforeId } },
        ],
      },
    ];
  }

  const chats = await Chat.find(chatFilter)
    .select("customerId workerId updatedAt")
    .sort({ updatedAt: -1, _id: -1 })
    .limit(limit)
    .lean();

  if (chats.length === 0) {
    return res
      .status(200)
      .json({ success: true, data: [], nextCursor: null, error: null });
  }

  const otherUserIds = chats.map((chat) =>
    String(chat.customerId) === String(myId) ? chat.workerId : chat.customerId,
  );

  const users = await User.find({ _id: { $in: otherUserIds } })
    .select("_id fullName image role currentRole")
    .lean();

  // chats[] is already in the desired order — preserve it instead of sorting
  // the user list separately. Filter Boolean handles the rare case where the
  // other user has been deleted (User.find skips them but the chat row remains).
  const userMap = new Map(users.map((u) => [String(u._id), u]));
  const orderedUsers = chats
    .map((chat) => {
      const otherId =
        String(chat.customerId) === String(myId)
          ? String(chat.workerId)
          : String(chat.customerId);
      return userMap.get(otherId);
    })
    .filter(Boolean);

  // Only emit a cursor when we filled the page — fewer than `limit` means
  // there's nothing left to fetch.
  const last = chats[chats.length - 1];
  const nextCursor =
    chats.length === limit ? `${last.updatedAt.toISOString()}|${last._id}` : null;

  return res
    .status(200)
    .json({ success: true, data: orderedUsers, nextCursor, error: null });
});

export const getMessages = asyncHandler(async (req, res) => {
  const { id: userToChatId } = req.params;
  const myId = req.user._id;

  assertValidObjectId(userToChatId, "Invalid user ID", "INVALID_USER_ID");

  const limit = Math.min(parseInt(req.query.limit || "10", 10), 10);
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
    .limit(limit)
    .lean();

  const messages = docs.reverse();

  const nextCursor = messages.length > 0
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

  const newMessage = await createMessage({
    senderId,
    receiverId,
    text,
    image,
  });

  emitNewMessage(newMessage);

  return res.status(201).json({ success: true, data: newMessage, error: null });
});
