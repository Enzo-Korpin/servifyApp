const mongoose = require("mongoose");

const workerProfileSchema = new mongoose.Schema({
    _id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User"
    },
    bio: {
        type: String,
        
    },
    yearsOfExperience: {
        type: Number,
        
    },
    rate: {
        type: Number,
        required: true
    },
    skills: [{
        type: [String],
        default: [],
        required: true
    }],
}, { timestamps: true });

const WorkerProfile = mongoose.model("WorkerProfile", workerProfileSchema);
module.exports = WorkerProfile;
