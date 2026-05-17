let ioInstance = null;

export const setSocketIO = (io) => {
  ioInstance = io;
};

export const getSocketIO = () => ioInstance;

export const userRoom = (userId) => `user:${userId}`;
export const chatRoom = (chatId) => `chat:${chatId}`;

export const emitNewMessage = (message) => {
  if (!ioInstance || !message) return;

  const payload = {
    success: true,
    data: message,
    error: null,
  };

  const chatId = String(message.chatId);
  const senderId = String(message.senderId);
  const receiverId = String(message.receiverId);

  ioInstance
    .to(chatRoom(chatId))
    .to(userRoom(senderId))
    .to(userRoom(receiverId))
    .emit("new_message", payload);
};
