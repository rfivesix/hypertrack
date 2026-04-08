import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_repository.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/adaptive_diet_phase.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/adaptive_recommendation_snapshot.dart';
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
      expect(await repository.getLatestRecommendationSnapshot(), isNull);
      expect(await repository.getLatestEstimatorState(), isNull);
    });

    test('coerces unsupported rate to goal default', () async {
      await repository.saveGoalAndTargetRate(
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.2,
      );

      expect(await repository.getGoal(), BodyweightGoal.gainWeight);
      expect(await repository.getTargetRateKgPerWeek(), 0.25);
    });

    test('persists and restores canonical snapshot + generated/applied',
        () async {
      final recommendation = _recommendation().copyWith(
        dueWeekKey: '2026-04-06',
        algorithmVersion: 'bayesian_test',
      );
      final estimate = _estimate(dueWeekKey: '2026-04-06');
      final snapshot = AdaptiveRecommendationSnapshot(
        recommendation: recommendation,
        maintenanceEstimate: estimate,
        dueWeekKey: '2026-04-06',
        algorithmVersion: 'bayesian_test',
      );

      await repository.saveLatestRecommendationSnapshot(snapshot: snapshot);
      await repository.saveLatestAppliedRecommendation(
        recommendation: recommendation,
      );

      final restoredSnapshot =
          await repository.getLatestRecommendationSnapshot();
      final generated = await repository.getLatestGeneratedRecommendation();
      final applied = await repository.getLatestAppliedRecommendation();
      final prefs = await SharedPreferences.getInstance();
      final rawSnapshot = prefs.getString(
        'adaptive_nutrition_recommendation.latest_snapshot',
      );
      final decoded = jsonDecode(rawSnapshot!) as Map<String, dynamic>;

      expect(restoredSnapshot, isNotNull);
      expect(generated, isNotNull);
      expect(applied, isNotNull);
      expect(restoredSnapshot!.isCoherent, isTrue);
      expect(restoredSnapshot.dueWeekKey, '2026-04-06');
      expect(restoredSnapshot.generatedAt, recommendation.generatedAt);
      expect(
          generated!.recommendedCalories, recommendation.recommendedCalories);
      expect(applied!.recommendedFatGrams, recommendation.recommendedFatGrams);
      expect(await repository.getLastGeneratedDueWeekKey(), '2026-04-06');
      expect(decoded.containsKey('generatedAt'), isFalse);
      expect(
        (decoded['recommendation'] as Map<String, dynamic>)['generatedAt'],
        isNotNull,
      );
    });

    test('persists and restores recursive estimator state', () async {
      const state = BayesianEstimatorState(
        posteriorMeanCalories: 2375,
        posteriorVarianceCalories2: 42000,
        lastDueWeekKey: '2026-04-06',
        lastPriorMeanCalories: 2400,
        lastPriorVarianceCalories2: 60000,
        lastPriorSource: BayesianPriorSource.chainedPosterior,
        lastObservationUsed: true,
        recentPosteriorMeansCalories: <double>[2360, 2370, 2375],
        recentObservationResidualsCalories: <double>[35, -20],
        recentObservationImpliedMaintenanceCalories: <double>[2385, 2365],
      );

      await repository.saveLatestEstimatorState(state: state);
      final restored = await repository.getLatestEstimatorState();

      expect(restored, isNotNull);
      expect(restored!.lastDueWeekKey, '2026-04-06');
      expect(restored.posteriorMeanCalories, closeTo(2375, 0.0001));
      expect(restored.posteriorVarianceCalories2, closeTo(42000, 0.0001));
      expect(restored.lastPriorSource, BayesianPriorSource.chainedPosterior);
      expect(restored.hasReplayPrior, isTrue);
      expect(restored.recentPosteriorMeansCalories, hasLength(3));
      expect(restored.recentObservationResidualsCalories, hasLength(2));
      expect(
          restored.recentObservationImpliedMaintenanceCalories, hasLength(2));
    });

    test('persists and restores diet phase tracking state', () async {
      final state = AdaptiveDietPhaseTrackingState(
        confirmedPhase: AdaptiveDietPhase.cut,
        confirmedPhaseStartDay: DateTime(2026, 4, 1),
        pendingPhase: AdaptiveDietPhase.bulk,
        pendingPhaseFirstSeenDay: DateTime(2026, 4, 3),
      );

      await repository.saveDietPhaseTrackingState(state: state);
      final restored = await repository.getDietPhaseTrackingState();

      expect(restored, isNotNull);
      expect(restored!.confirmedPhase, AdaptiveDietPhase.cut);
      expect(
        restored.confirmedPhaseStartDay,
        AdaptiveDietPhaseTrackingState.normalizeDay(DateTime(2026, 4, 1)),
      );
      expect(restored.pendingPhase, AdaptiveDietPhase.bulk);
      expect(
        restored.pendingPhaseFirstSeenDay,
        AdaptiveDietPhaseTrackingState.normalizeDay(DateTime(2026, 4, 3)),
      );
    });

    test('derives recursive state from snapshot when state key is absent',
        () async {
      final snapshot = AdaptiveRecommendationSnapshot(
        recommendation: _recommendation().copyWith(
          dueWeekKey: '2026-04-06',
          algorithmVersion: 'bayesian_test',
        ),
        maintenanceEstimate: _estimate(dueWeekKey: '2026-04-06'),
        dueWeekKey: '2026-04-06',
        algorithmVersion: 'bayesian_test',
      );
      await repository.saveLatestRecommendationSnapshot(snapshot: snapshot);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(
        'adaptive_nutrition_recommendation.latest_recursive_state',
      );

      final derived = await repository.getLatestEstimatorState();
      final rawPersisted = prefs.getString(
        'adaptive_nutrition_recommendation.latest_recursive_state',
      );

      expect(derived, isNotNull);
      expect(derived!.lastDueWeekKey, '2026-04-06');
      expect(
        derived.posteriorMeanCalories,
        closeTo(
            snapshot.maintenanceEstimate.posteriorMaintenanceCalories, 0.001),
      );
      expect(derived.recentPosteriorMeansCalories, hasLength(1));
      expect(derived.recentObservationResidualsCalories, hasLength(1));
      expect(derived.recentObservationImpliedMaintenanceCalories, hasLength(1));
      expect(rawPersisted, isNotNull);
    });

    test('derives phase tracking state from snapshot when key is absent',
        () async {
      final snapshot = AdaptiveRecommendationSnapshot(
        recommendation: _recommendation().copyWith(
          goal: BodyweightGoal.gainWeight,
          dueWeekKey: '2026-04-06',
          algorithmVersion: 'bayesian_test',
        ),
        maintenanceEstimate: _estimate(dueWeekKey: '2026-04-06'),
        dueWeekKey: '2026-04-06',
        algorithmVersion: 'bayesian_test',
      );
      await repository.saveLatestRecommendationSnapshot(snapshot: snapshot);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(
        'adaptive_nutrition_recommendation.diet_phase_tracking_state',
      );

      final derived = await repository.getDietPhaseTrackingState();
      final rawPersisted = prefs.getString(
        'adaptive_nutrition_recommendation.diet_phase_tracking_state',
      );

      expect(derived, isNotNull);
      expect(derived!.confirmedPhase, AdaptiveDietPhase.bulk);
      expect(
        derived.confirmedPhaseStartDay,
        AdaptiveDietPhaseTrackingState.normalizeDay(DateTime(2026, 4, 6)),
      );
      expect(derived.pendingPhase, isNull);
      expect(rawPersisted, isNotNull);
    });

    test('returns null for incoherent canonical snapshot payload', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'adaptive_nutrition_recommendation.latest_snapshot',
        '{"dueWeekKey":"2026-04-06","algorithmVersion":"bayesian_test",'
            '"recommendation":{"dueWeekKey":"2026-04-06","algorithmVersion":"bayesian_test"},'
            '"maintenanceEstimate":{"dueWeekKey":"2026-04-13"}}',
      );

      final snapshot = await repository.getLatestRecommendationSnapshot();
      expect(snapshot, isNull);
    });

    test('migrates coherent legacy bayesian payload to canonical snapshot',
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

      final snapshot = await repository.getLatestRecommendationSnapshot();
      final rawCanonical = prefs.getString(
        'adaptive_nutrition_recommendation.latest_snapshot',
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.dueWeekKey, '2026-04-06');
      expect(
        snapshot.maintenanceEstimate.posteriorMaintenanceCalories,
        closeTo(estimate.posteriorMaintenanceCalories, 0.001),
      );
      expect(rawCanonical, isNotNull);
    });

    test('migrates legacy generated recommendation into synthetic snapshot',
        () async {
      final recommendation = _recommendation().copyWith(
        dueWeekKey: '2026-03-30',
        algorithmVersion: 'legacy_heuristic',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'adaptive_nutrition_recommendation.latest_generated',
        _encodeRecommendation(recommendation),
      );
      await prefs.setString(
        'adaptive_nutrition_recommendation.last_generated_due_week_key',
        '2026-03-30',
      );

      final snapshot = await repository.getLatestRecommendationSnapshot();

      expect(snapshot, isNotNull);
      expect(snapshot!.dueWeekKey, '2026-03-30');
      expect(
        snapshot.maintenanceEstimate.qualityFlags,
        contains('legacy_generated_snapshot_migration'),
      );
      expect(
        snapshot.maintenanceEstimate.debugInfo['migration'],
        'from_legacy_generated_recommendation',
      );
      expect(
        snapshot.maintenanceEstimate.posteriorMaintenanceCalories,
        recommendation.estimatedMaintenanceCalories.toDouble(),
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
    debugInfo: const {
      'kalmanGain': 0.33,
      'observationResidualCalories': 30,
    },
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
