import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/worker.dart';
import '../providers/record_provider.dart';

class AddRecordScreen extends ConsumerStatefulWidget {
  final Worker worker;

  const AddRecordScreen({super.key, required this.worker});

  @override
  ConsumerState<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends ConsumerState<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _windSpeedCtrl = TextEditingController();
  final _blackBallCtrl = TextEditingController();
  final _ambientCtrl = TextEditingController();
  final _humidityCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  String _activity = 'Low';
  String _clothing = 'Light';
  bool _saving = false;

  @override
  void dispose() {
    _windSpeedCtrl.dispose();
    _blackBallCtrl.dispose();
    _ambientCtrl.dispose();
    _humidityCtrl.dispose();
    _pulseCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  /// Simple WBGT-inspired heat stress index calculation
  double _calculateHeatStress() {
    final bb = double.tryParse(_blackBallCtrl.text) ?? 0;
    final at = double.tryParse(_ambientCtrl.text) ?? 0;
    final hm = double.tryParse(_humidityCtrl.text) ?? 0;
    // Simplified WBGT approximation
    return double.parse(
        (0.7 * (at + (hm / 100) * 5) + 0.2 * bb + 0.1 * at).toStringAsFixed(1));
  }

  String _calculateRisk(double hsi) {
    if (hsi < 25) return 'Low';
    if (hsi < 30) return 'Moderate';
    if (hsi < 35) return 'High';
    return 'Extreme';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final hsi = _calculateHeatStress();
    final risk = _calculateRisk(hsi);

    setState(() => _saving = true);

    final data = {
      'workerId': widget.worker.id,
      'windSpeed': double.parse(_windSpeedCtrl.text.trim()),
      'blackBallTemp': double.parse(_blackBallCtrl.text.trim()),
      'ambientTemp': double.parse(_ambientCtrl.text.trim()),
      'humidity': double.parse(_humidityCtrl.text.trim()),
      'activityIntensity': _activity,
      'pulse': _pulseCtrl.text.trim(),
      'clothing': _clothing,
      'workDuration': double.parse(_durationCtrl.text.trim()),
      'heatStressIndex': hsi,
      'riskLevel': risk,
    };

    final ok = await ref.read(recordProvider.notifier).addRecord(data);

    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Record saved — Risk: $risk'),
          backgroundColor: _riskColor(risk),
        ));
        Navigator.pop(context, true);
      } else {
        final err = ref.read(recordProvider).error;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err ?? 'Error')));
      }
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

  String? _numValidator(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (double.tryParse(v) == null) return 'Enter a number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Record'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Worker chip
              Card(
                child: ListTile(
                  leading: Icon(Icons.person,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(widget.worker.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Monitoring for this worker'),
                ),
              ),
              const SizedBox(height: 16),

              // ── Environment ───────────────────────
              Text('Environment',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _windSpeedCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Wind Speed (m/s)',
                  prefixIcon: Icon(Icons.air),
                ),
                validator: _numValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _blackBallCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Black Ball Temp (°C)',
                  prefixIcon: Icon(Icons.thermostat),
                ),
                validator: _numValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ambientCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Ambient Temp (°C)',
                  prefixIcon: Icon(Icons.device_thermostat),
                ),
                validator: _numValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _humidityCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Humidity (%)',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                ),
                validator: _numValidator,
              ),
              const SizedBox(height: 24),

              // ── Worker metrics ────────────────────
              Text('Worker Metrics',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _activity,
                decoration: const InputDecoration(
                  labelText: 'Activity Intensity',
                  prefixIcon: Icon(Icons.directions_run),
                ),
                items: ['Low', 'Moderate', 'High', 'Very High']
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) => setState(() => _activity = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pulseCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pulse (bpm)',
                  prefixIcon: Icon(Icons.favorite_outline),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _clothing,
                decoration: const InputDecoration(
                  labelText: 'Clothing',
                  prefixIcon: Icon(Icons.checkroom),
                ),
                items: [
                  'Light',
                  'Normal',
                  'Heavy',
                  'Impermeable',
                ]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _clothing = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Work Duration (min)',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                validator: _numValidator,
              ),
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
