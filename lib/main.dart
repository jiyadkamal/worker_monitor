import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the local SQLite database
  await DatabaseHelper.instance.database;
  runApp(const ProviderScope(child: WorkerMonitorApp()));
}

class WorkerMonitorApp extends ConsumerWidget {
  const WorkerMonitorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Worker Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

/// Routes to [HomeScreen] when authenticated, [LoginScreen] otherwise.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).checkAuth());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    switch (authState.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}
