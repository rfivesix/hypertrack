import 'confidence_models.dart';
import 'goal_models.dart';
import 'recommendation_models.dart';

class AdaptiveNutritionRecommendationEngine {
  const AdaptiveNutritionRecommendationEngine._();

  static const double _kcalPerKgPerWeekToDay = 7700 / 7;

  static NutritionRecommendation generate({
    required RecommendationGenerationInput input,
    required BodyweightGoal goal,
    required double targetRateKgPerWeek,
    required DateTime generatedAt,
    required String algorithmVersion,
    String? dueWeekKey,
    NutritionRecommendation? previousRecommendation,
  }) {
    final confidence = classifyConfidence(
      windowDays: input.windowDays,
      weightLogCount: input.weightLogCount,
      intakeLoggedDays: input.intakeLoggedDays,
    );

    final inferredMaintenance = _inferMaintenanceCalories(input);
    final blend = _blendFactorForConfidence(confidence);

    var maintenance = (input.priorMaintenanceCalories * (1 - blend)) +
        (inferredMaintenance * blend);

    if (previousRecommendation != null) {
      final deltaLimit = _weeklyMaintenanceDeltaLimit(confidence);
      final delta =
          maintenance - previousRecommendation.estimatedMaintenanceCalories;
      maintenance = previousRecommendation.estimatedMaintenanceCalories +
          delta.clamp(-deltaLimit, deltaLimit);
    }

    final estimatedMaintenanceCalories = maintenance.round();
    final calorieAdjustment = rateAdjustmentKcalPerDay(targetRateKgPerWeek);
    final recommendedCalories =
        estimatedMaintenanceCalories + calorieAdjustment;

    final macroResult = _computeMacros(
      goal: goal,
      currentWeightKg: input.currentWeightKg,
      recommendedCalories: recommendedCalories,
    );

    final baselineCalories = input.activeTargetCalories ??
        previousRecommendation?.recommendedCalories;
    final warningState = _buildWarningState(
      baselineCalories: baselineCalories,
      recommendedCalories: recommendedCalories,
      extraReasons: macroResult.warningReasons,
    );

    return NutritionRecommendation(
      recommendedCalories: recommendedCalories,
      recommendedProteinGrams: macroResult.protein,
      recommendedCarbsGrams: macroResult.carbs,
      recommendedFatGrams: macroResult.fat,
      estimatedMaintenanceCalories: estimatedMaintenanceCalories,
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      confidence: confidence,
      warningState: warningState,
      generatedAt: generatedAt,
      windowStart: input.windowStart,
      windowEnd: input.windowEnd,
      algorithmVersion: algorithmVersion,
      inputSummary: RecommendationInputSummary(
        windowDays: input.windowDays,
        weightLogCount: input.weightLogCount,
        intakeLoggedDays: input.intakeLoggedDays,
        smoothedWeightSlopeKgPerWeek: input.smoothedWeightSlopeKgPerWeek,
        avgLoggedCalories: input.avgLoggedCalories,
        qualityFlags: input.qualityFlags,
      ),
      baselineCalories: baselineCalories,
      dueWeekKey: dueWeekKey,
    );
  }

  static RecommendationConfidence classifyConfidence({
    required int windowDays,
    required int weightLogCount,
    required int intakeLoggedDays,
  }) {
    if (windowDays >= 21 && weightLogCount >= 9 && intakeLoggedDays >= 15) {
      return RecommendationConfidence.high;
    }
    if (windowDays >= 14 && weightLogCount >= 6 && intakeLoggedDays >= 10) {
      return RecommendationConfidence.medium;
    }
    if (windowDays >= 7 && weightLogCount >= 3 && intakeLoggedDays >= 5) {
      return RecommendationConfidence.low;
    }
    return RecommendationConfidence.notEnoughData;
  }

  static int rateAdjustmentKcalPerDay(double kgPerWeek) {
    return (kgPerWeek * _kcalPerKgPerWeekToDay).round();
  }

