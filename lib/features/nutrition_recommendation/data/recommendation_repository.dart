import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/adaptive_diet_phase.dart';
import '../domain/adaptive_recommendation_snapshot.dart';
import '../domain/bayesian_tdee_estimator.dart';
import '../domain/goal_models.dart';
import '../domain/recommendation_models.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

class RecommendationRepository {
  static const String _goalKey =
      'adaptive_nutrition_recommendation.goal_direction';
  static const String _targetRateKey =
      'adaptive_nutrition_recommendation.target_rate_kg_per_week';
  static const String _priorActivityLevelKey =
      'adaptive_nutrition_recommendation.prior_activity_level';
  static const String _extraCardioHoursKey =
      'adaptive_nutrition_recommendation.extra_cardio_hours';
  static const String _latestSnapshotKey =
      'adaptive_nutrition_recommendation.latest_snapshot';
  static const String _latestRecursiveStateKey =
      'adaptive_nutrition_recommendation.latest_recursive_state';
  static const String _latestAppliedKey =
      'adaptive_nutrition_recommendation.latest_applied';
  static const String _lastGeneratedDueWeekKey =
      'adaptive_nutrition_recommendation.last_generated_due_week_key';
  static const String _lastDueNotificationWeekKey =
      'adaptive_nutrition_recommendation.last_due_notification_week_key';
  static const String _dietPhaseTrackingStateKey =
      'adaptive_nutrition_recommendation.diet_phase_tracking_state';

  // Legacy keys kept only for one-way migration/fallback support.
  static const String _legacyLatestGeneratedKey =
      'adaptive_nutrition_recommendation.latest_generated';
  static const String _legacyLatestBayesianSnapshotKey =
      'adaptive_nutrition_recommendation.latest_bayesian_experimental_snapshot';
  static const String _legacyLatestGeneratedBayesianKey =
      'adaptive_nutrition_recommendation.latest_generated_bayesian_experimental';
  static const String _legacyLastGeneratedDueWeekBayesianKey =
      'adaptive_nutrition_recommendation.last_generated_due_week_key_bayesian_experimental';
  static const String _legacyLatestBayesianMaintenanceEstimateKey =
      'adaptive_nutrition_recommendation.latest_bayesian_maintenance_estimate';

  final SharedPreferencesLoader _prefsLoader;

  RecommendationRepository({SharedPreferencesLoader? prefsLoader})
      : _prefsLoader = prefsLoader ?? SharedPreferences.getInstance;

  Future<BodyweightGoal> getGoal() async {
    final prefs = await _prefsLoader();
    final value = prefs.getString(_goalKey);
    return BodyweightGoal.values.firstWhere(
      (goal) => goal.name == value,
      orElse: () => BodyweightGoal.maintainWeight,
    );
  }

  Future<double> getTargetRateKgPerWeek() async {
    final prefs = await _prefsLoader();
    final goal = await getGoal();
    final raw = prefs.getDouble(_targetRateKey);
    if (raw == null) {
      return WeeklyTargetRateCatalog.defaultForGoal(goal).kgPerWeek;
    }
    return WeeklyTargetRateCatalog.coerceTargetRate(goal: goal, kgPerWeek: raw);
  }

  Future<void> saveGoalAndTargetRate({
    required BodyweightGoal goal,
    required double targetRateKgPerWeek,
  }) async {
    final prefs = await _prefsLoader();
    final coerced = WeeklyTargetRateCatalog.coerceTargetRate(
      goal: goal,
      kgPerWeek: targetRateKgPerWeek,
    );
    await prefs.setString(_goalKey, goal.name);
    await prefs.setDouble(_targetRateKey, coerced);
  }

