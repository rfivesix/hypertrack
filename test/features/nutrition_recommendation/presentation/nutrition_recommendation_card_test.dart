import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/presentation/nutrition_recommendation_card.dart';
import 'package:hypertrack/generated/app_localizations.dart';

void main() {
  testWidgets('renders empty state without recommendation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NutritionRecommendationCard(
            goal: BodyweightGoal.maintainWeight,
            targetRateKgPerWeek: 0,
            recommendation: null,
            activeTargetCalories: 2400,
            isApplying: false,
            onApply: () {},
          ),
        ),
      ),
    );

    expect(find.text('Adaptive recommendation'), findsOneWidget);
    expect(find.textContaining('unlock the first weekly recommendation'),
        findsOneWidget);
    expect(find.text('Apply recommendation to active goals'), findsNothing);
  });

  testWidgets('renders recommendation details and apply action',
      (tester) async {
    var applyTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NutritionRecommendationCard(
            goal: BodyweightGoal.maintainWeight,
            targetRateKgPerWeek: 0,
            recommendation: _recommendation(),
            activeTargetCalories: 2400,
            isApplying: false,
            onApply: () {
              applyTapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('2500 kcal'), findsOneWidget);
    expect(find.text('Apply recommendation to active goals'), findsOneWidget);

    await tester.tap(find.text('Apply recommendation to active goals'));
    await tester.pump();

    expect(applyTapped, isTrue);
  });
}

NutritionRecommendation _recommendation() {
  return NutritionRecommendation(
    recommendedCalories: 2500,
    recommendedProteinGrams: 180,
    recommendedCarbsGrams: 280,
    recommendedFatGrams: 75,
    estimatedMaintenanceCalories: 2500,
    goal: BodyweightGoal.maintainWeight,
    targetRateKgPerWeek: 0,
    confidence: RecommendationConfidence.medium,
    warningState: RecommendationWarningState.none,
    generatedAt: DateTime(2026, 4, 5),
    windowStart: DateTime(2026, 3, 15),
    windowEnd: DateTime(2026, 4, 5, 23, 59, 59),
    algorithmVersion: 'test',
    inputSummary: const RecommendationInputSummary(
      windowDays: 21,
      weightLogCount: 9,
      intakeLoggedDays: 15,
      smoothedWeightSlopeKgPerWeek: -0.2,
      avgLoggedCalories: 2300,
    ),
    baselineCalories: 2400,
    dueWeekKey: '2026-03-30',
  );
}
