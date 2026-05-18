// lib/features/workout/domain/classification/workout_classification.dart
import 'dart:convert';

/// Domain utilities for classifying sets and exercises.
class WorkoutClassification {
  static String normalizeAnalyticsToken(String? value) {
    if (value == null) return '';
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[/\\]+'), ' ')
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool looksLikeCardioToken(String? value) {
    final normalized = normalizeAnalyticsToken(value);
    if (normalized.isEmpty) return false;

    const exactCardioTokens = {
      'cardio',
      'run',
      'running',
      'jog',
      'jogging',
      'walk',
      'walking',
      'hike',
      'hiking',
      'bike',
      'biking',
      'cycling',
      'cycle',
      'swim',
      'swimming',
      'rower',
      'rowing',
      'elliptical',
      'treadmill',
      'stairmaster',
      'stepper',
    };

    if (exactCardioTokens.contains(normalized)) return true;

    return normalized.contains('cardio') ||
        normalized.contains('treadmill') ||
        normalized.contains('elliptical') ||
        normalized.contains('stationary bike') ||
        normalized.contains('exercise bike') ||
        normalized.contains('indoor cycling') ||
        normalized.contains('stair master') ||
        normalized.contains('stair climber');
  }

  static bool isRecoveryStrengthWorkSet({
    required String? setType,
    required String? categoryName,
    required String? nameDe,
    required String? nameEn,
    required String? exerciseNameSnapshot,
    required int reps,
  }) {
    if (reps <= 0) return false;

    if (looksLikeCardioToken(setType)) return false;
    if (looksLikeCardioToken(categoryName)) return false;
    if (looksLikeCardioToken(nameDe) ||
        looksLikeCardioToken(nameEn) ||
        looksLikeCardioToken(exerciseNameSnapshot)) {
      return false;
    }

    return true;
  }

  static List<String> parseMuscleList(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    // Fallback for legacy CSV-style muscle lists.
    if (jsonStr.contains(',')) {
      return jsonStr.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }
}
