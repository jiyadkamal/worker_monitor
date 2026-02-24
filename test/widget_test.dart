import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worker_monitor/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: WorkerMonitorApp()),
    );
    await tester.pumpAndSettle();

    // Should show login screen when unauthenticated
    expect(find.text('Worker Monitor'), findsOneWidget);
  });
}