  static double _inferMaintenanceCalories(RecommendationGenerationInput input) {
    final slope = input.smoothedWeightSlopeKgPerWeek;
    if (slope == null || input.intakeLoggedDays <= 0) {
      return input.priorMaintenanceCalories.toDouble();
    }
    return input.avgLoggedCalories - (slope * _kcalPerKgPerWeekToDay);
  }

  static double _blendFactorForConfidence(RecommendationConfidence confidence) {
    switch (confidence) {
      case RecommendationConfidence.notEnoughData:
        return 0;
      case RecommendationConfidence.low:
        return 0.35;
      case RecommendationConfidence.medium:
        return 0.60;
      case RecommendationConfidence.high:
        return 0.80;
    }
  }

  static double _weeklyMaintenanceDeltaLimit(
    RecommendationConfidence confidence,
  ) {
    switch (confidence) {
      case RecommendationConfidence.notEnoughData:
        return 80;
      case RecommendationConfidence.low:
        return 110;
      case RecommendationConfidence.medium:
        return 170;
      case RecommendationConfidence.high:
        return 240;
    }
  }

  static _MacroResult _computeMacros({
    required BodyweightGoal goal,
    required double currentWeightKg,
    required int recommendedCalories,
  }) {
    final normalizedWeight = currentWeightKg <= 0 ? 75.0 : currentWeightKg;
    var proteinGrams = (normalizedWeight * _proteinPerKg(goal)).round();
    final fatFloor = (normalizedWeight * 0.60).round().clamp(35, 130);

    var fatGrams = fatFloor;
    var carbsGrams =
        ((recommendedCalories - (proteinGrams * 4) - (fatGrams * 9)) / 4)
            .round();

    final warningReasons = <String>[];

    if (carbsGrams < 0) {
      carbsGrams = 0;
      fatGrams = ((recommendedCalories - (proteinGrams * 4)) / 9).floor();

      if (fatGrams < 25) {
        fatGrams = 25;
        final proteinBudgetCalories = recommendedCalories - (fatGrams * 9);
        if (proteinBudgetCalories < proteinGrams * 4) {
          proteinGrams = (proteinBudgetCalories / 4).floor().clamp(0, 999);
        }
      }

      warningReasons.add('macro_distribution_constrained');
    }

    return _MacroResult(
      protein: proteinGrams.clamp(0, 999),
      carbs: carbsGrams.clamp(0, 999),
      fat: fatGrams.clamp(0, 999),
      warningReasons: warningReasons,
    );
  }

  static double _proteinPerKg(BodyweightGoal goal) {
    switch (goal) {
      case BodyweightGoal.loseWeight:
        return 2.0;
      case BodyweightGoal.maintainWeight:
      case BodyweightGoal.gainWeight:
        return 1.8;
    }
  }

  static RecommendationWarningState _buildWarningState({
    required int? baselineCalories,
    required int recommendedCalories,
    required List<String> extraReasons,
  }) {
    final reasons = <String>[...extraReasons];
    var warningLevel = RecommendationWarningLevel.none;
    var hasLargeAdjustmentWarning = false;

    if (baselineCalories != null) {
      final delta = (recommendedCalories - baselineCalories).abs();
      if (delta >= 450) {
        warningLevel = RecommendationWarningLevel.high;
        hasLargeAdjustmentWarning = true;
        reasons.add('large_adjustment_high');
      } else if (delta >= 250) {
        warningLevel = RecommendationWarningLevel.moderate;
        hasLargeAdjustmentWarning = true;
        reasons.add('large_adjustment_moderate');
      }
    }

    if (!hasLargeAdjustmentWarning && reasons.isNotEmpty) {
      warningLevel = RecommendationWarningLevel.moderate;
    }

    return RecommendationWarningState(
      hasLargeAdjustmentWarning: hasLargeAdjustmentWarning,
      warningLevel: warningLevel,
      warningReasons: reasons,
    );
  }
}

class _MacroResult {
  final int protein;
  final int carbs;
  final int fat;
  final List<String> warningReasons;

  const _MacroResult({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.warningReasons,
  });
}
