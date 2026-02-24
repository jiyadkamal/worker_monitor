const mongoose = require("mongoose");

const monitoringRecordSchema = new mongoose.Schema({
    supervisorId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Supervisor",
        required: true,
    },
    workerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Worker",
        required: true,
    },
    windSpeed: { type: Number, required: true },
    blackBallTemp: { type: Number, required: true },
    ambientTemp: { type: Number, required: true },
    humidity: { type: Number, required: true },
    activityIntensity: { type: String, required: true },
    pulse: { type: String, required: true },
    clothing: { type: String, required: true },
    workDuration: { type: Number, required: true },
    heatStressIndex: { type: Number, required: true },
    riskLevel: { type: String, required: true },
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

module.exports = mongoose.model("MonitoringRecord", monitoringRecordSchema);
