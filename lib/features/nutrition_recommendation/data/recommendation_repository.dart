import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/bayesian_experimental_snapshot.dart';
import '../domain/bayesian_tdee_estimator.dart';
import '../domain/goal_models.dart';
import '../domain/recommendation_estimation_mode.dart';
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
  static const String _latestGeneratedKey =
      'adaptive_nutrition_recommendation.latest_generated';
  static const String _latestAppliedKey =
      'adaptive_nutrition_recommendation.latest_applied';
  static const String _lastGeneratedDueWeekKey =
      'adaptive_nutrition_recommendation.last_generated_due_week_key';
  static const String _lastDueNotificationWeekKey =
      'adaptive_nutrition_recommendation.last_due_notification_week_key';
  static const String _latestBayesianExperimentalSnapshotKey =
      'adaptive_nutrition_recommendation.latest_bayesian_experimental_snapshot';
  // Legacy fragmented Bayesian experimental keys.
  // These remain readable for one-way migration only.
  static const String _latestGeneratedBayesianExperimentalKey =
      'adaptive_nutrition_recommendation.latest_generated_bayesian_experimental';
  static const String _lastGeneratedDueWeekBayesianExperimentalKey =
      'adaptive_nutrition_recommendation.last_generated_due_week_key_bayesian_experimental';
  static const String _latestBayesianMaintenanceEstimateKey =
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

  Future<NutritionRecommendation?> getLatestGeneratedRecommendation() async {
    return getLatestGeneratedRecommendationForMode(
      mode: RecommendationEstimationMode.heuristic,
    );
  }

  Future<void> saveLatestGeneratedRecommendation({
    required NutritionRecommendation recommendation,
  }) async {
    await saveLatestGeneratedRecommendationForMode(
      mode: RecommendationEstimationMode.heuristic,
      recommendation: recommendation,
    );
  }

  Future<NutritionRecommendation?> getLatestAppliedRecommendation() async {
    return _loadRecommendation(_latestAppliedKey);
  }

  Future<void> saveLatestAppliedRecommendation({
    required NutritionRecommendation recommendation,
  }) async {
    await _saveRecommendation(_latestAppliedKey, recommendation);
  }

  Future<String?> getLastGeneratedDueWeekKey() async {
    return getLastGeneratedDueWeekKeyForMode(
      mode: RecommendationEstimationMode.heuristic,
    );
  }

  Future<void> setLastGeneratedDueWeekKey(String dueWeekKey) async {
    await setLastGeneratedDueWeekKeyForMode(
      mode: RecommendationEstimationMode.heuristic,
      dueWeekKey: dueWeekKey,
    );
  }

  Future<String?> getLastDueNotificationWeekKey() async {
    final prefs = await _prefsLoader();
    return prefs.getString(_lastDueNotificationWeekKey);
  }

  Future<void> setLastDueNotificationWeekKey(String dueWeekKey) async {
    final prefs = await _prefsLoader();
    await prefs.setString(_lastDueNotificationWeekKey, dueWeekKey);
  }

  Future<NutritionRecommendation?> getLatestGeneratedRecommendationForMode({
    required RecommendationEstimationMode mode,
  }) async {
    switch (mode) {
      case RecommendationEstimationMode.heuristic:
        return _loadRecommendation(_latestGeneratedKey);
      case RecommendationEstimationMode.bayesianExperimental:
        // Bayesian experimental mode no longer uses fragmented persistence keys.
        throw UnsupportedError(
          'Bayesian experimental mode uses atomic snapshot persistence. '
          'Legacy fragmented recommendation keys are migration-only.',
        );
    }
  }

  Future<void> saveLatestGeneratedRecommendationForMode({
    required RecommendationEstimationMode mode,
    required NutritionRecommendation recommendation,
  }) async {
    switch (mode) {
      case RecommendationEstimationMode.heuristic:
        await _saveRecommendation(_latestGeneratedKey, recommendation);
        if (recommendation.dueWeekKey != null &&
            recommendation.dueWeekKey!.isNotEmpty) {
          await setLastGeneratedDueWeekKeyForMode(
            mode: mode,
            dueWeekKey: recommendation.dueWeekKey!,
          );
        }
        return;
      case RecommendationEstimationMode.bayesianExperimental:
        // Bayesian experimental mode no longer uses fragmented persistence keys.
        throw UnsupportedError(
          'Bayesian experimental mode uses atomic snapshot persistence. '
          'Legacy fragmented recommendation keys are migration-only.',
        );
    }
  }

  Future<String?> getLastGeneratedDueWeekKeyForMode({
    required RecommendationEstimationMode mode,
  }) async {
    switch (mode) {
      case RecommendationEstimationMode.heuristic:
        final prefs = await _prefsLoader();
        return prefs.getString(_lastGeneratedDueWeekKey);
      case RecommendationEstimationMode.bayesianExperimental:
        // Bayesian experimental mode no longer uses fragmented persistence keys.
        throw UnsupportedError(
          'Bayesian experimental mode uses atomic snapshot persistence. '
          'Legacy fragmented due-week keys are migration-only.',
        );
    }
  }

  Future<void> setLastGeneratedDueWeekKeyForMode({
    required RecommendationEstimationMode mode,
    required String dueWeekKey,
  }) async {
    switch (mode) {
      case RecommendationEstimationMode.heuristic:
        final prefs = await _prefsLoader();
        await prefs.setString(_lastGeneratedDueWeekKey, dueWeekKey);
        return;
      case RecommendationEstimationMode.bayesianExperimental:
        // Bayesian experimental mode no longer uses fragmented persistence keys.
        throw UnsupportedError(
          'Bayesian experimental mode uses atomic snapshot persistence. '
          'Legacy fragmented due-week keys are migration-only.',
        );
    }
  }

  Future<BayesianExperimentalRecommendationSnapshot?>
      getLatestBayesianExperimentalSnapshot() async {
    final prefs = await _prefsLoader();
    final encoded = prefs.getString(_latestBayesianExperimentalSnapshotKey);
    if (encoded != null && encoded.isNotEmpty) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is! Map<String, dynamic>) {
          return null;
        }
        return BayesianExperimentalRecommendationSnapshot.fromJson(decoded);
      } catch (_) {
        return null;
      }
    }

    // Legacy one-way migration fallback:
    // only if no atomic snapshot exists, attempt to migrate coherent
    // fragmented legacy keys into the snapshot key.
    return _migrateLegacyBayesianExperimentalSnapshot(prefs);
  }

  Future<void> saveLatestBayesianExperimentalSnapshot({
    required BayesianExperimentalRecommendationSnapshot snapshot,
  }) async {
    if (!snapshot.isCoherent) {
      throw ArgumentError.value(
        snapshot,
        'snapshot',
        'Bayesian experimental snapshot must be coherent before persistence.',
      );
    }

    final prefs = await _prefsLoader();
    await prefs.setString(
      _latestBayesianExperimentalSnapshotKey,
      jsonEncode(snapshot.toJson()),
    );
  }

  Future<void> clearForTesting() async {
    final prefs = await _prefsLoader();
    await prefs.remove(_goalKey);
    await prefs.remove(_targetRateKey);
    await prefs.remove(_priorActivityLevelKey);
    await prefs.remove(_extraCardioHoursKey);
    await prefs.remove(_latestGeneratedKey);
    await prefs.remove(_latestAppliedKey);
    await prefs.remove(_lastGeneratedDueWeekKey);
    await prefs.remove(_lastDueNotificationWeekKey);
    await prefs.remove(_latestBayesianExperimentalSnapshotKey);
    await prefs.remove(_latestGeneratedBayesianExperimentalKey);
    await prefs.remove(_lastGeneratedDueWeekBayesianExperimentalKey);
    await prefs.remove(_latestBayesianMaintenanceEstimateKey);
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

  Future<BayesianExperimentalRecommendationSnapshot?>
      _migrateLegacyBayesianExperimentalSnapshot(
          SharedPreferences prefs) async {
    final recommendation = _loadRecommendationFromPrefs(
      prefs,
      _latestGeneratedBayesianExperimentalKey,
    );
    final estimate = _loadEstimateFromPrefs(
      prefs,
      _latestBayesianMaintenanceEstimateKey,
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
        prefs.getString(_lastGeneratedDueWeekBayesianExperimentalKey);
    if (legacyLastGeneratedDueWeekKey != null &&
        legacyLastGeneratedDueWeekKey.isNotEmpty &&
        legacyLastGeneratedDueWeekKey != dueWeekKey) {
      return null;
    }

    final snapshot = BayesianExperimentalRecommendationSnapshot(
      recommendation: recommendation,
      maintenanceEstimate: estimate,
      dueWeekKey: dueWeekKey,
      algorithmVersion: recommendation.algorithmVersion,
    );
    if (!snapshot.isCoherent) {
      return null;
    }

    await prefs.setString(
      _latestBayesianExperimentalSnapshotKey,
      jsonEncode(snapshot.toJson()),
    );
    return snapshot;
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
}
