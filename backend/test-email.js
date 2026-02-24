const path = require("path");
require("dotenv").config({ path: path.join(__dirname, ".env") });
const nodemailer = require("nodemailer");

async function testGmail() {
    console.log("-----------------------------------------");
    console.log("Checking Gmail configuration...");
    console.log(`User: ${process.env.GMAIL_USER}`);
    console.log(`Pass: ${process.env.GMAIL_PASS ? "********" : "NOT SET"}`);
    console.log("-----------------------------------------");

    if (!process.env.GMAIL_USER || !process.env.GMAIL_PASS || process.env.GMAIL_USER.includes("your_email")) {
        console.error("❌ ERROR: Please update GMAIL_USER and GMAIL_PASS in your .env file first!");
        process.exit(1);
    }

    const transporter = nodemailer.createTransport({
        service: "gmail",
        auth: {
            user: process.env.GMAIL_USER,
            pass: process.env.GMAIL_PASS,
        },
    });

    try {
        console.log("⏳ Verifying connection to Gmail SMTP...");
        await transporter.verify();
        console.log("✅ SUCCESS: Connection verified! Your credentials are correct.");

        console.log(`⏳ Sending test email to ${process.env.GMAIL_USER}...`);
        await transporter.sendMail({
            from: `"Worker Monitor Test" <${process.env.GMAIL_USER}>`,
            to: process.env.GMAIL_USER,
            subject: "🚀 Gmail System Test",
            text: "If you are reading this, your Worker Monitor email system is working perfectly!",
            html: "<h3>🚀 Gmail System Test</h3><p>If you are reading this, your <b>Worker Monitor</b> email system is working perfectly!</p>",
        });
        console.log("✅ SUCCESS: Test email sent! Check your inbox.");

    } catch (err) {
        console.error("❌ FAILED: Could not send email.");
        console.error("-----------------------------------------");
        console.error(`Error Code: ${err.code || "N/A"}`);
        console.error(`Message: ${err.message}`);
        console.error("-----------------------------------------");
        console.error("TIPS:");
        console.error("1. Make sure 2-Step Verification is ON in your Google Account.");
        console.error("2. Make sure you are using a 16-character 'App Password', NOT your regular login password.");
        console.error("3. Check that GMAIL_USER matches your actual Gmail address.");
    }
}

testGmail();
