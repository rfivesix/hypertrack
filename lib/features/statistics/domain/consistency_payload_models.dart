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
    return TrainingStatsPayload(
      totalWorkouts: (data['totalWorkouts'] as num?)?.toInt() ?? 0,
      thisWeekCount: (data['thisWeekCount'] as num?)?.toInt() ?? 0,
      avgPerWeek: (data['avgPerWeek'] as num?)?.toDouble() ?? 0.0,
      streakWeeks: (data['streakWeeks'] as num?)?.toInt() ?? 0,
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
    return WeeklyConsistencyMetricPayload(
      weekStart: data['weekStart'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0),
      weekLabel: data['weekLabel'] as String? ?? '',
      count: (data['count'] as num?)?.toInt() ?? 0,
      durationMinutes: (data['durationMinutes'] as num?)?.toDouble() ?? 0.0,
      tonnage: (data['tonnage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
