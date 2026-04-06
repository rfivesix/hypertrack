import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

  Future<NutritionRecommendation?> getLatestGeneratedRecommendationForMode({
    required RecommendationEstimationMode mode,
  }) async {
    return _loadRecommendation(_latestGeneratedKeyForMode(mode));
  }

  Future<void> saveLatestGeneratedRecommendationForMode({
    required RecommendationEstimationMode mode,
    required NutritionRecommendation recommendation,
  }) async {
    await _saveRecommendation(_latestGeneratedKeyForMode(mode), recommendation);
    if (recommendation.dueWeekKey != null &&
        recommendation.dueWeekKey!.isNotEmpty) {
      await setLastGeneratedDueWeekKeyForMode(
        mode: mode,
        dueWeekKey: recommendation.dueWeekKey!,
      );
    }
  }

  Future<String?> getLastGeneratedDueWeekKeyForMode({
    required RecommendationEstimationMode mode,
  }) async {
    final prefs = await _prefsLoader();
    return prefs.getString(_lastGeneratedDueWeekKeyForMode(mode));
  }

  Future<void> setLastGeneratedDueWeekKeyForMode({
    required RecommendationEstimationMode mode,
    required String dueWeekKey,
  }) async {
    final prefs = await _prefsLoader();
    await prefs.setString(_lastGeneratedDueWeekKeyForMode(mode), dueWeekKey);
  }

  Future<BayesianMaintenanceEstimate?>
      getLatestBayesianMaintenanceEstimate() async {
    final prefs = await _prefsLoader();
    final encoded = prefs.getString(_latestBayesianMaintenanceEstimateKey);
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

  Future<void> saveLatestBayesianMaintenanceEstimate({
    required BayesianMaintenanceEstimate estimate,
  }) async {
    final prefs = await _prefsLoader();
    await prefs.setString(
      _latestBayesianMaintenanceEstimateKey,
      jsonEncode(estimate.toJson()),
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
    await prefs.remove(_latestGeneratedBayesianExperimentalKey);
    await prefs.remove(_lastGeneratedDueWeekBayesianExperimentalKey);
    await prefs.remove(_latestBayesianMaintenanceEstimateKey);
  }

  String _latestGeneratedKeyForMode(RecommendationEstimationMode mode) {
    switch (mode) {
      case RecommendationEstimationMode.heuristic:
        return _latestGeneratedKey;
      case RecommendationEstimationMode.bayesianExperimental:
        return _latestGeneratedBayesianExperimentalKey;
    }
  }

  String _lastGeneratedDueWeekKeyForMode(RecommendationEstimationMode mode) {
    switch (mode) {
      case RecommendationEstimationMode.heuristic:
        return _lastGeneratedDueWeekKey;
      case RecommendationEstimationMode.bayesianExperimental:
        return _lastGeneratedDueWeekBayesianExperimentalKey;
    }
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
}
