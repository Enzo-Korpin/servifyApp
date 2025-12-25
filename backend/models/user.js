const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
    fullName: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    password: {
        type: String,
        required: true
    },
    role: {
        type: String,
        enum: ["customer", "worker"],
        default: "customer",
    },
    currentRole: {
        type: String,
        enum: ["customer", "worker"],
        default: "customer",
    },
    lat: {
        type: Number
    },
    lng: {
        type: Number
    },
    image: {
        type: String
    },
    isVerified: {
        type: Boolean,
        default: false
    },
    verificationCodeHash: {
        type: String
    },
    verificationCodeExpiry: {
        type: Date
    }
}, { timestamps: true });

const User = mongoose.model("User", userSchema);
module.exports = User;