import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by name…',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) =>
                    ref.read(workerProvider.notifier).fetchWorkers(search: v),
              )
            : const Text('Workers'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
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
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
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
        icon: const Icon(Icons.person_add),
        label: const Text('Add Worker'),
      ),
      body: workerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : workerState.workers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: cs.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('No workers yet',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Tap + to add your first worker',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(workerProvider.notifier).fetchWorkers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 8, bottom: 88),
                    itemCount: workerState.workers.length,
                    itemBuilder: (context, index) {
                      final w = workerState.workers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Text(
                              w.name.isNotEmpty
                                  ? w.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(w.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${w.gender} • Age ${w.age} • BMI ${w.bmi}'),
                          trailing:
                              const Icon(Icons.chevron_right, size: 20),
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
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
