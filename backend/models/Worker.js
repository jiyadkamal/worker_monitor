const mongoose = require("mongoose");

const workerSchema = new mongoose.Schema({
    supervisorId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Supervisor",
        required: true,
    },
    name: {
        type: String,
        required: [true, "Name is required"],
        trim: true,
    },
    email: {
        type: String,
        required: [true, "Email is required"],
        trim: true,
        lowercase: true,
    },
    gender: {
        type: String,
        required: [true, "Gender is required"],
        enum: ["Male", "Female", "Other"],
    },
    age: {
        type: Number,
        required: [true, "Age is required"],
    },
    weight: {
        type: Number,
        required: [true, "Weight is required"],
    },
    height: {
        type: Number,
        required: [true, "Height is required"],
    },
    bmi: {
        type: Number,
        required: true,
    },
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

module.exports = mongoose.model("Worker", workerSchema);
