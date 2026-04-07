import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
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
            maintenanceEstimate: null,
            generatedAt: null,
            nextAdaptiveRecommendationDueAt: DateTime(2026, 4, 6),
            isAdaptiveRecommendationDueNow: true,
            activeTargetCalories: 2400,
            isRecalculating: false,
            isApplying: false,
            onRecalculate: () {},
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
    var recalculateTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NutritionRecommendationCard(
            goal: BodyweightGoal.maintainWeight,
            targetRateKgPerWeek: 0,
            recommendation: _recommendation(),
            maintenanceEstimate: _estimate(),
            generatedAt: DateTime(2026, 4, 5, 9, 0),
            nextAdaptiveRecommendationDueAt: DateTime(2026, 4, 13),
            isAdaptiveRecommendationDueNow: false,
            activeTargetCalories: 2400,
            isRecalculating: false,
            isApplying: false,
            onRecalculate: () {
              recalculateTapped = true;
            },
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
    expect(
      find.text(l10n.adaptiveRecommendationRecalculateNowAction),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.adaptiveRecommendationApplyAction));
    await tester
        .tap(find.text(l10n.adaptiveRecommendationRecalculateNowAction));
    await tester.pump();

    expect(applyTapped, isTrue);
    expect(recalculateTapped, isTrue);
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
            maintenanceEstimate: _estimate(),
            generatedAt: recommendation.generatedAt,
            nextAdaptiveRecommendationDueAt: DateTime(2026, 4, 13),
            isAdaptiveRecommendationDueNow: false,
            activeTargetCalories: 2400,
            isRecalculating: false,
            isApplying: false,
            onRecalculate: () {},
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

  testWidgets('renders unresolved-food warning message when reason is present',
      (tester) async {
    final recommendation = _recommendation().copyWith(
      warningState: const RecommendationWarningState(
        hasLargeAdjustmentWarning: false,
        warningLevel: RecommendationWarningLevel.moderate,
        warningReasons: ['unresolved_food_calories'],
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
            maintenanceEstimate: _estimate(),
            generatedAt: recommendation.generatedAt,
            nextAdaptiveRecommendationDueAt: DateTime(2026, 4, 13),
            isAdaptiveRecommendationDueNow: false,
            activeTargetCalories: 2400,
            isRecalculating: false,
            isApplying: false,
            onRecalculate: () {},
            onApply: () {},
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(NutritionRecommendationCard));
    final l10n = AppLocalizations.of(context)!;
    expect(
      find.text(l10n.adaptiveRecommendationWarningUnresolvedFood),
      findsOneWidget,
    );
  });

  testWidgets(
      'renders prior-only data-basis message when recommendation is prior-only',
      (tester) async {
    final recommendation = _recommendation().copyWith(
      confidence: RecommendationConfidence.notEnoughData,
      inputSummary: const RecommendationInputSummary(
        windowDays: 0,
        weightLogCount: 1,
        intakeLoggedDays: 0,
        smoothedWeightSlopeKgPerWeek: null,
        avgLoggedCalories: 0,
        qualityFlags: ['onboarding_prior_only'],
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
            maintenanceEstimate: _estimate(),
            generatedAt: recommendation.generatedAt,
            nextAdaptiveRecommendationDueAt: DateTime(2026, 4, 13),
            isAdaptiveRecommendationDueNow: false,
            activeTargetCalories: 2400,
            isRecalculating: false,
            isApplying: false,
            onRecalculate: () {},
            onApply: () {},
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(NutritionRecommendationCard));
    final l10n = AppLocalizations.of(context)!;
    expect(
      find.text(l10n.adaptiveRecommendationDataBasisHintPriorOnly),
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
            maintenanceEstimate: null,
            generatedAt: null,
            nextAdaptiveRecommendationDueAt: DateTime(2026, 4, 6),
            isAdaptiveRecommendationDueNow: true,
            activeTargetCalories: 2400,
            isRecalculating: false,
            isApplying: false,
            onRecalculate: () {},
            onApply: () {},
          ),
        ),
      ),
    );

    expect(find.text('Adaptive Empfehlung'), findsOneWidget);
  });

  testWidgets('renders maintenance credible interval and uncertainty hint',
      (tester) async {
    final estimate = _estimate().copyWith(
      posteriorStdDevCalories: 80,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NutritionRecommendationCard(
            goal: BodyweightGoal.maintainWeight,
            targetRateKgPerWeek: 0,
            recommendation: _recommendation(),
            maintenanceEstimate: estimate,
            generatedAt: DateTime(2026, 4, 5, 9, 0),
            nextAdaptiveRecommendationDueAt: DateTime(2026, 4, 13),
            isAdaptiveRecommendationDueNow: false,
            activeTargetCalories: 2400,
            isRecalculating: false,
            isApplying: false,
            onRecalculate: () {},
            onApply: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('adaptive_recommendation_range_line')),
        findsOneWidget);
    expect(find.byKey(const Key('adaptive_recommendation_uncertainty_hint')),
        findsOneWidget);
  });

  testWidgets('renders stabilizing hint when estimate is still settling',
      (tester) async {
    final estimate = _estimate().copyWith(
      qualityFlags: const ['bayesian_estimate_still_stabilizing'],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NutritionRecommendationCard(
            goal: BodyweightGoal.maintainWeight,
            targetRateKgPerWeek: 0,
            recommendation: _recommendation(),
            maintenanceEstimate: estimate,
            generatedAt: DateTime(2026, 4, 5, 9, 0),
            nextAdaptiveRecommendationDueAt: DateTime(2026, 4, 13),
            isAdaptiveRecommendationDueNow: false,
            activeTargetCalories: 2400,
            isRecalculating: false,
            isApplying: false,
            onRecalculate: () {},
            onApply: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('adaptive_recommendation_stabilizing_hint')),
      findsOneWidget,
    );
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

BayesianMaintenanceEstimate _estimate() {
  return const BayesianMaintenanceEstimate(
    posteriorMaintenanceCalories: 2500,
    posteriorStdDevCalories: 150,
    profilePriorMaintenanceCalories: 2450,
    priorMeanUsedCalories: 2450,
    priorStdDevUsedCalories: 200,
    priorSource: BayesianPriorSource.profilePriorBootstrap,
    observedIntakeCalories: 2350,
    observedWeightSlopeKgPerWeek: -0.1,
    observationImpliedMaintenanceCalories: 2460,
    effectiveSampleSize: 10,
    confidence: RecommendationConfidence.medium,
    qualityFlags: <String>[],
    debugInfo: <String, Object>{},
    dueWeekKey: '2026-03-30',
  );
}

extension on BayesianMaintenanceEstimate {
  BayesianMaintenanceEstimate copyWith({
    double? posteriorMaintenanceCalories,
    double? posteriorStdDevCalories,
    double? profilePriorMaintenanceCalories,
    double? priorMeanUsedCalories,
    double? priorStdDevUsedCalories,
    BayesianPriorSource? priorSource,
    double? observedIntakeCalories,
    double? observedWeightSlopeKgPerWeek,
    double? observationImpliedMaintenanceCalories,
    double? effectiveSampleSize,
    RecommendationConfidence? confidence,
    List<String>? qualityFlags,
    Map<String, Object>? debugInfo,
    String? dueWeekKey,
  }) {
    return BayesianMaintenanceEstimate(
      posteriorMaintenanceCalories:
          posteriorMaintenanceCalories ?? this.posteriorMaintenanceCalories,
      posteriorStdDevCalories:
          posteriorStdDevCalories ?? this.posteriorStdDevCalories,
      profilePriorMaintenanceCalories: profilePriorMaintenanceCalories ??
          this.profilePriorMaintenanceCalories,
      priorMeanUsedCalories:
          priorMeanUsedCalories ?? this.priorMeanUsedCalories,
      priorStdDevUsedCalories:
          priorStdDevUsedCalories ?? this.priorStdDevUsedCalories,
      priorSource: priorSource ?? this.priorSource,
      observedIntakeCalories:
          observedIntakeCalories ?? this.observedIntakeCalories,
      observedWeightSlopeKgPerWeek:
          observedWeightSlopeKgPerWeek ?? this.observedWeightSlopeKgPerWeek,
      observationImpliedMaintenanceCalories:
          observationImpliedMaintenanceCalories ??
              this.observationImpliedMaintenanceCalories,
      effectiveSampleSize: effectiveSampleSize ?? this.effectiveSampleSize,
      confidence: confidence ?? this.confidence,
      qualityFlags: qualityFlags ?? this.qualityFlags,
      debugInfo: debugInfo ?? this.debugInfo,
      dueWeekKey: dueWeekKey ?? this.dueWeekKey,
    );
  }
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
