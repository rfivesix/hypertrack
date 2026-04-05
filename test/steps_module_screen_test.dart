import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/steps/data/steps_aggregation_repository.dart';
import 'package:hypertrack/features/steps/presentation/steps_module_screen.dart';
import 'package:hypertrack/generated/app_localizations.dart';
import 'package:hypertrack/services/workout_session_manager.dart';
import 'package:hypertrack/widgets/statistics_steps_card.dart';
import 'package:provider/provider.dart';

Future<void> _pumpUntilScopeLoaded(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      return;
    }
  }
  throw TestFailure('Steps scope did not finish loading in test');
}

Future<void> _pumpScopeTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await _pumpUntilScopeLoaded(tester);
}

void main() {
  testWidgets('scope switching updates trend canvas and card label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<WorkoutSessionManager>.value(
        value: WorkoutSessionManager(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StepsModuleScreen(
            repository: InMemoryStepsAggregationRepository(),
            targetStepsLoader: _fakeTargetSteps,
            stepsProviderNameLoader: _fakeProviderName,
          ),
        ),
      ),
    );

    await _pumpUntilScopeLoaded(tester);

    expect(find.text('Hourly timeline'), findsOneWidget);
    expect(find.byType(StatisticsStepsCard), findsNothing);

    await tester.tap(find.text('Week'));
    await _pumpScopeTransition(tester);

    expect(find.text('Hourly timeline'), findsNothing);
    expect(find.byType(StatisticsStepsCard), findsNothing);

    await tester.tap(find.text('Month'));
    await _pumpScopeTransition(tester);

    expect(find.byType(StatisticsStepsCard), findsOneWidget);
    expect(find.textContaining('This month •'), findsOneWidget);
  });
}

Future<int> _fakeTargetSteps() async => 8000;

Future<String> _fakeProviderName() async => 'Local';
