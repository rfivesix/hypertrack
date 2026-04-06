import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_engine.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_models.dart';

void main() {
  group('AdaptiveNutritionRecommendationEngine', () {
    test('classifyConfidence follows MVP thresholds', () {
      expect(
        AdaptiveNutritionRecommendationEngine.classifyConfidence(
          windowDays: 6,
          weightLogCount: 10,
          intakeLoggedDays: 10,
        ),
        RecommendationConfidence.notEnoughData,
      );

      expect(
        AdaptiveNutritionRecommendationEngine.classifyConfidence(
          windowDays: 7,
          weightLogCount: 3,
          intakeLoggedDays: 5,
        ),
        RecommendationConfidence.low,
      );

      expect(
        AdaptiveNutritionRecommendationEngine.classifyConfidence(
          windowDays: 14,
          weightLogCount: 6,
          intakeLoggedDays: 10,
        ),
        RecommendationConfidence.medium,
      );

      expect(
        AdaptiveNutritionRecommendationEngine.classifyConfidence(
          windowDays: 21,
          weightLogCount: 9,
          intakeLoggedDays: 15,
        ),
        RecommendationConfidence.high,
      );
    });

    test('rateAdjustmentKcalPerDay maps weekly kg target to kcal/day', () {
      expect(
        AdaptiveNutritionRecommendationEngine.rateAdjustmentKcalPerDay(-0.50),
        -550,
      );
      expect(
        AdaptiveNutritionRecommendationEngine.rateAdjustmentKcalPerDay(0.25),
        275,
      );
    });

    test(
        'generate keeps active targets unchanged conceptually via baseline-only warning comparison',
        () {
      final input = _input(
        priorMaintenanceCalories: 2400,
        avgLoggedCalories: 2300,
        smoothedWeightSlopeKgPerWeek: -0.2,
        windowDays: 14,
        weightLogCount: 6,
        intakeLoggedDays: 10,
        activeTargetCalories: 2000,
      );

      final recommendation = AdaptiveNutritionRecommendationEngine.generate(
        input: input,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
      );

      expect(recommendation.recommendedCalories, greaterThan(2000));
      expect(recommendation.baselineCalories, 2000);
      expect(recommendation.warningState.hasLargeAdjustmentWarning, isTrue);
      expect(
        recommendation.warningState.warningReasons.any(
          (reason) => reason.startsWith('large_adjustment_'),
        ),
        isTrue,
      );
    });

    test('generate applies a safety floor for implausibly low calories', () {
      final input = _input(
        priorMaintenanceCalories: 1200,
        avgLoggedCalories: 0,
        smoothedWeightSlopeKgPerWeek: null,
        windowDays: 0,
        weightLogCount: 0,
        intakeLoggedDays: 0,
        activeTargetCalories: null,
        currentWeightKg: 95,
      );

      final recommendation = AdaptiveNutritionRecommendationEngine.generate(
        input: input,
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -1.0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
      );

      expect(recommendation.recommendedCalories, 1200);
      expect(
        recommendation.warningState.warningReasons,
        contains('calorie_floor_applied'),
      );
      expect(
        recommendation.warningState.warningLevel,
        RecommendationWarningLevel.high,
      );
      expect(recommendation.recommendedCarbsGrams, 0);
      expect(
        recommendation.warningState.warningReasons,
        contains('macro_distribution_constrained'),
      );
    });

    test('generate degrades confidence when safety floor is applied', () {
      final input = _input(
        priorMaintenanceCalories: 1400,
        avgLoggedCalories: 1300,
        smoothedWeightSlopeKgPerWeek: 0,
        windowDays: 21,
        weightLogCount: 9,
        intakeLoggedDays: 15,
      );

      final recommendation = AdaptiveNutritionRecommendationEngine.generate(
        input: input,
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -1.0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
      );

      expect(recommendation.recommendedCalories, 1200);
      expect(recommendation.confidence, RecommendationConfidence.low);
      expect(
        recommendation.warningState.warningReasons,
        contains('calorie_floor_applied'),
      );
    });

    test('generate surfaces unresolved calorie inputs as warning reason', () {
      final input = _input(
        priorMaintenanceCalories: 2400,
        avgLoggedCalories: 2200,
        smoothedWeightSlopeKgPerWeek: -0.1,
        windowDays: 14,
        weightLogCount: 6,
        intakeLoggedDays: 10,
        qualityFlags: const ['unresolved_food_calories'],
      );

      final recommendation = AdaptiveNutritionRecommendationEngine.generate(
        input: input,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
      );

      expect(
        recommendation.warningState.warningReasons,
        contains('unresolved_food_calories'),
      );
      expect(
        recommendation.warningState.warningLevel,
        RecommendationWarningLevel.moderate,
      );
    });

    test('generate damps maintenance jumps against previous recommendation',
        () {
      final previous = NutritionRecommendation(
        recommendedCalories: 2400,
        recommendedProteinGrams: 180,
        recommendedCarbsGrams: 250,
        recommendedFatGrams: 80,
        estimatedMaintenanceCalories: 2400,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        confidence: RecommendationConfidence.high,
        warningState: RecommendationWarningState.none,
        generatedAt: DateTime(2026, 3, 29),
        windowStart: DateTime(2026, 3, 9),
        windowEnd: DateTime(2026, 3, 29, 23, 59, 59),
        algorithmVersion: 'test',
        inputSummary: const RecommendationInputSummary(
          windowDays: 21,
          weightLogCount: 9,
          intakeLoggedDays: 15,
          smoothedWeightSlopeKgPerWeek: 0,
          avgLoggedCalories: 2400,
        ),
        baselineCalories: 2400,
        dueWeekKey: '2026-03-23',
      );

      final input = _input(
        priorMaintenanceCalories: 3200,
        avgLoggedCalories: 3300,
        smoothedWeightSlopeKgPerWeek: -0.8,
        windowDays: 21,
        weightLogCount: 9,
        intakeLoggedDays: 15,
      );

      final recommendation = AdaptiveNutritionRecommendationEngine.generate(
        input: input,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
        previousRecommendation: previous,
      );

      expect(
          recommendation.estimatedMaintenanceCalories, lessThanOrEqualTo(2640));
      expect(recommendation.estimatedMaintenanceCalories,
          greaterThanOrEqualTo(2160));
    });

    test('generate keeps notEnoughData recommendations strictly prior-only',
        () {
      final previous = NutritionRecommendation(
        recommendedCalories: 2500,
        recommendedProteinGrams: 180,
        recommendedCarbsGrams: 260,
        recommendedFatGrams: 80,
        estimatedMaintenanceCalories: 2500,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        confidence: RecommendationConfidence.high,
        warningState: RecommendationWarningState.none,
        generatedAt: DateTime(2026, 3, 29),
        windowStart: DateTime(2026, 3, 9),
        windowEnd: DateTime(2026, 3, 29, 23, 59, 59),
        algorithmVersion: 'test',
        inputSummary: const RecommendationInputSummary(
          windowDays: 21,
          weightLogCount: 9,
          intakeLoggedDays: 15,
          smoothedWeightSlopeKgPerWeek: 0.1,
          avgLoggedCalories: 2500,
        ),
        baselineCalories: 2500,
        dueWeekKey: '2026-03-23',
      );

      final input = _input(
        priorMaintenanceCalories: 2100,
        avgLoggedCalories: 3000,
        smoothedWeightSlopeKgPerWeek: -0.8,
        windowDays: 3,
        weightLogCount: 1,
        intakeLoggedDays: 1,
      );

      final recommendation = AdaptiveNutritionRecommendationEngine.generate(
        input: input,
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -0.5,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
        previousRecommendation: previous,
      );

      expect(recommendation.confidence, RecommendationConfidence.notEnoughData);
      expect(recommendation.estimatedMaintenanceCalories, 2100);
      expect(
        recommendation.recommendedCalories,
        2100 +
            AdaptiveNutritionRecommendationEngine.rateAdjustmentKcalPerDay(
              -0.5,
            ),
      );
    });
  });
}

RecommendationGenerationInput _input({
  required int priorMaintenanceCalories,
  required double avgLoggedCalories,
  required double? smoothedWeightSlopeKgPerWeek,
  required int windowDays,
  required int weightLogCount,
  required int intakeLoggedDays,
  int? activeTargetCalories,
  List<String> qualityFlags = const [],
  double currentWeightKg = 82,
}) {
  return RecommendationGenerationInput(
    windowStart: DateTime(2026, 3, 15),
    windowEnd: DateTime(2026, 4, 5, 23, 59, 59),
    windowDays: windowDays,
    weightLogCount: weightLogCount,
    intakeLoggedDays: intakeLoggedDays,
    smoothedWeightSlopeKgPerWeek: smoothedWeightSlopeKgPerWeek,
    avgLoggedCalories: avgLoggedCalories,
    currentWeightKg: currentWeightKg,
    priorMaintenanceCalories: priorMaintenanceCalories,
    activeTargetCalories: activeTargetCalories,
    qualityFlags: qualityFlags,
  );
}
