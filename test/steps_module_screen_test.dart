import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/steps/data/steps_aggregation_repository.dart';
import 'package:hypertrack/features/steps/presentation/steps_module_screen.dart';
import 'package:hypertrack/generated/app_localizations.dart';

void main() {
  testWidgets('scope switching updates trend canvas and card label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StepsModuleScreen(
          repository: InMemoryStepsAggregationRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Today by hour'), findsOneWidget);
    expect(find.textContaining('Steps • Today'), findsOneWidget);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.textContaining('Steps •'), findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    expect(find.textContaining('202'), findsOneWidget);
    expect(find.textContaining('Steps •'), findsOneWidget);
  });
}
