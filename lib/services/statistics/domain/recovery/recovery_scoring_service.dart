import '../../../../models/exercise.dart';
import '../../../../models/set_log.dart';

/// Canonical recovery-related scoring helpers for statistics flows.
///
/// This service is intentionally pure and side-effect free so UI layers can
/// delegate score/state interpretation without changing behavior.
class RecoveryScoringService {
  const RecoveryScoringService._();

  /// Computes total strength volume using the existing weight * reps logic.
  static double totalVolume(List<SetLog> sets) {
    double total = 0.0;
    for (final set in sets) {
      total += (set.weightKg ?? 0) * (set.reps ?? 0);
    }
    return total;
  }

  /// Groups strength volume by exercise category.
  static Map<String, double> categoryVolume(
    List<SetLog> sets,
    Map<String, Exercise> exerciseDetails,
  ) {
    final categoryVolume = <String, double>{};
    for (final set in sets) {
      final volume = (set.weightKg ?? 0) * (set.reps ?? 0);
      if (volume > 0) {
        final category = exerciseDetails[set.exerciseName]?.categoryName ?? 'Other';
        categoryVolume.update(category, (current) => current + volume, ifAbsent: () => volume);
      }
    }
    return categoryVolume;
  }

  /// Returns the share (0..1) of [value] within [total].
  static double share(double value, double total) {
    if (total <= 0) return 0.0;
    return value / total;
  }
}
