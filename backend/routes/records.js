const express = require("express");
const MonitoringRecord = require("../models/MonitoringRecord");
const Worker = require("../models/Worker");
const auth = require("../middleware/auth");
const { sendRecordEmail } = require("../utils/mailer");
const { generateWorkerExcel } = require("../utils/excelGenerator");
const { generateChartImage } = require("../utils/chartGenerator");

const router = express.Router();

// All routes are protected
router.use(auth);

// POST /api/records — create monitoring record + send email with attachment & graph
router.post("/", async (req, res) => {
    try {
        const {
            workerId,
            windSpeed,
            blackBallTemp,
            ambientTemp,
            humidity,
            activityIntensity,
            pulse,
            clothing,
            workDuration,
            heatStressIndex,
            riskLevel,
        } = req.body;

        // Verify the worker belongs to this supervisor
        const worker = await Worker.findOne({
            _id: workerId,
            supervisorId: req.user.id,
        });

        if (!worker) {
            return res.status(404).json({ message: "Worker not found" });
        }

        const record = new MonitoringRecord({
            supervisorId: req.user.id,
            workerId,
            windSpeed,
            blackBallTemp,
            ambientTemp,
            humidity,
            activityIntensity,
            pulse,
            clothing,
            workDuration,
            heatStressIndex,
            riskLevel,
        });

        await record.save();

        // Send email notification with full history Excel & Graph attached
        if (worker.email) {
            const allRecords = await MonitoringRecord.find({ workerId }).sort({ createdAt: -1 });

            // Generate Excel history
            const workbook = await generateWorkerExcel(worker.name, allRecords);
            const excelBuffer = await workbook.xlsx.writeBuffer();

            // Generate Trend Chart Image
            const chartBuffer = await generateChartImage(allRecords);

            const attachments = [
                {
                    filename: `${worker.name.replace(/\s+/g, "_")}_history.xlsx`,
                    content: excelBuffer,
                },
            ];

            if (chartBuffer) {
                attachments.push({
                    filename: "trend-chart.png",
                    content: chartBuffer,
                    cid: "trendChart", // linked in HTML email body
                });
            }

            sendRecordEmail(worker.email, worker.name, record, attachments);
        }

        res.status(201).json(record);
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});

// GET /api/records/export/:workerId — download Excel
router.get("/export/:workerId", async (req, res) => {
    try {
        // Verify worker belongs to supervisor
        const worker = await Worker.findOne({
            _id: req.params.workerId,
            supervisorId: req.user.id,
        });

        if (!worker) {
            return res.status(404).json({ message: "Worker not found" });
        }

        const records = await MonitoringRecord.find({
            workerId: req.params.workerId,
            supervisorId: req.user.id,
        }).sort({ createdAt: -1 });

        const workbook = await generateWorkerExcel(worker.name, records);

        // Set response headers
        const filename = `${worker.name.replace(/\s+/g, "_")}_records.xlsx`;
        res.setHeader(
            "Content-Type",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        );
        res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);

        await workbook.xlsx.write(res);
        res.end();
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});

// GET /api/records — list records (optional filter by workerId)
router.get("/", async (req, res) => {
    try {
        const query = { supervisorId: req.user.id };

        if (req.query.workerId) {
            query.workerId = req.query.workerId;
        }

        const records = await MonitoringRecord.find(query)
            .populate("workerId", "name")
            .sort({ createdAt: -1 });

        res.status(200).json(records);
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});

// GET /api/records/:id — single record
router.get("/:id", async (req, res) => {
    try {
        const record = await MonitoringRecord.findOne({
            _id: req.params.id,
            supervisorId: req.user.id,
        }).populate("workerId", "name");

        if (!record) {
            return res.status(404).json({ message: "Record not found" });
        }

        res.status(200).json(record);
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});

module.exports = router;
