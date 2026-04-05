import 'confidence_models.dart';
import 'goal_models.dart';

class RecommendationInputSummary {
  final int windowDays;
  final int weightLogCount;
  final int intakeLoggedDays;
  final double? smoothedWeightSlopeKgPerWeek;
  final double avgLoggedCalories;
  final List<String> qualityFlags;

  const RecommendationInputSummary({
    required this.windowDays,
    required this.weightLogCount,
    required this.intakeLoggedDays,
    required this.smoothedWeightSlopeKgPerWeek,
    required this.avgLoggedCalories,
    this.qualityFlags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'windowDays': windowDays,
      'weightLogCount': weightLogCount,
      'intakeLoggedDays': intakeLoggedDays,
      'smoothedWeightSlopeKgPerWeek': smoothedWeightSlopeKgPerWeek,
      'avgLoggedCalories': avgLoggedCalories,
      'qualityFlags': qualityFlags,
    };
  }

  factory RecommendationInputSummary.fromJson(Map<String, dynamic> json) {
    return RecommendationInputSummary(
      windowDays: json['windowDays'] as int? ?? 0,
      weightLogCount: json['weightLogCount'] as int? ?? 0,
      intakeLoggedDays: json['intakeLoggedDays'] as int? ?? 0,
      smoothedWeightSlopeKgPerWeek:
          (json['smoothedWeightSlopeKgPerWeek'] as num?)?.toDouble(),
      avgLoggedCalories: (json['avgLoggedCalories'] as num?)?.toDouble() ?? 0,
      qualityFlags: ((json['qualityFlags'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}

class RecommendationGenerationInput {
  final DateTime windowStart;
  final DateTime windowEnd;
  final int windowDays;
  final int weightLogCount;
  final int intakeLoggedDays;
  final double? smoothedWeightSlopeKgPerWeek;
  final double avgLoggedCalories;
  final double currentWeightKg;
  final int priorMaintenanceCalories;
  final int? activeTargetCalories;
  final List<String> qualityFlags;

  const RecommendationGenerationInput({
    required this.windowStart,
    required this.windowEnd,
    required this.windowDays,
    required this.weightLogCount,
    required this.intakeLoggedDays,
    required this.smoothedWeightSlopeKgPerWeek,
    required this.avgLoggedCalories,
    required this.currentWeightKg,
    required this.priorMaintenanceCalories,
    required this.activeTargetCalories,
    this.qualityFlags = const [],
  });
}

class NutritionRecommendation {
  final int recommendedCalories;
  final int recommendedProteinGrams;
  final int recommendedCarbsGrams;
  final int recommendedFatGrams;
  final int estimatedMaintenanceCalories;
  final BodyweightGoal goal;
  final double targetRateKgPerWeek;
  final RecommendationConfidence confidence;
  final RecommendationWarningState warningState;
  final DateTime generatedAt;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String algorithmVersion;
  final RecommendationInputSummary inputSummary;
  final int? baselineCalories;
  final String? dueWeekKey;

  const NutritionRecommendation({
    required this.recommendedCalories,
    required this.recommendedProteinGrams,
    required this.recommendedCarbsGrams,
    required this.recommendedFatGrams,
    required this.estimatedMaintenanceCalories,
    required this.goal,
    required this.targetRateKgPerWeek,
    required this.confidence,
    required this.warningState,
    required this.generatedAt,
    required this.windowStart,
    required this.windowEnd,
    required this.algorithmVersion,
    required this.inputSummary,
    required this.baselineCalories,
    required this.dueWeekKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'recommendedCalories': recommendedCalories,
      'recommendedProteinGrams': recommendedProteinGrams,
      'recommendedCarbsGrams': recommendedCarbsGrams,
      'recommendedFatGrams': recommendedFatGrams,
      'estimatedMaintenanceCalories': estimatedMaintenanceCalories,
      'goal': goal.name,
      'targetRateKgPerWeek': targetRateKgPerWeek,
      'confidence': confidence.name,
      'warningState': warningState.toJson(),
      'generatedAt': generatedAt.toIso8601String(),
      'windowStart': windowStart.toIso8601String(),
      'windowEnd': windowEnd.toIso8601String(),
      'algorithmVersion': algorithmVersion,
      'inputSummary': inputSummary.toJson(),
      'baselineCalories': baselineCalories,
      'dueWeekKey': dueWeekKey,
    };
  }

  factory NutritionRecommendation.fromJson(Map<String, dynamic> json) {
    final goalRaw = json['goal'] as String?;
    final confidenceRaw = json['confidence'] as String?;

    return NutritionRecommendation(
      recommendedCalories: json['recommendedCalories'] as int? ?? 0,
      recommendedProteinGrams: json['recommendedProteinGrams'] as int? ?? 0,
      recommendedCarbsGrams: json['recommendedCarbsGrams'] as int? ?? 0,
      recommendedFatGrams: json['recommendedFatGrams'] as int? ?? 0,
      estimatedMaintenanceCalories:
          json['estimatedMaintenanceCalories'] as int? ?? 0,
      goal: BodyweightGoal.values.firstWhere(
        (goal) => goal.name == goalRaw,
        orElse: () => BodyweightGoal.maintainWeight,
      ),
      targetRateKgPerWeek:
          (json['targetRateKgPerWeek'] as num?)?.toDouble() ?? 0,
      confidence: RecommendationConfidence.values.firstWhere(
        (state) => state.name == confidenceRaw,
        orElse: () => RecommendationConfidence.notEnoughData,
      ),
      warningState: RecommendationWarningState.fromJson(
        (json['warningState'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      windowStart: DateTime.tryParse(json['windowStart'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      windowEnd: DateTime.tryParse(json['windowEnd'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      algorithmVersion: json['algorithmVersion'] as String? ?? 'unknown',
      inputSummary: RecommendationInputSummary.fromJson(
        (json['inputSummary'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      baselineCalories: json['baselineCalories'] as int?,
      dueWeekKey: json['dueWeekKey'] as String?,
    );
  }
}
