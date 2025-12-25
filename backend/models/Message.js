const mongoose = require("mongoose");

const messageSchema = new mongoose.Schema({
    chatId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Chat",
        required: true
    },
    senderId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    type: {
        type: String,
        enum: ["text", "image"],
        default: "text"
    },
    imageURL: {
        type: String,
        default: null
    },
    voiceURl: {
        type: String,
        default: null
    }
}, { timestamps: true });

const Message = mongoose.model("Message", messageSchema);
module.exports = Message;