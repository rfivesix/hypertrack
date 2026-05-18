import '../../workout/data/sources/workout_local_data_source.dart';
import '../../../util/body_nutrition_analytics_utils.dart';
import '../../../util/perf_debug_timer.dart';
import '../domain/consistency_payload_models.dart';
import '../domain/hub_payload_models.dart';
import '../domain/recovery_domain_service.dart';
import '../domain/recovery_payload_models.dart';
import '../domain/statistics_range_policy.dart';

class StatisticsHubDataAdapter {
  final WorkoutLocalDataSource _workoutDatabaseHelper;
  final StatisticsRangePolicyService _rangePolicy;

  const StatisticsHubDataAdapter({
    required WorkoutLocalDataSource workoutDatabaseHelper,
    StatisticsRangePolicyService rangePolicy =
        StatisticsRangePolicyService.instance,
  })  : _workoutDatabaseHelper = workoutDatabaseHelper,
        _rangePolicy = rangePolicy;

  Future<(StatisticsHubPayload, BodyNutritionAnalyticsResult)> fetch({
    required int selectedTimeRangeIndex,
  }) async {
    final adapterStopwatch = Stopwatch()..start();
    final selectedDays = _rangePolicy.selectedDaysFromIndex(
      selectedTimeRangeIndex,
    );
    final weeklyVolumeRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.hubWeeklyVolume,
      selectedRangeIndex: selectedTimeRangeIndex,
    );
    final workoutsPerWeekRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.hubWorkoutsPerWeek,
      selectedRangeIndex: selectedTimeRangeIndex,
    );
    final consistencyRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.hubConsistencyMetrics,
      selectedRangeIndex: selectedTimeRangeIndex,
    );
    final recoveryRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.hubRecoveryReadiness,
      selectedRangeIndex: selectedTimeRangeIndex,
    );
    final muscleRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.hubMuscleAnalytics,
      selectedRangeIndex: selectedTimeRangeIndex,
    );
    final improvementRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.hubNotablePrImprovements,
      selectedRangeIndex: selectedTimeRangeIndex,
      selectedDays: selectedDays,
    );

    try {
      final prs = PerfDebugTimer.time(
        area: 'statistics',
        label: 'prSummary',
        action: () => _workoutDatabaseHelper.getRecentGlobalPRs(limit: 3),
      );
      final weeklyVolume = PerfDebugTimer.time(
        area: 'statistics',
        label: 'weeklyVolume',
        action: () => _workoutDatabaseHelper.getWeeklyVolumeData(
          weeksBack: weeklyVolumeRange.effectiveWeeks ?? 6,
        ),
      );
      final workoutsPerWeek = PerfDebugTimer.time(
        area: 'statistics',
        label: 'workoutsPerWeek',
        action: () => _workoutDatabaseHelper.getWorkoutsPerWeek(
          weeksBack: workoutsPerWeekRange.effectiveWeeks ?? 6,
        ),
      );
      final consistencyMetrics = PerfDebugTimer.time(
        area: 'statistics',
        label: 'consistency',
        action: () => _workoutDatabaseHelper.getWeeklyConsistencyMetrics(
          weeksBack: consistencyRange.effectiveWeeks ?? 6,
        ),
      );
      final muscleAnalytics = PerfDebugTimer.time(
        area: 'statistics',
        label: 'muscleAnalytics',
        action: () => _workoutDatabaseHelper.getMuscleGroupAnalytics(
          daysBack: selectedDays,
          weeksBack: muscleRange.effectiveWeeks ?? 8,
        ),
        fields: {'range': '${selectedDays}d'},
      );
      final trainingStats = PerfDebugTimer.time(
        area: 'statistics',
        label: 'trainingStats',
        action: _workoutDatabaseHelper.getTrainingStats,
      );
      final recoveryAnalytics = PerfDebugTimer.time(
        area: 'statistics',
        label: 'recovery',
        action: () => _workoutDatabaseHelper.getRecoveryAnalytics(
          lookbackDays: recoveryRange.effectiveDays ??
              RecoveryDomainService.recoveryLookbackDays,
        ),
      );
      final improvements = PerfDebugTimer.time(
        area: 'statistics',
        label: 'notablePrImprovements',
        action: () => _workoutDatabaseHelper.getNotablePrImprovements(
          daysWindow: improvementRange.effectiveDays ?? selectedDays,
          limit: 3,
        ),
      );
      final bodyNutrition = PerfDebugTimer.time(
        area: 'statistics',
        label: 'bodyNutrition',
        action: () => BodyNutritionAnalyticsUtils.build(
          rangeIndex: selectedTimeRangeIndex,
        ),
        fields: {'range': '${selectedDays}d'},
      );

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
    } finally {
      adapterStopwatch.stop();
      PerfDebugTimer.logDuration(
        area: 'statistics',
        label: 'adapterFetch',
        metric: 'total',
        elapsed: adapterStopwatch.elapsed,
        fields: {'range': '${selectedDays}d'},
      );
    }
  }

  Future<RecoveryAnalyticsPayload> fetchRecovery({
    required int selectedTimeRangeIndex,
  }) async {
    final recoveryRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.hubRecoveryReadiness,
      selectedRangeIndex: selectedTimeRangeIndex,
    );
    final recoveryAnalytics = await PerfDebugTimer.time(
      area: 'statistics',
      label: 'recovery',
      action: () => _workoutDatabaseHelper.getRecoveryAnalytics(
        lookbackDays: recoveryRange.effectiveDays ??
            RecoveryDomainService.recoveryLookbackDays,
      ),
      fields: {'fixed': '${recoveryRange.effectiveDays}d'},
    );
    return RecoveryAnalyticsPayload.fromMap(recoveryAnalytics);
  }

  Future<
      ({
        List<Map<String, dynamic>> workoutsPerWeek,
        List<WeeklyConsistencyMetricPayload> weeklyConsistencyMetrics,
        TrainingStatsPayload trainingStats,
      })> fetchConsistency({
    required int selectedTimeRangeIndex,
  }) async {
    final workoutsPerWeekRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.hubWorkoutsPerWeek,
      selectedRangeIndex: selectedTimeRangeIndex,
    );
    final consistencyRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.hubConsistencyMetrics,
      selectedRangeIndex: selectedTimeRangeIndex,
    );

    final results = await Future.wait<dynamic>([
      PerfDebugTimer.time(
        area: 'statistics',
        label: 'workoutsPerWeek',
        action: () => _workoutDatabaseHelper.getWorkoutsPerWeek(
          weeksBack: workoutsPerWeekRange.effectiveWeeks ?? 6,
        ),
      ),
      PerfDebugTimer.time(
        area: 'statistics',
        label: 'consistency',
        action: () => _workoutDatabaseHelper.getWeeklyConsistencyMetrics(
          weeksBack: consistencyRange.effectiveWeeks ?? 6,
        ),
      ),
      PerfDebugTimer.time(
        area: 'statistics',
        label: 'trainingStats',
        action: _workoutDatabaseHelper.getTrainingStats,
      ),
    ]);

    return (
      workoutsPerWeek: results[0] as List<Map<String, dynamic>>,
      weeklyConsistencyMetrics: (results[1] as List<Map<String, dynamic>>)
          .map(WeeklyConsistencyMetricPayload.fromMap)
          .toList(),
      trainingStats: TrainingStatsPayload.fromMap(
        results[2] as Map<String, dynamic>,
      ),
    );
  }

  Future<
      ({
        List<Map<String, dynamic>> recentPrs,
        List<Map<String, dynamic>> notableImprovements,
      })> fetchPerformanceRecords({
    required int selectedTimeRangeIndex,
  }) async {
    final selectedDays = _rangePolicy.selectedDaysFromIndex(
      selectedTimeRangeIndex,
    );
    final improvementRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.hubNotablePrImprovements,
      selectedRangeIndex: selectedTimeRangeIndex,
      selectedDays: selectedDays,
    );

    final results = await Future.wait<dynamic>([
      PerfDebugTimer.time(
        area: 'statistics',
        label: 'prSummary',
        action: () => _workoutDatabaseHelper.getRecentGlobalPRs(limit: 3),
      ),
      PerfDebugTimer.time(
        area: 'statistics',
        label: 'notablePrImprovements',
        action: () => _workoutDatabaseHelper.getNotablePrImprovements(
          daysWindow: improvementRange.effectiveDays ?? selectedDays,
          limit: 3,
        ),
      ),
    ]);

    return (
      recentPrs: results[0] as List<Map<String, dynamic>>,
      notableImprovements: results[1] as List<Map<String, dynamic>>,
    );
  }

  Future<
      ({
        List<Map<String, dynamic>> weeklyVolume,
        Map<String, dynamic> muscleAnalytics,
      })> fetchVolumeMuscles({
    required int selectedTimeRangeIndex,
  }) async {
    final selectedDays = _rangePolicy.selectedDaysFromIndex(
      selectedTimeRangeIndex,
    );
    final weeklyVolumeRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.hubWeeklyVolume,
      selectedRangeIndex: selectedTimeRangeIndex,
    );
    final muscleRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.hubMuscleAnalytics,
      selectedRangeIndex: selectedTimeRangeIndex,
    );

    final results = await Future.wait<dynamic>([
      PerfDebugTimer.time(
        area: 'statistics',
        label: 'weeklyVolume',
        action: () => _workoutDatabaseHelper.getWeeklyVolumeData(
          weeksBack: weeklyVolumeRange.effectiveWeeks ?? 6,
        ),
      ),
      PerfDebugTimer.time(
        area: 'statistics',
        label: 'muscleAnalytics',
        action: () => _workoutDatabaseHelper.getMuscleGroupAnalytics(
          daysBack: selectedDays,
          weeksBack: muscleRange.effectiveWeeks ?? 8,
        ),
        fields: {'range': '${selectedDays}d'},
      ),
    ]);

    return (
      weeklyVolume: results[0] as List<Map<String, dynamic>>,
      muscleAnalytics: results[1] as Map<String, dynamic>,
    );
  }

  Future<BodyNutritionAnalyticsResult> fetchBodyNutrition({
    required int selectedTimeRangeIndex,
  }) {
    final selectedDays = _rangePolicy.selectedDaysFromIndex(
      selectedTimeRangeIndex,
    );
    return PerfDebugTimer.time(
      area: 'statistics',
      label: 'bodyNutrition',
      action: () => BodyNutritionAnalyticsUtils.build(
        rangeIndex: selectedTimeRangeIndex,
      ),
      fields: {'range': '${selectedDays}d'},
    );
  }
}
