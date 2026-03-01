import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supervisor.dart';
import '../services/local_db_service.dart';

// ── State ─────────────────────────────────────────────────
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final Supervisor? supervisor;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.supervisor,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, Supervisor? supervisor, String? error}) {
    return AuthState(
      status: status ?? this.status,
      supervisor: supervisor ?? this.supervisor,
      error: error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> checkAuth() async {
    final hasSession = await LocalDbService.hasSession();
    state = AuthState(
      status: hasSession ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final data = await LocalDbService.register(name, email, password);
      final sup = Supervisor.fromJson(data['supervisor']);
      state = AuthState(status: AuthStatus.authenticated, supervisor: sup);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final data = await LocalDbService.login(email, password);
      final sup = Supervisor.fromJson(data['supervisor']);
      state = AuthState(status: AuthStatus.authenticated, supervisor: sup);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
    }
  }

  Future<void> logout() async {
    await LocalDbService.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ── Provider ──────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
