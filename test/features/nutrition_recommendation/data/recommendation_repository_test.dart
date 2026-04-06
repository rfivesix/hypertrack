import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_repository.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/bayesian_experimental_snapshot.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecommendationRepository', () {
    late RecommendationRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = RecommendationRepository();
    });

    test('returns maintain defaults when nothing persisted', () async {
      expect(await repository.getGoal(), BodyweightGoal.maintainWeight);
      expect(await repository.getTargetRateKgPerWeek(), 0);
      expect(
        await repository.getPriorActivityLevel(),
        PriorActivityLevel.moderate,
      );
      expect(
        await repository.getExtraCardioHoursOption(),
        ExtraCardioHoursOption.h0,
      );
      expect(await repository.getLatestGeneratedRecommendation(), isNull);
    });

    test('coerces unsupported rate to goal default', () async {
      await repository.saveGoalAndTargetRate(
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.2,
      );

      expect(await repository.getGoal(), BodyweightGoal.gainWeight);
      expect(await repository.getTargetRateKgPerWeek(), 0.25);
    });

    test('persists and restores generated/applied recommendations', () async {
      final recommendation = _recommendation();
      await repository.savePriorActivityLevel(PriorActivityLevel.veryHigh);
      await repository.saveExtraCardioHoursOption(ExtraCardioHoursOption.h3);

      await repository.saveLatestGeneratedRecommendation(
        recommendation: recommendation,
      );
      await repository.saveLatestAppliedRecommendation(
        recommendation: recommendation,
      );

      final generated = await repository.getLatestGeneratedRecommendation();
      final applied = await repository.getLatestAppliedRecommendation();

      expect(generated, isNotNull);
      expect(applied, isNotNull);
      expect(
          generated!.recommendedCalories, recommendation.recommendedCalories);
      expect(applied!.recommendedFatGrams, recommendation.recommendedFatGrams);
      expect(await repository.getLastGeneratedDueWeekKey(), '2026-03-30');
      expect(
        await repository.getPriorActivityLevel(),
        PriorActivityLevel.veryHigh,
      );
      expect(
        await repository.getExtraCardioHoursOption(),
        ExtraCardioHoursOption.h3,
      );
    });

    test('falls back to default prior activity level on unknown raw value',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'adaptive_nutrition_recommendation.prior_activity_level': 'legacyValue',
      });
      repository = RecommendationRepository();

      expect(
        await repository.getPriorActivityLevel(),
        PriorActivityLevel.moderate,
      );
    });

    test('persists and restores atomic Bayesian experimental snapshot',
        () async {
      final snapshot = BayesianExperimentalRecommendationSnapshot(
        recommendation: _recommendation().copyWith(
          dueWeekKey: '2026-04-06',
          algorithmVersion: 'bayesian_test',
        ),
        maintenanceEstimate: _estimate(dueWeekKey: '2026-04-06'),
        dueWeekKey: '2026-04-06',
        algorithmVersion: 'bayesian_test',
      );

      await repository.saveLatestBayesianExperimentalSnapshot(
        snapshot: snapshot,
      );

      final restored = await repository.getLatestBayesianExperimentalSnapshot();
      final heuristic = await repository.getLatestGeneratedRecommendation();
      final prefs = await SharedPreferences.getInstance();
      final rawSnapshot = prefs.getString(
        'adaptive_nutrition_recommendation.latest_bayesian_experimental_snapshot',
      );
      final decodedSnapshot = jsonDecode(rawSnapshot!) as Map<String, dynamic>;

      expect(restored, isNotNull);
      expect(heuristic, isNull);
      expect(restored!.dueWeekKey, '2026-04-06');
      expect(restored.generatedAt, restored.recommendation.generatedAt);
      expect(
        restored.generatedAt,
        snapshot.recommendation.generatedAt,
      );
      expect(decodedSnapshot.containsKey('generatedAt'), isFalse);
      expect(
        (decodedSnapshot['recommendation'] as Map)['generatedAt'],
        isNotNull,
      );
      expect(
        restored.maintenanceEstimate.posteriorMaintenanceCalories,
        closeTo(2380, 0.001),
      );
      expect(
        prefs.getString(
          'adaptive_nutrition_recommendation.last_generated_due_week_key_bayesian_experimental',
        ),
        isNull,
      );
    });

    test('returns null for incoherent Bayesian snapshot payload', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'adaptive_nutrition_recommendation.latest_bayesian_experimental_snapshot',
        '{"dueWeekKey":"2026-04-06","algorithmVersion":"bayesian_test",'
            '"recommendation":{"dueWeekKey":"2026-04-06","algorithmVersion":"bayesian_test"},'
            '"maintenanceEstimate":{"dueWeekKey":"2026-04-13"}}',
      );

      final snapshot = await repository.getLatestBayesianExperimentalSnapshot();
      expect(snapshot, isNull);
    });

    test('migrates coherent legacy experimental payload to atomic snapshot',
        () async {
      final recommendation = _recommendation().copyWith(
        dueWeekKey: '2026-04-06',
        algorithmVersion: 'bayesian_test',
      );
      final estimate = _estimate(dueWeekKey: '2026-04-06');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'adaptive_nutrition_recommendation.latest_generated_bayesian_experimental',
        _encodeRecommendation(recommendation),
      );
      await prefs.setString(
        'adaptive_nutrition_recommendation.latest_bayesian_maintenance_estimate',
        _encodeEstimate(estimate),
      );
      await prefs.setString(
        'adaptive_nutrition_recommendation.last_generated_due_week_key_bayesian_experimental',
        '2026-04-06',
      );

      final snapshot = await repository.getLatestBayesianExperimentalSnapshot();

      expect(snapshot, isNotNull);
      expect(snapshot!.dueWeekKey, '2026-04-06');
      expect(
        snapshot.maintenanceEstimate.posteriorMaintenanceCalories,
        closeTo(estimate.posteriorMaintenanceCalories, 0.001),
      );
    });
  });
}

NutritionRecommendation _recommendation() {
  return NutritionRecommendation(
    recommendedCalories: 2400,
    recommendedProteinGrams: 170,
    recommendedCarbsGrams: 270,
    recommendedFatGrams: 70,
    estimatedMaintenanceCalories: 2400,
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
    baselineCalories: 2300,
    dueWeekKey: '2026-03-30',
  );
}

BayesianMaintenanceEstimate _estimate({required String dueWeekKey}) {
  return BayesianMaintenanceEstimate(
    posteriorMaintenanceCalories: 2380,
    posteriorStdDevCalories: 180,
    profilePriorMaintenanceCalories: 2400,
    priorMeanUsedCalories: 2400,
    priorStdDevUsedCalories: 200,
    priorSource: BayesianPriorSource.profilePriorBootstrap,
    observedIntakeCalories: 2300,
    observedWeightSlopeKgPerWeek: -0.1,
    observationImpliedMaintenanceCalories: 2410,
    effectiveSampleSize: 10,
    confidence: RecommendationConfidence.medium,
    qualityFlags: const ['bayesian_prior_dominant'],
    debugInfo: const {'kalmanGain': 0.33},
    dueWeekKey: dueWeekKey,
  );
}

String _encodeRecommendation(NutritionRecommendation recommendation) {
  return jsonEncode(recommendation.toJson());
}

String _encodeEstimate(BayesianMaintenanceEstimate estimate) {
  return jsonEncode(estimate.toJson());
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
