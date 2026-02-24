import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/worker.dart';
import '../providers/worker_provider.dart';
import '../providers/record_provider.dart';
import '../services/api_service.dart';
import 'add_edit_worker_screen.dart';
import 'add_record_screen.dart';

class WorkerDetailScreen extends ConsumerStatefulWidget {
  final Worker worker;

  const WorkerDetailScreen({super.key, required this.worker});

  @override
  ConsumerState<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends ConsumerState<WorkerDetailScreen> {
  bool _downloading = false;

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
        content:
            Text('Are you sure you want to delete ${widget.worker.name}?'),
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
    setState(() => _downloading = true);
    try {
      final bytes = await ApiService.downloadExcel(widget.worker.id!);
      final dir = await getApplicationDocumentsDirectory();
      final filename =
          '${widget.worker.name.replaceAll(' ', '_')}_records.xlsx';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved: $filename')),
        );
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'extreme':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordState = ref.watch(recordProvider);
    final cs = Theme.of(context).colorScheme;
    final w = widget.worker;
    final dateFmt = DateFormat('MMM d, yyyy  HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(w.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (_) => AddEditWorkerScreen(worker: w)),
              );
              if (result == true && mounted) {
                ref.read(workerProvider.notifier).fetchWorkers();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _deleteWorker,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => AddRecordScreen(worker: w)),
          );
          if (result == true) {
            ref
                .read(recordProvider.notifier)
                .fetchRecords(workerId: w.id);
          }
        },
        icon: const Icon(Icons.add_chart),
        label: const Text('Add Record'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Worker Info Card ─────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        w.name.isNotEmpty ? w.name[0].toUpperCase() : '?',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(w.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email_outlined,
                            size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(w.email,
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _infoChip(Icons.wc, w.gender),
                        _infoChip(Icons.cake, 'Age ${w.age}'),
                        _infoChip(Icons.monitor_weight, '${w.weight} kg'),
                        _infoChip(Icons.height, '${w.height} cm'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('BMI: ${w.bmi}',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.onTertiaryContainer)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Monitoring Graph ─────────────────
            if (recordState.records.isNotEmpty) ...[
              Text('Heat Stress Trend',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  height: 220,
                  padding: const EdgeInsets.fromLTRB(10, 24, 20, 10),
                  child: LineChart(
                    LineChartData(
                      clipData: const FlClipData.all(),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (spot) => cs.secondaryContainer,
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                            s.y.toString(),
                            TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.bold),
                          )).toList(),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calculateInterval(recordState.records),
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: cs.outlineVariant.withAlpha(80),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: _calculateInterval(recordState.records),
                            getTitlesWidget: (v, meta) => Text(
                              v.toInt().toString(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: cs.outline,
                              ),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: recordState.records.reversed
                              .toList()
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value.heatStressIndex))
                              .toList(),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 3,
                              color: cs.surface,
                              strokeWidth: 2,
                              strokeColor: cs.primary,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [cs.primary.withAlpha(50), cs.primary.withAlpha(0)],
                            ),
                          ),
                        ),
                      ],
                      minY: _calculateMinY(recordState.records),
                      maxY: _calculateMaxY(recordState.records),
                      minX: -0.2,
                      maxX: (recordState.records.length - 1).toDouble() + 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Monitoring History Header ────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monitoring History',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (recordState.records.isNotEmpty)
                  _downloading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton.icon(
                          onPressed: _downloadExcel,
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Excel'),
                        ),
              ],
            ),
            const SizedBox(height: 8),

            if (recordState.isLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else if (recordState.records.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.assessment_outlined,
                            size: 48, color: cs.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text('No records yet',
                            style:
                                TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...recordState.records.map((r) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _riskColor(r.riskLevel).withValues(alpha: 0.15),
                        child: Icon(Icons.thermostat,
                            color: _riskColor(r.riskLevel)),
                      ),
                      title: Text(
                        'Risk: ${r.riskLevel}',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _riskColor(r.riskLevel)),
                      ),
                      subtitle: Text(r.createdAt != null
                          ? dateFmt.format(r.createdAt!)
                          : ''),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            children: [
                              _detailRow('Heat Stress Index',
                                  r.heatStressIndex.toString()),
                              _detailRow(
                                  'Ambient Temp', '${r.ambientTemp}°C'),
                              _detailRow('Black Ball Temp',
                                  '${r.blackBallTemp}°C'),
                              _detailRow('Humidity', '${r.humidity}%'),
                              _detailRow(
                                  'Wind Speed', '${r.windSpeed} m/s'),
                              _detailRow('Activity', r.activityIntensity),
                              _detailRow('Pulse', r.pulse),
                              _detailRow('Clothing', r.clothing),
                              _detailRow(
                                  'Duration', '${r.workDuration} min'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Chart Helpers ──────────────────────────────────
  double _calculateInterval(List<dynamic> records) {
    if (records.isEmpty) return 10;
    final max = records.map((r) => r.heatStressIndex as double).reduce((a, b) => a > b ? a : b);
    final min = records.map((r) => r.heatStressIndex as double).reduce((a, b) => a < b ? a : b);
    final span = max - min;
    if (span < 10) return 2;
    if (span < 25) return 5;
    if (span < 50) return 10;
    return 20;
  }

  double _calculateMinY(List<dynamic> records) {
    if (records.isEmpty) return 0;
    final min = records.map((r) => r.heatStressIndex as double).reduce((a, b) => a < b ? a : b);
    final interval = _calculateInterval(records);
    return ((min - interval) / interval).floor() * interval;
  }

  double _calculateMaxY(List<dynamic> records) {
    if (records.isEmpty) return 100;
    final max = records.map((r) => r.heatStressIndex as double).reduce((a, b) => a > b ? a : b);
    final interval = _calculateInterval(records);
    return ((max + interval) / interval).ceil() * interval;
  }
}
