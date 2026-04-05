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

    final context = tester.element(find.byType(NutritionRecommendationCard));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.adaptiveRecommendationCardTitle), findsOneWidget);
    expect(find.text(l10n.adaptiveRecommendationEmptyBody), findsOneWidget);
    expect(find.text(l10n.adaptiveRecommendationApplyAction), findsNothing);
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

    final context = tester.element(find.byType(NutritionRecommendationCard));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text('2500 kcal'), findsOneWidget);
    expect(find.text(l10n.adaptiveRecommendationApplyAction), findsOneWidget);

    await tester.tap(find.text(l10n.adaptiveRecommendationApplyAction));
    await tester.pump();

    expect(applyTapped, isTrue);
  });

  testWidgets('renders safety-floor warning message when reason is present',
      (tester) async {
    final recommendation = _recommendation().copyWith(
      warningState: const RecommendationWarningState(
        hasLargeAdjustmentWarning: false,
        warningLevel: RecommendationWarningLevel.high,
        warningReasons: ['calorie_floor_applied'],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NutritionRecommendationCard(
            goal: BodyweightGoal.maintainWeight,
            targetRateKgPerWeek: 0,
            recommendation: recommendation,
            activeTargetCalories: 2400,
            isApplying: false,
            onApply: () {},
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(NutritionRecommendationCard));
    final l10n = AppLocalizations.of(context)!;
    expect(
      find.text(l10n.adaptiveRecommendationWarningCalorieFloor),
      findsOneWidget,
    );
  });

  testWidgets('renders localized recommendation title for german locale',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
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

    expect(find.text('Adaptive Empfehlung'), findsOneWidget);
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

extension on NutritionRecommendation {
  NutritionRecommendation copyWith({
    int? recommendedCalories,
    int? recommendedProteinGrams,
    int? recommendedCarbsGrams,
    int? recommendedFatGrams,
    int? estimatedMaintenanceCalories,
    BodyweightGoal? goal,
    double? targetRateKgPerWeek,
    RecommendationConfidence? confidence,
    RecommendationWarningState? warningState,
    DateTime? generatedAt,
    DateTime? windowStart,
    DateTime? windowEnd,
    String? algorithmVersion,
    RecommendationInputSummary? inputSummary,
    int? baselineCalories,
    String? dueWeekKey,
  }) {
    return NutritionRecommendation(
      recommendedCalories: recommendedCalories ?? this.recommendedCalories,
      recommendedProteinGrams:
          recommendedProteinGrams ?? this.recommendedProteinGrams,
      recommendedCarbsGrams:
          recommendedCarbsGrams ?? this.recommendedCarbsGrams,
      recommendedFatGrams: recommendedFatGrams ?? this.recommendedFatGrams,
      estimatedMaintenanceCalories:
          estimatedMaintenanceCalories ?? this.estimatedMaintenanceCalories,
      goal: goal ?? this.goal,
      targetRateKgPerWeek: targetRateKgPerWeek ?? this.targetRateKgPerWeek,
      confidence: confidence ?? this.confidence,
      warningState: warningState ?? this.warningState,
      generatedAt: generatedAt ?? this.generatedAt,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
      inputSummary: inputSummary ?? this.inputSummary,
      baselineCalories: baselineCalories ?? this.baselineCalories,
      dueWeekKey: dueWeekKey ?? this.dueWeekKey,
    );
  }
}
