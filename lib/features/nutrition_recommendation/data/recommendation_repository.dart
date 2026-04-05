import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/goal_models.dart';
import '../domain/recommendation_models.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

class RecommendationRepository {
  static const String _goalKey =
      'adaptive_nutrition_recommendation.goal_direction';
  static const String _targetRateKey =
      'adaptive_nutrition_recommendation.target_rate_kg_per_week';
  static const String _latestGeneratedKey =
      'adaptive_nutrition_recommendation.latest_generated';
  static const String _latestAppliedKey =
      'adaptive_nutrition_recommendation.latest_applied';
  static const String _lastGeneratedDueWeekKey =
      'adaptive_nutrition_recommendation.last_generated_due_week_key';

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

  Future<NutritionRecommendation?> getLatestGeneratedRecommendation() async {
    return _loadRecommendation(_latestGeneratedKey);
  }

  Future<void> saveLatestGeneratedRecommendation({
    required NutritionRecommendation recommendation,
  }) async {
    await _saveRecommendation(_latestGeneratedKey, recommendation);
    if (recommendation.dueWeekKey != null &&
        recommendation.dueWeekKey!.isNotEmpty) {
      final prefs = await _prefsLoader();
      await prefs.setString(
        _lastGeneratedDueWeekKey,
        recommendation.dueWeekKey!,
      );
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

  Future<String?> getLastGeneratedDueWeekKey() async {
    final prefs = await _prefsLoader();
    return prefs.getString(_lastGeneratedDueWeekKey);
  }

  Future<void> setLastGeneratedDueWeekKey(String dueWeekKey) async {
    final prefs = await _prefsLoader();
    await prefs.setString(_lastGeneratedDueWeekKey, dueWeekKey);
  }

  Future<void> clearForTesting() async {
    final prefs = await _prefsLoader();
    await prefs.remove(_goalKey);
    await prefs.remove(_targetRateKey);
    await prefs.remove(_latestGeneratedKey);
    await prefs.remove(_latestAppliedKey);
    await prefs.remove(_lastGeneratedDueWeekKey);
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
