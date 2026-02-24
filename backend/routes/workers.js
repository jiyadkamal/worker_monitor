const express = require("express");
const Worker = require("../models/Worker");
const auth = require("../middleware/auth");

const router = express.Router();

// All routes are protected
router.use(auth);

// GET /api/workers — list all workers (with optional search by name)
router.get("/", async (req, res) => {
    try {
        const { search } = req.query;
        const query = { supervisorId: req.user.id };

        if (search) {
            query.name = { $regex: search, $options: "i" };
        }

        const workers = await Worker.find(query).sort({ name: 1 });
        res.status(200).json(workers);
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});

// GET /api/workers/:id — get single worker
router.get("/:id", async (req, res) => {
    try {
        const worker = await Worker.findOne({
            _id: req.params.id,
            supervisorId: req.user.id,
        });

        if (!worker) {
            return res.status(404).json({ message: "Worker not found" });
        }

        res.status(200).json(worker);
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});

// POST /api/workers — add worker
router.post("/", async (req, res) => {
    try {
        const { name, email, gender, age, weight, height } = req.body;

        if (!name || !email || !gender || !age || !weight || !height) {
            return res.status(400).json({ message: "All fields are required" });
        }

        // Calculate BMI: weight(kg) / (height(m))^2
        const heightInMeters = height / 100;
        const bmi = parseFloat((weight / (heightInMeters * heightInMeters)).toFixed(1));

        const worker = new Worker({
            supervisorId: req.user.id,
            name,
            email,
            gender,
            age,
            weight,
            height,
            bmi,
        });

        await worker.save();
        res.status(201).json(worker);
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});

// PUT /api/workers/:id — edit worker
router.put("/:id", async (req, res) => {
    try {
        const { name, email, gender, age, weight, height } = req.body;

        // Recalculate BMI if weight or height changed
        let bmi;
        if (weight && height) {
            const heightInMeters = height / 100;
            bmi = parseFloat((weight / (heightInMeters * heightInMeters)).toFixed(1));
        }

        const updateData = { name, email, gender, age, weight, height };
        if (bmi !== undefined) updateData.bmi = bmi;

        const worker = await Worker.findOneAndUpdate(
            { _id: req.params.id, supervisorId: req.user.id },
            updateData,
            { new: true, runValidators: true }
        );

        if (!worker) {
            return res.status(404).json({ message: "Worker not found" });
        }

        res.status(200).json(worker);
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});

// DELETE /api/workers/:id — delete worker
router.delete("/:id", async (req, res) => {
    try {
        const worker = await Worker.findOneAndDelete({
            _id: req.params.id,
            supervisorId: req.user.id,
        });

        if (!worker) {
            return res.status(404).json({ message: "Worker not found" });
        }

        res.status(200).json({ message: "Worker deleted successfully" });
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});

module.exports = router;
