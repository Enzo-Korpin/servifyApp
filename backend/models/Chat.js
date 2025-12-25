const mongoose = require("mongoose");

const chatSchema = new mongoose.Schema({
    customerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    workerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    createdFromRequestId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "ServiceRequest",
        required: true
    },
}, { timestamps: true });

const Chat = mongoose.model("Chat", chatSchema);
module.exports = Chat;