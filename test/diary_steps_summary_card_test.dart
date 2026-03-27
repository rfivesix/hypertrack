import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:hypertrack/features/steps/domain/steps_models.dart';
import 'package:hypertrack/widgets/statistics_steps_card.dart';

void main() {
  final buckets = List<StepsBucket>.generate(
    7,
    (index) => StepsBucket(
      start: DateTime(2026, 3, 20).add(Duration(days: index)),
      steps: 1200 + (index * 700),
    ),
  );

  testWidgets('statistics steps card shows key diary values', (tester) async {
    final formatted = NumberFormat.decimalPattern().format(3388);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatisticsStepsCard(
            onTap: () {},
            title: 'Schritte',
            subtitle: 'Letzte 7 Tage • Withings',
            currentSteps: 3388,
            currentStepsSubtitle: 'Heute',
            dailyTotals: buckets,
            dailyGoal: 8000,
          ),
        ),
      ),
    );

    expect(find.text('Schritte'), findsOneWidget);
    expect(find.text('Letzte 7 Tage • Withings'), findsOneWidget);
    expect(find.text(formatted), findsOneWidget);
    expect(find.text('Heute'), findsOneWidget);
  });

  testWidgets('statistics steps card forwards onTap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatisticsStepsCard(
            onTap: () => tapped = true,
            title: 'Schritte',
            subtitle: 'Letzte 7 Tage • Local',
            currentSteps: 1200,
            currentStepsSubtitle: 'Heute',
            dailyTotals: buckets,
            dailyGoal: 8000,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(StatisticsStepsCard));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
