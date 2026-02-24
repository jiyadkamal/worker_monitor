const axios = require("axios");

/**
 * Generates a Heat Stress Index trend chart image using QuickChart.io.
 * returns image buffer.
 */
async function generateChartImage(records) {
    try {
        const labels = records
            .slice(0, 7) // Last 7 records
            .reverse()
            .map((r) =>
                r.createdAt
                    ? new Date(r.createdAt).toLocaleDateString([], { month: "short", day: "numeric" })
                    : ""
            );

        const data = records
            .slice(0, 7)
            .reverse()
            .map((r) => r.heatStressIndex);

        const chartConfig = {
            type: "line",
            data: {
                labels: labels,
                datasets: [
                    {
                        label: "Heat Stress Index",
                        data: data,
                        fill: true,
                        backgroundColor: "rgba(21, 101, 192, 0.1)",
                        borderColor: "#1565C0",
                        borderWidth: 3,
                        pointBackgroundColor: "#1565C0",
                        pointRadius: 4,
                        lineTension: 0.4,
                    },
                ],
            },
            options: {
                title: {
                    display: true,
                    text: "Heat Stress Trend (Last 7 Records)",
                },
                scales: {
                    yAxes: [
                        {
                            ticks: { min: 20, max: 100 },
                        },
                    ],
                },
            },
        };

        const response = await axios.post(
            "https://quickchart.io/chart",
            {
                chart: chartConfig,
                width: 600,
                height: 300,
                format: "png",
            },
            { responseType: "arraybuffer" }
        );

        return Buffer.from(response.data);
    } catch (err) {
        console.error("❌ Chart generation failed:", err.message);
        return null;
    }
}

module.exports = { generateChartImage };
