import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/monitoring_record.dart';

class EmailService {
  // Gmail credentials — same as the backend .env had
  static const String _gmailUser = 'jiyadkamal1@gmail.com';
  static const String _gmailPass = 'lnmb uqug kptb lmsq';

  /// Send a monitoring record email to a worker.
  /// Fire-and-forget — errors are logged but not thrown.
  static Future<void> sendRecordEmail(
    String workerEmail,
    String workerName,
    MonitoringRecord record, {
    String? excelFilePath,
  }) async {
    try {
      final smtpServer = gmail(_gmailUser, _gmailPass);

      final riskColors = {
        'Low': '#4CAF50',
        'Moderate': '#FF9800',
        'High': '#FF5722',
        'Extreme': '#F44336',
      };
      final riskColor = riskColors[record.riskLevel] ?? '#9E9E9E';

      final html = '''
      <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: linear-gradient(135deg, #1565C0, #1976D2); padding: 24px; border-radius: 12px 12px 0 0;">
          <h2 style="color: white; margin: 0;">🌡️ Heat Stress Monitoring Report</h2>
          <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0;">Hello $workerName,</p>
        </div>
        <div style="background: #fff; padding: 24px; border: 1px solid #e0e0e0;">
          <div style="background: ${riskColor}15; border-left: 4px solid $riskColor; padding: 12px 16px; border-radius: 4px; margin-bottom: 20px;">
            <strong style="color: $riskColor; font-size: 18px;">Risk Level: ${record.riskLevel}</strong><br/>
            <span style="color: #555;">Heat Stress Index: <strong>${record.heatStressIndex}</strong></span>
          </div>
          <table style="width: 100%; border-collapse: collapse;">
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 8px 0; color: #666;">Ambient Temp</td>
              <td style="padding: 8px 0; text-align: right; font-weight: 600;">${record.ambientTemp}°C</td>
            </tr>
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 8px 0; color: #666;">Black Ball Temp</td>
              <td style="padding: 8px 0; text-align: right; font-weight: 600;">${record.blackBallTemp}°C</td>
            </tr>
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 8px 0; color: #666;">Humidity</td>
              <td style="padding: 8px 0; text-align: right; font-weight: 600;">${record.humidity}%</td>
            </tr>
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 8px 0; color: #666;">Wind Speed</td>
              <td style="padding: 8px 0; text-align: right; font-weight: 600;">${record.windSpeed} m/s</td>
            </tr>
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 8px 0; color: #666;">Activity Intensity</td>
              <td style="padding: 8px 0; text-align: right; font-weight: 600;">${record.activityIntensity}</td>
            </tr>
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 8px 0; color: #666;">Pulse</td>
              <td style="padding: 8px 0; text-align: right; font-weight: 600;">${record.pulse}</td>
            </tr>
            <tr style="border-bottom: 1px solid #eee;">
              <td style="padding: 8px 0; color: #666;">Clothing</td>
              <td style="padding: 8px 0; text-align: right; font-weight: 600;">${record.clothing}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #666;">Work Duration</td>
              <td style="padding: 8px 0; text-align: right; font-weight: 600;">${record.workDuration} min</td>
            </tr>
          </table>
        </div>
        <div style="background: #f5f5f5; padding: 16px; border-radius: 0 0 12px 12px; text-align: center; border: 1px solid #e0e0e0; border-top: none;">
          <p style="color: #888; margin: 0; font-size: 13px;">Worker Monitor App — Automated Report</p>
        </div>
      </div>
      ''';

      final message = Message()
        ..from = Address(_gmailUser, 'Worker Monitor')
        ..recipients.add(workerEmail)
        ..subject = '⚠️ Heat Stress Report — Risk: ${record.riskLevel}'
        ..html = html;

      if (excelFilePath != null) {
        message.attachments.add(FileAttachment(
          File(excelFilePath),
          contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ));
      }

      await send(message, smtpServer);
      debugPrint('✅ 📧 Email successfully sent to $workerEmail');
    } catch (e) {
      debugPrint('❌ 📧 Email delivery failed for $workerEmail: $e');
    }
  }
}
