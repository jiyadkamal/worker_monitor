import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/worker_provider.dart';
import 'add_edit_worker_screen.dart';
import 'worker_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(workerProvider.notifier).fetchWorkers());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workerState = ref.watch(workerProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search workers...',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) =>
                    ref.read(workerProvider.notifier).fetchWorkers(search: v),
              )
            : Text(
                'Safety Monitor',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchCtrl.clear();
                  ref.read(workerProvider.notifier).fetchWorkers();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddEditWorkerScreen()),
          );
          if (result == true) {
            ref.read(workerProvider.notifier).fetchWorkers();
          }
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Worker'),
        elevation: 4,
      ),
      body: workerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : workerState.workers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.people_alt_outlined,
                            size: 80, color: cs.primary),
                      ),
                      const SizedBox(height: 24),
                      Text('No Workers Found',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 8),
                      Text('Add your team members to start monitoring.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(workerProvider.notifier).fetchWorkers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                        left: 20, right: 20, top: 12, bottom: 100),
                    itemCount: workerState.workers.length,
                    itemBuilder: (context, index) {
                      final w = workerState.workers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      WorkerDetailScreen(worker: w),
                                ),
                              );
                              ref.read(workerProvider.notifier).fetchWorkers();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // ── Avatar ─────────────────────
                                  Hero(
                                    tag: 'avatar-${w.id}',
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: cs.primary.withValues(alpha: 0.1),
                                      backgroundImage: (w.photoUrl != null && w.photoUrl!.isNotEmpty)
                                          ? FileImage(File(w.photoUrl!))
                                          : null,
                                      child: (w.photoUrl == null || w.photoUrl!.isEmpty)
                                          ? Text(
                                              w.name.isNotEmpty ? w.name[0].toUpperCase() : '?',
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: cs.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // ── Info ───────────────────────
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          w.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${w.gender} • ${w.age} years • BMI ${w.bmi}',
                                          style: TextStyle(
                                            color: cs.onSurfaceVariant,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // ── Arrow ──────────────────────
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      size: 16, color: cs.outlineVariant),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
