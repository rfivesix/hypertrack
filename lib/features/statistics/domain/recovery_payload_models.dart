class RecoveryTotalsPayload {
  final int recovering;
  final int ready;
  final int fresh;
  final int tracked;

  const RecoveryTotalsPayload({
    required this.recovering,
    required this.ready,
    required this.fresh,
    required this.tracked,
  });

  factory RecoveryTotalsPayload.fromMap(Map<String, dynamic> data) {
    return RecoveryTotalsPayload(
      recovering: (data['recovering'] as num?)?.toInt() ?? 0,
      ready: (data['ready'] as num?)?.toInt() ?? 0,
      fresh: (data['fresh'] as num?)?.toInt() ?? 0,
      tracked: (data['tracked'] as num?)?.toInt() ?? 0,
    );
  }
}

class RecoveryMusclePayload {
  final String muscleGroup;
  final String state;
  final double hoursSinceLastSignificantLoad;
  final DateTime? lastSignificantLoadAt;
  final double lastEquivalentSets;
  final double? avgRir;
  final double? avgRpe;
  final bool highSessionFatigue;
  final int recoveringUpperHours;
  final int readyUpperHours;

  const RecoveryMusclePayload({
    required this.muscleGroup,
    required this.state,
    required this.hoursSinceLastSignificantLoad,
    required this.lastSignificantLoadAt,
    required this.lastEquivalentSets,
    required this.avgRir,
    required this.avgRpe,
    required this.highSessionFatigue,
    required this.recoveringUpperHours,
    required this.readyUpperHours,
  });

  factory RecoveryMusclePayload.fromMap(Map<String, dynamic> data) {
    return RecoveryMusclePayload(
      muscleGroup: data['muscleGroup'] as String? ?? '',
      state: data['state'] as String? ?? '',
      hoursSinceLastSignificantLoad:
          (data['hoursSinceLastSignificantLoad'] as num?)?.toDouble() ?? 0.0,
      lastSignificantLoadAt: data['lastSignificantLoadAt'] as DateTime?,
      lastEquivalentSets: (data['lastEquivalentSets'] as num?)?.toDouble() ?? 0,
      avgRir: (data['avgRir'] as num?)?.toDouble(),
      avgRpe: (data['avgRpe'] as num?)?.toDouble(),
      highSessionFatigue: (data['highSessionFatigue'] as bool?) ?? false,
      recoveringUpperHours:
          (data['recoveringUpperHours'] as num?)?.toInt() ?? 48,
      readyUpperHours: (data['readyUpperHours'] as num?)?.toInt() ?? 72,
    );
  }
}

class RecoveryAnalyticsPayload {
  final bool hasData;
  final String overallState;
  final RecoveryTotalsPayload totals;
  final List<RecoveryMusclePayload> muscles;

  const RecoveryAnalyticsPayload({
    required this.hasData,
    required this.overallState,
    required this.totals,
    required this.muscles,
  });

  factory RecoveryAnalyticsPayload.fromMap(Map<String, dynamic> data) {
    final totalsMap = (data['totals'] as Map<String, dynamic>?) ?? const {};
    final musclesList = (data['muscles'] as List<dynamic>? ?? const []);
    return RecoveryAnalyticsPayload(
      hasData: (data['hasData'] as bool?) ?? false,
      overallState: data['overallState'] as String? ?? '',
      totals: RecoveryTotalsPayload.fromMap(totalsMap),
      muscles: musclesList
          .whereType<Map<String, dynamic>>()
          .map(RecoveryMusclePayload.fromMap)
          .toList(),
    );
  }
}
