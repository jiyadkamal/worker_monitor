const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const Supervisor = require("../models/Supervisor");

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || "secretkey";

// POST /api/auth/register
router.post("/register", async (req, res) => {
    try {
        const { name, email, password } = req.body;

        if (!name || !email || !password) {
            return res.status(400).json({ message: "All fields are required" });
        }

        // Check if email already exists
        const existingSupervisor = await Supervisor.findOne({ email });
        if (existingSupervisor) {
            return res.status(400).json({ message: "Email already registered" });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        const supervisor = new Supervisor({
            name,
            email,
            password: hashedPassword,
        });

        await supervisor.save();

        // Generate token
        const token = jwt.sign({ id: supervisor._id }, JWT_SECRET, {
            expiresIn: "7d",
        });

        res.status(201).json({
            token,
            supervisor: {
                id: supervisor._id,
                name: supervisor.name,
                email: supervisor.email,
            },
        });
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});

// POST /api/auth/login
router.post("/login", async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ message: "All fields are required" });
        }

        // Find supervisor
        const supervisor = await Supervisor.findOne({ email });
        if (!supervisor) {
            return res.status(400).json({ message: "Invalid credentials" });
        }

        // Compare password
        const isMatch = await bcrypt.compare(password, supervisor.password);
        if (!isMatch) {
            return res.status(400).json({ message: "Invalid credentials" });
        }

        // Generate token
        const token = jwt.sign({ id: supervisor._id }, JWT_SECRET, {
            expiresIn: "7d",
        });

        res.status(200).json({
            token,
            supervisor: {
                id: supervisor._id,
                name: supervisor.name,
                email: supervisor.email,
            },
        });
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});

module.exports = router;
