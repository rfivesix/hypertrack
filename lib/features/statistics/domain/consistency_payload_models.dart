class TrainingStatsPayload {
  final int totalWorkouts;
  final int thisWeekCount;
  final double avgPerWeek;
  final int streakWeeks;

  const TrainingStatsPayload({
    required this.totalWorkouts,
    required this.thisWeekCount,
    required this.avgPerWeek,
    required this.streakWeeks,
  });

  factory TrainingStatsPayload.fromMap(Map<String, dynamic> data) {
    final totalWorkouts = data['totalWorkouts'];
    final thisWeekCount = data['thisWeekCount'];
    final avgPerWeek = data['avgPerWeek'];
    final streakWeeks = data['streakWeeks'];

    return TrainingStatsPayload(
      totalWorkouts: totalWorkouts is num ? totalWorkouts.toInt() : 0,
      thisWeekCount: thisWeekCount is num ? thisWeekCount.toInt() : 0,
      avgPerWeek: avgPerWeek is num ? avgPerWeek.toDouble() : 0.0,
      streakWeeks: streakWeeks is num ? streakWeeks.toInt() : 0,
    );
  }
}

class WeeklyConsistencyMetricPayload {
  final DateTime weekStart;
  final String weekLabel;
  final int count;
  final double durationMinutes;
  final double tonnage;

  const WeeklyConsistencyMetricPayload({
    required this.weekStart,
    required this.weekLabel,
    required this.count,
    required this.durationMinutes,
    required this.tonnage,
  });

  factory WeeklyConsistencyMetricPayload.fromMap(Map<String, dynamic> data) {
    final weekStart = data['weekStart'];
    final weekLabel = data['weekLabel'];
    final count = data['count'];
    final durationMinutes = data['durationMinutes'];
    final tonnage = data['tonnage'];

    return WeeklyConsistencyMetricPayload(
      weekStart: weekStart is DateTime
          ? weekStart
          : DateTime.fromMillisecondsSinceEpoch(0),
      weekLabel: weekLabel is String ? weekLabel : '',
      count: count is num ? count.toInt() : 0,
      durationMinutes:
          durationMinutes is num ? durationMinutes.toDouble() : 0.0,
      tonnage: tonnage is num ? tonnage.toDouble() : 0.0,
    );
  }
}
