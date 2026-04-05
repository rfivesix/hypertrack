enum RecommendationConfidence {
  notEnoughData,
  low,
  medium,
  high,
}

enum RecommendationWarningLevel {
  none,
  moderate,
  high,
}

class RecommendationWarningState {
  final bool hasLargeAdjustmentWarning;
  final RecommendationWarningLevel warningLevel;
  final List<String> warningReasons;

  const RecommendationWarningState({
    required this.hasLargeAdjustmentWarning,
    required this.warningLevel,
    this.warningReasons = const [],
  });

  static const none = RecommendationWarningState(
    hasLargeAdjustmentWarning: false,
    warningLevel: RecommendationWarningLevel.none,
  );

  Map<String, dynamic> toJson() {
    return {
      'hasLargeAdjustmentWarning': hasLargeAdjustmentWarning,
      'warningLevel': warningLevel.name,
      'warningReasons': warningReasons,
    };
  }

  factory RecommendationWarningState.fromJson(Map<String, dynamic> json) {
    final levelRaw = json['warningLevel'] as String?;
    final level = RecommendationWarningLevel.values.firstWhere(
      (candidate) => candidate.name == levelRaw,
      orElse: () => RecommendationWarningLevel.none,
    );

    return RecommendationWarningState(
      hasLargeAdjustmentWarning:
          json['hasLargeAdjustmentWarning'] as bool? ?? false,
      warningLevel: level,
      warningReasons: ((json['warningReasons'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}
