import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/worker.dart';
import '../services/api_service.dart';

// ── State ─────────────────────────────────────────────────
class WorkerState {
  final bool isLoading;
  final List<Worker> workers;
  final String? error;

  const WorkerState({
    this.isLoading = false,
    this.workers = const [],
    this.error,
  });

  WorkerState copyWith({bool? isLoading, List<Worker>? workers, String? error}) {
    return WorkerState(
      isLoading: isLoading ?? this.isLoading,
      workers: workers ?? this.workers,
      error: error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────
class WorkerNotifier extends StateNotifier<WorkerState> {
  WorkerNotifier() : super(const WorkerState());

  Future<void> fetchWorkers({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiService.getWorkers(search: search);
      final list = data.map((j) => Worker.fromJson(j)).toList();
      state = state.copyWith(isLoading: false, workers: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addWorker(Map<String, dynamic> data) async {
    try {
      await ApiService.createWorker(data);
      await fetchWorkers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateWorker(String id, Map<String, dynamic> data) async {
    try {
      await ApiService.updateWorker(id, data);
      await fetchWorkers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteWorker(String id) async {
    try {
      await ApiService.deleteWorker(id);
      await fetchWorkers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// ── Provider ──────────────────────────────────────────────
final workerProvider = StateNotifierProvider<WorkerNotifier, WorkerState>((ref) {
  return WorkerNotifier();
});
