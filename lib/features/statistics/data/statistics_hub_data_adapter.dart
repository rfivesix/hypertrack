import '../../../data/workout_database_helper.dart';
import '../../../util/body_nutrition_analytics_utils.dart';
import '../domain/consistency_payload_models.dart';
import '../domain/hub_payload_models.dart';
import '../domain/recovery_payload_models.dart';

class StatisticsHubDataAdapter {
  final WorkoutDatabaseHelper _workoutDatabaseHelper;

  const StatisticsHubDataAdapter({
    required WorkoutDatabaseHelper workoutDatabaseHelper,
  }) : _workoutDatabaseHelper = workoutDatabaseHelper;

  Future<(StatisticsHubPayload, BodyNutritionAnalyticsResult)> fetch({
    required int selectedDays,
    required int selectedTimeRangeIndex,
  }) async {
    final prs = _workoutDatabaseHelper.getRecentGlobalPRs(limit: 3);
    final weeklyVolume = _workoutDatabaseHelper.getWeeklyVolumeData(weeksBack: 6);
    final workoutsPerWeek = _workoutDatabaseHelper.getWorkoutsPerWeek(weeksBack: 6);
    final consistencyMetrics =
        _workoutDatabaseHelper.getWeeklyConsistencyMetrics(weeksBack: 6);
    final muscleAnalytics = _workoutDatabaseHelper.getMuscleGroupAnalytics(
      daysBack: selectedDays,
      weeksBack: 8,
    );
    final trainingStats = _workoutDatabaseHelper.getTrainingStats();
    final recoveryAnalytics = _workoutDatabaseHelper.getRecoveryAnalytics();
    final improvements = _workoutDatabaseHelper.getNotablePrImprovements(
      daysWindow: selectedDays > 120 ? 90 : selectedDays,
      limit: 3,
    );
    final bodyNutrition =
        BodyNutritionAnalyticsUtils.build(rangeIndex: selectedTimeRangeIndex);

    final results = await Future.wait<dynamic>([
      prs,
      weeklyVolume,
      workoutsPerWeek,
      consistencyMetrics,
      muscleAnalytics,
      trainingStats,
      recoveryAnalytics,
      improvements,
      bodyNutrition,
    ]);

    final payload = StatisticsHubPayload(
      recentPrs: results[0] as List<Map<String, dynamic>>,
      weeklyVolume: results[1] as List<Map<String, dynamic>>,
      workoutsPerWeek: results[2] as List<Map<String, dynamic>>,
      weeklyConsistencyMetrics: (results[3] as List<Map<String, dynamic>>)
          .map(WeeklyConsistencyMetricPayload.fromMap)
          .toList(),
      muscleAnalytics: results[4] as Map<String, dynamic>,
      trainingStats: TrainingStatsPayload.fromMap(
        results[5] as Map<String, dynamic>,
      ),
      recoveryAnalytics: RecoveryAnalyticsPayload.fromMap(
        results[6] as Map<String, dynamic>,
      ),
      notableImprovements: results[7] as List<Map<String, dynamic>>,
    );

    return (payload, results[8] as BodyNutritionAnalyticsResult);
  }
}
