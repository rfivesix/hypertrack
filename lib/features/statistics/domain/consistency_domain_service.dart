import 'consistency_payload_models.dart';

class ConsistencyDomainService {
  const ConsistencyDomainService._();

  static String formatTrend(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}';
  }

  static double computeTrainingDaysPerWeekLast4({
    required Map<DateTime, int> workoutDayCounts,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final since = effectiveNow.subtract(const Duration(days: 28));
    final activeDays = workoutDayCounts.entries
        .where((e) => e.key.isAfter(since) || e.key.isAtSameMomentAs(since))
        .where((e) => e.value > 0)
        .length;
    return activeDays / 4.0;
  }

  static double computeRhythmDelta({
    required List<WeeklyConsistencyMetricPayload> weeklyMetrics,
  }) {
    if (weeklyMetrics.length < 8) return 0;
    final recent = weeklyMetrics.sublist(weeklyMetrics.length - 4);
    final prior = weeklyMetrics.sublist(
        weeklyMetrics.length - 8, weeklyMetrics.length - 4);
    final recentAvg =
        recent.map((e) => e.count.toDouble()).reduce((a, b) => a + b) / 4.0;
    final priorAvg =
        prior.map((e) => e.count.toDouble()).reduce((a, b) => a + b) / 4.0;
    return recentAvg - priorAvg;
  }

  static double rollingConsistencyPercent({
    required List<WeeklyConsistencyMetricPayload> weeklyMetrics,
  }) {
    if (weeklyMetrics.isEmpty) return 0;
    final recent = weeklyMetrics.length > 8
        ? weeklyMetrics.sublist(weeklyMetrics.length - 8)
        : weeklyMetrics;
    final consistentWeeks = recent.where((e) => e.count >= 2).length;
    return (consistentWeeks / recent.length) * 100.0;
  }
}
