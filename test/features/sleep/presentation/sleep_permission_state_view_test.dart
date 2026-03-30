import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/platform/permissions/sleep_permission_models.dart';
import 'package:hypertrack/features/sleep/presentation/sleep_permission_state_view.dart';

void main() {
  Future<void> pumpState(WidgetTester tester, SleepPermissionState state) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SleepPermissionStateView(
            status: SleepPermissionStatus(state: state),
            onConnect: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders connect state for denied', (tester) async {
    await pumpState(tester, SleepPermissionState.denied);

    expect(find.text('Permission denied'), findsOneWidget);
    expect(find.text('Connect health data'), findsOneWidget);
  });

  testWidgets('renders unavailable and not-installed states distinctly',
      (tester) async {
    await pumpState(tester, SleepPermissionState.unavailable);
    expect(find.text('Health source unavailable'), findsOneWidget);

    await pumpState(tester, SleepPermissionState.notInstalled);
    expect(find.text('Health Connect not installed'), findsOneWidget);
  });
}
