import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monitoring_record.dart';
import '../services/api_service.dart';

// ── State ─────────────────────────────────────────────────
class RecordState {
  final bool isLoading;
  final List<MonitoringRecord> records;
  final String? error;

  const RecordState({
    this.isLoading = false,
    this.records = const [],
    this.error,
  });

  RecordState copyWith(
      {bool? isLoading, List<MonitoringRecord>? records, String? error}) {
    return RecordState(
      isLoading: isLoading ?? this.isLoading,
      records: records ?? this.records,
      error: error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────
class RecordNotifier extends StateNotifier<RecordState> {
  RecordNotifier() : super(const RecordState());

  Future<void> fetchRecords({String? workerId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiService.getRecords(workerId: workerId);
      final list = data.map((j) => MonitoringRecord.fromJson(j)).toList();
      state = state.copyWith(isLoading: false, records: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addRecord(Map<String, dynamic> data) async {
    try {
      await ApiService.createRecord(data);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// ── Provider ──────────────────────────────────────────────
final recordProvider =
    StateNotifierProvider<RecordNotifier, RecordState>((ref) {
  return RecordNotifier();
});
