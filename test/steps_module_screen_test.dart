import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/steps/data/steps_aggregation_repository.dart';
import 'package:hypertrack/features/steps/presentation/steps_module_screen.dart';

void main() {
  testWidgets('scope switching updates trend canvas and card label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StepsModuleScreen(repository: InMemoryStepsAggregationRepository()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Today by hour'), findsOneWidget);
    expect(find.textContaining('Steps • Today'), findsOneWidget);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.textContaining('Steps • Last 7 days'), findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    expect(find.text('This month'), findsOneWidget);
    expect(find.textContaining('Steps • This month'), findsOneWidget);
  });
}
