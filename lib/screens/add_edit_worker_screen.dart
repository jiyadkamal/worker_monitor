import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/worker.dart';
import '../providers/worker_provider.dart';

class AddEditWorkerScreen extends ConsumerStatefulWidget {
  final Worker? worker; // null = add, non-null = edit

  const AddEditWorkerScreen({super.key, this.worker});

  @override
  ConsumerState<AddEditWorkerScreen> createState() =>
      _AddEditWorkerScreenState();
}

class _AddEditWorkerScreenState extends ConsumerState<AddEditWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  String _gender = 'Male';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final w = widget.worker;
    _nameCtrl = TextEditingController(text: w?.name ?? '');
    _emailCtrl = TextEditingController(text: w?.email ?? '');
    _ageCtrl = TextEditingController(text: w != null ? '${w.age}' : '');
    _weightCtrl = TextEditingController(text: w != null ? '${w.weight}' : '');
    _heightCtrl = TextEditingController(text: w != null ? '${w.height}' : '');
    if (w != null) _gender = w.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  bool get isEditing => widget.worker != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'gender': _gender,
      'age': int.parse(_ageCtrl.text.trim()),
      'weight': double.parse(_weightCtrl.text.trim()),
      'height': double.parse(_heightCtrl.text.trim()),
    };

    bool success;
    if (isEditing) {
      success = await ref
          .read(workerProvider.notifier)
          .updateWorker(widget.worker!.id!, data);
    } else {
      success = await ref.read(workerProvider.notifier).addWorker(data);
    }

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(isEditing ? 'Worker updated' : 'Worker added')));
        Navigator.pop(context, true);
      } else {
        final err = ref.read(workerProvider).error;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err ?? 'Error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Worker' : 'Add Worker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Gender dropdown
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Enter a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Enter a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _heightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  prefixIcon: Icon(Icons.height),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Enter a number';
                  return null;
                },
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
                label: Text(isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
