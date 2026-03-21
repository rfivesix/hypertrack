import 'consistency_payload_models.dart';
import 'recovery_payload_models.dart';

class StatisticsHubPayload {
  final List<Map<String, dynamic>> recentPrs;
  final List<Map<String, dynamic>> weeklyVolume;
  final List<Map<String, dynamic>> workoutsPerWeek;
  final List<WeeklyConsistencyMetricPayload> weeklyConsistencyMetrics;
  final Map<String, dynamic> muscleAnalytics;
  final TrainingStatsPayload trainingStats;
  final RecoveryAnalyticsPayload recoveryAnalytics;
  final List<Map<String, dynamic>> notableImprovements;

  const StatisticsHubPayload({
    required this.recentPrs,
    required this.weeklyVolume,
    required this.workoutsPerWeek,
    required this.weeklyConsistencyMetrics,
    required this.muscleAnalytics,
    required this.trainingStats,
    required this.recoveryAnalytics,
    required this.notableImprovements,
  });
}
