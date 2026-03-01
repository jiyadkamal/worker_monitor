import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import '../models/worker.dart';
import '../models/monitoring_record.dart';
import '../providers/worker_provider.dart';
import '../providers/record_provider.dart';
import 'add_edit_worker_screen.dart';
import 'add_record_screen.dart';

class WorkerDetailScreen extends ConsumerStatefulWidget {
  final Worker worker;

  const WorkerDetailScreen({super.key, required this.worker});

  @override
  ConsumerState<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends ConsumerState<WorkerDetailScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(recordProvider.notifier)
        .fetchRecords(workerId: widget.worker.id));
  }

  Future<void> _deleteWorker() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Worker'),
        content: Text('Are you sure you want to delete ${widget.worker.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await ref
          .read(workerProvider.notifier)
          .deleteWorker(widget.worker.id!);
      if (mounted && ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Worker deleted')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _downloadExcel() async {
    try {
      final records = ref.read(recordProvider).records;
      if (records.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No records to export')),
          );
        }
        return;
      }

      final excel = xl.Excel.createExcel();
      final sheet = excel['Records'];

      // Headers
      final headers = [
        'Date', 'Wind Speed', 'Black Ball Temp', 'Ambient Temp',
        'Humidity', 'Activity', 'Pulse', 'Clothing',
        'Work Duration', 'Heat Stress Index', 'Risk Level',
      ];
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = xl.TextCellValue(headers[i]);
      }

      // Data rows
      for (var r = 0; r < records.length; r++) {
        final rec = records[r];
        final row = r + 1;
        final date = rec.createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(rec.createdAt!) : '';
        final values = [
          date, rec.windSpeed, rec.blackBallTemp, rec.ambientTemp,
          rec.humidity, rec.activityIntensity, rec.pulse, rec.clothing,
          rec.workDuration, rec.heatStressIndex, rec.riskLevel,
        ];
        for (var c = 0; c < values.length; c++) {
          final v = values[c];
          if (v is double) {
            sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row)).value = xl.DoubleCellValue(v);
          } else {
            sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row)).value = xl.TextCellValue(v.toString());
          }
        }
      }

      // Remove default Sheet1 if it exists
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Request storage permission for Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          await Permission.manageExternalStorage.request();
        }
      }

      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) throw Exception('Could not access storage');

      final filename = '${widget.worker.name.replaceAll(' ', '_')}_records_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${dir.path}/$filename');
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved: $filename')),
          );
          await OpenFilex.open(file.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordState = ref.watch(recordProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(widget.worker.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditWorkerScreen(worker: widget.worker),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Excel',
            onPressed: _downloadExcel,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _deleteWorker,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => AddRecordScreen(worker: widget.worker)),
          );
          if (result == true) {
            ref.read(recordProvider.notifier).fetchRecords(workerId: widget.worker.id);
          }
        },
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text('Add Reading'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(recordProvider.notifier).fetchRecords(workerId: widget.worker.id),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Card ──────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'avatar-${widget.worker.id}',
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: cs.primary.withValues(alpha: 0.1),
                          backgroundImage: (widget.worker.photoUrl != null && widget.worker.photoUrl!.isNotEmpty)
                              ? FileImage(File(widget.worker.photoUrl!))
                              : null,
                          child: (widget.worker.photoUrl == null || widget.worker.photoUrl!.isEmpty)
                              ? Text(
                                  widget.worker.name[0].toUpperCase(),
                                  style: TextStyle(fontSize: 28, color: cs.primary, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.worker.name, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${widget.worker.gender} • ${widget.worker.age} Years Old', style: TextStyle(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // ── Stats Row ────────────────────────────
              Row(
                children: [
                  Expanded(child: _buildStatCard('BMI', widget.worker.bmi.toStringAsFixed(1), Icons.monitor_weight_outlined, cs)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Height', '${widget.worker.height}cm', Icons.height_rounded, cs)),
                ],
              ),
              const SizedBox(height: 24),

              // ── Trend Chart ──────────────────────────
              Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Heat Stress Trend', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              if (recordState.records.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 24, 24, 12),
                    child: SizedBox(
                      height: 220,
                      child: LineChart(_buildChartData(recordState, cs)),
                    ),
                  ),
                )
              else
                _buildEmptyChart(cs),

              const SizedBox(height: 32),
              
              // ── History List ─────────────────────────
              Text('Recent Readings', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (recordState.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
              else if (recordState.records.isEmpty)
                Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text('No readings recorded yet.', style: TextStyle(color: cs.onSurfaceVariant))))
              else
                ...recordState.records.map((r) => _buildRecordItem(r, cs)),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: cs.primary, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(ColorScheme cs) {
    return Card(
      child: Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart_rounded, size: 48, color: cs.outlineVariant),
            const SizedBox(height: 8),
            Text('No trend data available', style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(MonitoringRecord r, ColorScheme cs) {
    final date = DateFormat('MMM dd, hh:mm a').format(r.createdAt ?? DateTime.now());
    final riskColor = _getRiskColor(r.riskLevel);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: CircleAvatar(
          backgroundColor: riskColor.withValues(alpha: 0.1),
          child: Icon(Icons.thermostat_rounded, color: riskColor, size: 20),
        ),
        title: Text('Index: ${r.heatStressIndex.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(date),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(r.riskLevel, style: TextStyle(color: riskColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _detailRow('Ambient Temp', '${r.ambientTemp}°C', cs),
                _detailRow('Humidity', '${r.humidity}%', cs),
                _detailRow('Activity', r.activityIntensity, cs),
                _detailRow('Work Duration', '${r.workDuration} min', cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Color _getRiskColor(String risk) {
    risk = risk.toLowerCase();
    if (risk.contains('high') || risk.contains('extreme')) return Colors.red;
    if (risk.contains('moderate')) return Colors.orange;
    return Colors.green;
  }

  LineChartData _buildChartData(RecordState recordState, ColorScheme cs) {
    final spots = recordState.records.reversed.toList().asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.heatStressIndex)).toList();
    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: cs.outlineVariant.withValues(alpha: 0.2), strokeWidth: 1, dashArray: [5, 5])),
      titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles(), bottomTitles: AxisTitles()),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
          barWidth: 4,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [cs.primary.withValues(alpha: 0.2), cs.primary.withValues(alpha: 0)])),
        ),
      ],
      minY: _calculateMinY(recordState.records),
      maxY: _calculateMaxY(recordState.records),
      minX: -0.2,
      maxX: (recordState.records.length - 1).toDouble() + 0.2,
    );
  }

  double _calculateInterval(List<MonitoringRecord> records) {
    if (records.isEmpty) return 10;
    final max = records.map((r) => r.heatStressIndex).reduce((a, b) => a > b ? a : b);
    final min = records.map((r) => r.heatStressIndex).reduce((a, b) => a < b ? a : b);
    final span = max - min;
    if (span < 10) return 2;
    if (span < 25) return 5;
    if (span < 50) return 10;
    return 20;
  }

  double _calculateMinY(List<MonitoringRecord> records) {
    if (records.isEmpty) return 0;
    final min = records.map((r) => r.heatStressIndex).reduce((a, b) => a < b ? a : b);
    final interval = _calculateInterval(records);
    return ((min - interval) / interval).floor() * interval;
  }

  double _calculateMaxY(List<MonitoringRecord> records) {
    if (records.isEmpty) return 100;
    final max = records.map((r) => r.heatStressIndex).reduce((a, b) => a > b ? a : b);
    final interval = _calculateInterval(records);
    return ((max + interval) / interval).ceil() * interval;
  }
}