  Future<AdaptiveDietPhaseTrackingState?> getDietPhaseTrackingState() async {
    final prefs = await _prefsLoader();
    final encoded = prefs.getString(_dietPhaseTrackingStateKey);
    if (encoded != null && encoded.isNotEmpty) {
      var corrupted = false;
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is Map<String, dynamic>) {
          final state = AdaptiveDietPhaseTrackingState.fromJson(decoded);
          if (state.isValid) {
            return state;
          }
        }
        corrupted = true;
      } catch (_) {
        corrupted = true;
      }
      if (corrupted) {
        await prefs.remove(_dietPhaseTrackingStateKey);
      }
    }

    final snapshot = await getLatestRecommendationSnapshot();
    if (snapshot == null) {
      return null;
    }

    final derivedState = _deriveDietPhaseTrackingStateFromSnapshot(snapshot);
    if (derivedState == null || !derivedState.isValid) {
      return null;
    }
    await saveDietPhaseTrackingState(state: derivedState);
    return derivedState;
  }

  Future<void> saveDietPhaseTrackingState({
    required AdaptiveDietPhaseTrackingState state,
  }) async {
    if (!state.isValid) {
      throw ArgumentError.value(
        state,
        'state',
        'Diet phase tracking state must be valid before persistence.',
      );
    }

    final prefs = await _prefsLoader();
    await prefs.setString(
      _dietPhaseTrackingStateKey,
      jsonEncode(state.toJson()),
    );
  }

  Future<PriorActivityLevel> getPriorActivityLevel() async {
    final prefs = await _prefsLoader();
    final raw = prefs.getString(_priorActivityLevelKey);
    return PriorActivityLevel.values.firstWhere(
      (level) => level.name == raw,
      orElse: () => PriorActivityLevelCatalog.defaultLevel,
    );
  }

  Future<void> savePriorActivityLevel(PriorActivityLevel level) async {
    final prefs = await _prefsLoader();
    await prefs.setString(_priorActivityLevelKey, level.name);
  }

  Future<ExtraCardioHoursOption> getExtraCardioHoursOption() async {
    final prefs = await _prefsLoader();
    final raw = prefs.getString(_extraCardioHoursKey);
    return ExtraCardioHoursOption.values.firstWhere(
      (option) => option.name == raw,
      orElse: () => ExtraCardioHoursCatalog.defaultOption,
    );
  }

  Future<void> saveExtraCardioHoursOption(ExtraCardioHoursOption option) async {
    final prefs = await _prefsLoader();
    await prefs.setString(_extraCardioHoursKey, option.name);
  }

  Future<AdaptiveRecommendationSnapshot?>
      getLatestRecommendationSnapshot() async {
    final prefs = await _prefsLoader();
    final encoded = prefs.getString(_latestSnapshotKey);
    if (encoded != null && encoded.isNotEmpty) {
      var corrupted = false;
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is Map<String, dynamic>) {
          return AdaptiveRecommendationSnapshot.fromJson(decoded);
        }
        corrupted = true;
      } catch (_) {
        corrupted = true;
      }
      if (corrupted) {
        await prefs.remove(_latestSnapshotKey);
      }
    }

    return _migrateLegacySnapshot(prefs);
  }

  Future<void> saveLatestRecommendationSnapshot({
    required AdaptiveRecommendationSnapshot snapshot,
  }) async {
    if (!snapshot.isCoherent) {
      throw ArgumentError.value(
        snapshot,
        'snapshot',
        'Adaptive recommendation snapshot must be coherent before persistence.',
      );
    }

    final prefs = await _prefsLoader();
    await prefs.setString(_latestSnapshotKey, jsonEncode(snapshot.toJson()));
    await prefs.setString(_lastGeneratedDueWeekKey, snapshot.dueWeekKey);
  }

  Future<NutritionRecommendation?> getLatestGeneratedRecommendation() async {
    return (await getLatestRecommendationSnapshot())?.recommendation;
  }

  Future<void> saveLatestGeneratedRecommendation({
    required NutritionRecommendation recommendation,
    required BayesianMaintenanceEstimate maintenanceEstimate,
    BayesianEstimatorState? recursiveState,
  }) async {
    final dueWeekKey = recommendation.dueWeekKey?.trim();
    if (dueWeekKey == null || dueWeekKey.isEmpty) {
      throw ArgumentError.value(
        recommendation.dueWeekKey,
        'recommendation.dueWeekKey',
        'Recommendation dueWeekKey must be present for snapshot persistence.',
      );
    }

    final snapshot = AdaptiveRecommendationSnapshot(
      recommendation: recommendation,
      maintenanceEstimate: maintenanceEstimate,
      dueWeekKey: dueWeekKey,
      algorithmVersion: recommendation.algorithmVersion,
    );
    await saveLatestRecommendationSnapshot(snapshot: snapshot);

    if (recursiveState != null && recursiveState.isValid) {
      await saveLatestEstimatorState(state: recursiveState);
    }
  }

  Future<NutritionRecommendation?> getLatestAppliedRecommendation() async {
    return _loadRecommendation(_latestAppliedKey);
  }

  Future<void> saveLatestAppliedRecommendation({
    required NutritionRecommendation recommendation,
  }) async {
    await _saveRecommendation(_latestAppliedKey, recommendation);
  }

  Future<BayesianEstimatorState?> getLatestEstimatorState() async {
    final prefs = await _prefsLoader();
    final encoded = prefs.getString(_latestRecursiveStateKey);
    if (encoded != null && encoded.isNotEmpty) {
      var corrupted = false;
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is Map<String, dynamic>) {
          final state = BayesianEstimatorState.fromJson(decoded);
          if (state.isValid) {
            return state;
          }
        }
        corrupted = true;
      } catch (_) {
        corrupted = true;
      }
      if (corrupted) {
        await prefs.remove(_latestRecursiveStateKey);
      }
    }

    final snapshot = await getLatestRecommendationSnapshot();
    if (snapshot == null) {
      return null;
    }

    // Backfill recursive state from a coherent snapshot for migration and
    // recovery paths where only snapshot payload exists.
    final derivedState = _deriveEstimatorStateFromSnapshot(snapshot);
    if (derivedState == null || !derivedState.isValid) {
      return null;
    }

    await saveLatestEstimatorState(state: derivedState);
    return derivedState;
  }

  Future<void> saveLatestEstimatorState({
    required BayesianEstimatorState state,
  }) async {
    if (!state.isValid) {
      throw ArgumentError.value(
        state,
        'state',
        'Recursive estimator state must be valid before persistence.',
      );
    }

    final prefs = await _prefsLoader();
    await prefs.setString(
      _latestRecursiveStateKey,
      jsonEncode(state.toJson()),
    );
  }

  Future<String?> getLastGeneratedDueWeekKey() async {
    final prefs = await _prefsLoader();
    final explicit = prefs.getString(_lastGeneratedDueWeekKey);
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    final snapshot = await getLatestRecommendationSnapshot();
    if (snapshot == null) {
      return null;
    }

    await prefs.setString(_lastGeneratedDueWeekKey, snapshot.dueWeekKey);
    return snapshot.dueWeekKey;
  }

  Future<void> setLastGeneratedDueWeekKey(String dueWeekKey) async {
    final prefs = await _prefsLoader();
    await prefs.setString(_lastGeneratedDueWeekKey, dueWeekKey);
  }

  Future<String?> getLastDueNotificationWeekKey() async {
    final prefs = await _prefsLoader();
    return prefs.getString(_lastDueNotificationWeekKey);
  }

  Future<void> setLastDueNotificationWeekKey(String dueWeekKey) async {
    final prefs = await _prefsLoader();
    await prefs.setString(_lastDueNotificationWeekKey, dueWeekKey);
  }

  Future<void> clearForTesting() async {
    final prefs = await _prefsLoader();
    await prefs.remove(_goalKey);
    await prefs.remove(_targetRateKey);
    await prefs.remove(_priorActivityLevelKey);
    await prefs.remove(_extraCardioHoursKey);
    await prefs.remove(_latestSnapshotKey);
    await prefs.remove(_latestRecursiveStateKey);
    await prefs.remove(_latestAppliedKey);
    await prefs.remove(_lastGeneratedDueWeekKey);
    await prefs.remove(_lastDueNotificationWeekKey);
    await prefs.remove(_dietPhaseTrackingStateKey);

    // Legacy keys are still cleaned for deterministic tests.
    await prefs.remove(_legacyLatestGeneratedKey);
    await prefs.remove(_legacyLatestBayesianSnapshotKey);
    await prefs.remove(_legacyLatestGeneratedBayesianKey);
    await prefs.remove(_legacyLastGeneratedDueWeekBayesianKey);
    await prefs.remove(_legacyLatestBayesianMaintenanceEstimateKey);
  }

  Future<AdaptiveRecommendationSnapshot?> _migrateLegacySnapshot(
    SharedPreferences prefs,
  ) async {
    final migrated = await _migrateLegacyBayesianSnapshot(prefs) ??
        await _migrateLegacyFragmentedBayesianSnapshot(prefs) ??
        await _migrateLegacyGeneratedRecommendationSnapshot(prefs);

    if (migrated == null) {
      return null;
    }
    await saveLatestRecommendationSnapshot(snapshot: migrated);
    return migrated;
  }

  Future<AdaptiveRecommendationSnapshot?> _migrateLegacyBayesianSnapshot(
    SharedPreferences prefs,
  ) async {
    final encoded = prefs.getString(_legacyLatestBayesianSnapshotKey);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return AdaptiveRecommendationSnapshot.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<AdaptiveRecommendationSnapshot?>
      _migrateLegacyFragmentedBayesianSnapshot(
    SharedPreferences prefs,
  ) async {
    final recommendation = _loadRecommendationFromPrefs(
      prefs,
      _legacyLatestGeneratedBayesianKey,
    );
    final estimate = _loadEstimateFromPrefs(
      prefs,
      _legacyLatestBayesianMaintenanceEstimateKey,
    );

    if (recommendation == null || estimate == null) {
      return null;
    }

    final dueWeekKey = recommendation.dueWeekKey;
    final estimateDueWeekKey = estimate.dueWeekKey;
    if (dueWeekKey == null ||
        dueWeekKey.isEmpty ||
        estimateDueWeekKey == null ||
        estimateDueWeekKey.isEmpty ||
        dueWeekKey != estimateDueWeekKey) {
      return null;
    }

    final legacyLastGeneratedDueWeekKey =
        prefs.getString(_legacyLastGeneratedDueWeekBayesianKey);
    if (legacyLastGeneratedDueWeekKey != null &&
        legacyLastGeneratedDueWeekKey.isNotEmpty &&
        legacyLastGeneratedDueWeekKey != dueWeekKey) {
      return null;
    }

    final snapshot = AdaptiveRecommendationSnapshot(
      recommendation: recommendation,
      maintenanceEstimate: estimate,
      dueWeekKey: dueWeekKey,
      algorithmVersion: recommendation.algorithmVersion,
    );
    return snapshot.isCoherent ? snapshot : null;
  }

  Future<AdaptiveRecommendationSnapshot?>
      _migrateLegacyGeneratedRecommendationSnapshot(
    SharedPreferences prefs,
  ) async {
    final recommendation =
        _loadRecommendationFromPrefs(prefs, _legacyLatestGeneratedKey);
    if (recommendation == null) {
      return null;
    }

    final dueWeekKey = recommendation.dueWeekKey?.trim() ??
        prefs.getString(_lastGeneratedDueWeekKey)?.trim();
    if (dueWeekKey == null || dueWeekKey.isEmpty) {
      return null;
    }

    final syntheticEstimate = BayesianMaintenanceEstimate(
      posteriorMaintenanceCalories:
          recommendation.estimatedMaintenanceCalories.toDouble(),
      posteriorStdDevCalories:
          const BayesianEstimatorConfig().priorStdDevCalories,
      profilePriorMaintenanceCalories:
          recommendation.estimatedMaintenanceCalories.toDouble(),
      priorMeanUsedCalories:
          recommendation.estimatedMaintenanceCalories.toDouble(),
      priorStdDevUsedCalories:
          const BayesianEstimatorConfig().priorStdDevCalories,
      priorSource: BayesianPriorSource.profilePriorBootstrap,
      observedIntakeCalories: null,
      observedWeightSlopeKgPerWeek: null,
      observationImpliedMaintenanceCalories: null,
      effectiveSampleSize: 0,
      confidence: recommendation.confidence,
      qualityFlags: const <String>['legacy_generated_snapshot_migration'],
      debugInfo: const <String, Object>{
        'migration': 'from_legacy_generated_recommendation',
      },
      dueWeekKey: dueWeekKey,
    );

    return AdaptiveRecommendationSnapshot(
      recommendation: _copyRecommendationWithDueWeekKey(
        recommendation: recommendation,
        dueWeekKey: dueWeekKey,
      ),
      maintenanceEstimate: syntheticEstimate,
      dueWeekKey: dueWeekKey,
      algorithmVersion: recommendation.algorithmVersion,
    );
  }

  BayesianEstimatorState? _deriveEstimatorStateFromSnapshot(
    AdaptiveRecommendationSnapshot snapshot,
  ) {
    final estimate = snapshot.maintenanceEstimate;
    final dueWeekKey = snapshot.dueWeekKey.trim();
    if (dueWeekKey.isEmpty) {
      return null;
    }
    if (!estimate.posteriorMaintenanceCalories.isFinite ||
        !estimate.posteriorStdDevCalories.isFinite ||
        estimate.posteriorStdDevCalories <= 0 ||
        !estimate.priorMeanUsedCalories.isFinite ||
        !estimate.priorStdDevUsedCalories.isFinite ||
        estimate.priorStdDevUsedCalories <= 0) {
      return null;
    }

    final posteriorVariance =
        math.pow(estimate.posteriorStdDevCalories, 2).toDouble();
    final priorVariance =
        math.pow(estimate.priorStdDevUsedCalories, 2).toDouble();
    final residualFromDebug =
        _asDouble(estimate.debugInfo['observationResidualCalories']);
    final observedMaintenance = estimate.observationImpliedMaintenanceCalories;

    final state = BayesianEstimatorState(
      posteriorMeanCalories: estimate.posteriorMaintenanceCalories,
      posteriorVarianceCalories2: posteriorVariance,
      lastDueWeekKey: dueWeekKey,
      lastPriorMeanCalories: estimate.priorMeanUsedCalories,
      lastPriorVarianceCalories2: priorVariance,
      lastPriorSource: estimate.priorSource,
      lastObservationUsed:
          estimate.observationImpliedMaintenanceCalories != null,
      recentPosteriorMeansCalories: <double>[
        estimate.posteriorMaintenanceCalories,
      ],
      recentObservationResidualsCalories: residualFromDebug == null
          ? const <double>[]
          : <double>[residualFromDebug],
      recentObservationImpliedMaintenanceCalories: observedMaintenance == null
          ? const <double>[]
          : <double>[observedMaintenance],
    );

    return state.isValid ? state : null;
  }

  AdaptiveDietPhaseTrackingState? _deriveDietPhaseTrackingStateFromSnapshot(
    AdaptiveRecommendationSnapshot snapshot,
  ) {
    final recommendation = snapshot.recommendation;
    final dueWeekDay = DateTime.tryParse(snapshot.dueWeekKey.trim());
    final confirmedStartDay = AdaptiveDietPhaseTrackingState.normalizeDay(
      dueWeekDay ?? recommendation.generatedAt,
    );
    final phase = recommendation.goal.canonicalDietPhase;

    return AdaptiveDietPhaseTrackingState(
      confirmedPhase: phase,
      confirmedPhaseStartDay: confirmedStartDay,
      pendingPhase: null,
      pendingPhaseFirstSeenDay: null,
    );
  }

  Future<void> _saveRecommendation(
    String key,
    NutritionRecommendation recommendation,
  ) async {
    final prefs = await _prefsLoader();
    await prefs.setString(key, jsonEncode(recommendation.toJson()));
  }

  Future<NutritionRecommendation?> _loadRecommendation(String key) async {
    final prefs = await _prefsLoader();
    return _loadRecommendationFromPrefs(prefs, key);
  }

  NutritionRecommendation? _loadRecommendationFromPrefs(
    SharedPreferences prefs,
    String key,
  ) {
    final encoded = prefs.getString(key);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return NutritionRecommendation.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  BayesianMaintenanceEstimate? _loadEstimateFromPrefs(
    SharedPreferences prefs,
    String key,
  ) {
    final encoded = prefs.getString(key);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return BayesianMaintenanceEstimate.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  double? _asDouble(Object? value) {
    return switch (value) {
      num() => value.toDouble(),
      _ => null,
    };
  }

  NutritionRecommendation _copyRecommendationWithDueWeekKey({
    required NutritionRecommendation recommendation,
    required String dueWeekKey,
  }) {
    return NutritionRecommendation(
      recommendedCalories: recommendation.recommendedCalories,
      recommendedProteinGrams: recommendation.recommendedProteinGrams,
      recommendedCarbsGrams: recommendation.recommendedCarbsGrams,
      recommendedFatGrams: recommendation.recommendedFatGrams,
      estimatedMaintenanceCalories: recommendation.estimatedMaintenanceCalories,
      goal: recommendation.goal,
      targetRateKgPerWeek: recommendation.targetRateKgPerWeek,
      confidence: recommendation.confidence,
      warningState: recommendation.warningState,
      generatedAt: recommendation.generatedAt,
      windowStart: recommendation.windowStart,
      windowEnd: recommendation.windowEnd,
      algorithmVersion: recommendation.algorithmVersion,
      inputSummary: recommendation.inputSummary,
      baselineCalories: recommendation.baselineCalories,
      dueWeekKey: dueWeekKey,
    );
  }
}
