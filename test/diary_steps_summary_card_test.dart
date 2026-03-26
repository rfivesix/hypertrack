import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/screens/diary_screen.dart';
import 'package:hypertrack/widgets/glass_progress_bar.dart';

void main() {
  testWidgets('diary steps summary uses GlassProgressBar component', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DiaryStepsSummaryCard(
            stepsLabel: 'Steps',
            stepsText: '5,000',
            value: 5000,
            target: 10000,
          ),
        ),
      ),
    );

    expect(find.byType(GlassProgressBar), findsOneWidget);
    expect(find.text('Steps'), findsOneWidget);
    expect(find.textContaining('steps'), findsOneWidget);
  });
}
