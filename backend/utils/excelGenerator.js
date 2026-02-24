const ExcelJS = require("exceljs");

/**
 * Generates an Excel workbook for a worker's records.
 * @param {string} workerName 
 * @param {Array} records 
 * @returns {Promise<ExcelJS.Workbook>}
 */
async function generateWorkerExcel(workerName, records) {
    const workbook = new ExcelJS.Workbook();
    workbook.creator = "Worker Monitor";
    const sheet = workbook.addWorksheet("Monitoring Records");

    sheet.columns = [
        { header: "Date", key: "date", width: 20 },
        { header: "Wind Speed (m/s)", key: "windSpeed", width: 18 },
        { header: "Black Ball Temp (°C)", key: "blackBallTemp", width: 22 },
        { header: "Ambient Temp (°C)", key: "ambientTemp", width: 20 },
        { header: "Humidity (%)", key: "humidity", width: 15 },
        { header: "Activity", key: "activityIntensity", width: 15 },
        { header: "Pulse", key: "pulse", width: 12 },
        { header: "Clothing", key: "clothing", width: 15 },
        { header: "Duration (min)", key: "workDuration", width: 16 },
        { header: "Heat Stress Index", key: "heatStressIndex", width: 20 },
        { header: "Risk Level", key: "riskLevel", width: 14 },
    ];

    sheet.getRow(1).font = { bold: true, color: { argb: "FFFFFFFF" } };
    sheet.getRow(1).fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "FF1565C0" },
    };

    for (const r of records) {
        sheet.addRow({
            date: r.createdAt
                ? new Date(r.createdAt).toISOString().replace("T", " ").substring(0, 19)
                : "",
            windSpeed: r.windSpeed,
            blackBallTemp: r.blackBallTemp,
            ambientTemp: r.ambientTemp,
            humidity: r.humidity,
            activityIntensity: r.activityIntensity,
            pulse: r.pulse,
            clothing: r.clothing,
            workDuration: r.workDuration,
            heatStressIndex: r.heatStressIndex,
            riskLevel: r.riskLevel,
        });
    }

    return workbook;
}

module.exports = { generateWorkerExcel };
