const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
require("dotenv").config();

const authRoutes = require("./routes/auth");
const workerRoutes = require("./routes/workers");
const recordRoutes = require("./routes/records");

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/workers", workerRoutes);
app.use("/api/records", recordRoutes);

// Health check
app.get("/", (req, res) => {
    res.json({ message: "Worker Monitor API is running" });
});

// MongoDB connection & server start
const MONGO_URI = process.env.MONGO_URI || "mongodb://127.0.0.1:27017/worker_monitor";
const PORT = process.env.PORT || 5000;

mongoose
    .connect(MONGO_URI)
    .then(() => {
        console.log("Connected to MongoDB");
        app.listen(PORT, () => {
            console.log(`Server running on port ${PORT}`);
        });
    })
    .catch((err) => {
        console.error("MongoDB connection error:", err.message);
    });
