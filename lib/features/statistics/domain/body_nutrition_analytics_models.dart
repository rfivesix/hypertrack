import 'package:flutter/material.dart';
import 'statistics_data_quality_policy.dart';

class DailyValuePoint {
  final DateTime day;
  final double value;

  const DailyValuePoint({required this.day, required this.value});
}

enum BodyNutritionInsightType {
  notEnoughData,
  stableWeightCaloriesUp,
  weightUpCaloriesUp,
  caloriesDownWeightNotYetChanged,
  weightDownCaloriesDown,
  mixed,
}

enum BodyNutritionTrendDirection { rising, falling, stable, unclear }

enum BodyNutritionRelationshipType {
  alignedCutLike,
  alignedBulkLike,
  stableMaintenanceLike,
  mixedOrUnclear,
  insufficientData,
}

enum BodyNutritionConfidence { high, moderate, low, insufficient }

class BodyNutritionTrendSnapshot {
  const BodyNutritionTrendSnapshot({
    required this.direction,
    required this.slopePerWeek,
    required this.netChange,
    required this.signalToNoise,
  });

  final BodyNutritionTrendDirection direction;
  final double? slopePerWeek;
  final double? netChange;
  final double signalToNoise;
}

class BodyNutritionDataQualitySummary {
  const BodyNutritionDataQualitySummary({
    required this.spanDays,
    required this.weightDays,
    required this.calorieDays,
    required this.overlapDays,
    required this.weightCoverage,
    required this.calorieCoverage,
    required this.overlapCoverage,
    required this.weightLargestGapDays,
    required this.calorieLargestGapDays,
  });

  final int spanDays;
  final int weightDays;
  final int calorieDays;
  final int overlapDays;
  final double weightCoverage;
  final double calorieCoverage;
  final double overlapCoverage;
  final int weightLargestGapDays;
  final int calorieLargestGapDays;
}

class BodyNutritionAnalyticsResult {
  final DateTimeRange range;
  final int totalDays;
  final double? currentWeightKg;
  final double? weightChangeKg;
  final double avgDailyCalories;
  final int weightDays;
  final int loggedCalorieDays;
  final List<DailyValuePoint> weightDaily;
  final List<DailyValuePoint> smoothedWeight;
  final List<DailyValuePoint> caloriesDaily;
  final List<DailyValuePoint> smoothedCalories;
  final List<DailyValuePoint> normalizedWeightTrend;
  final List<DailyValuePoint> normalizedCaloriesTrend;
  final DateTimeRange? normalizedTrendRange;
  final BodyNutritionTrendSnapshot weightTrend;
  final BodyNutritionTrendSnapshot calorieTrend;
  final BodyNutritionRelationshipType relationship;
  final BodyNutritionConfidence confidence;
  final BodyNutritionDataQualitySummary qualitySummary;
  final BodyNutritionInsightType insightType;
  final StatisticsDataQualityAssessment insightDataQuality;

  const BodyNutritionAnalyticsResult({
    required this.range,
    required this.totalDays,
    required this.currentWeightKg,
    required this.weightChangeKg,
    required this.avgDailyCalories,
    required this.weightDays,
    required this.loggedCalorieDays,
    required this.weightDaily,
    required this.smoothedWeight,
    required this.caloriesDaily,
    required this.smoothedCalories,
    this.normalizedWeightTrend = const [],
    this.normalizedCaloriesTrend = const [],
    this.normalizedTrendRange,
    required this.weightTrend,
    required this.calorieTrend,
    required this.relationship,
    required this.confidence,
    required this.qualitySummary,
    required this.insightType,
    required this.insightDataQuality,
  });

  bool get hasAnyData => weightDays > 0 || loggedCalorieDays > 0;

  bool get hasEnoughForInsight =>
      insightType != BodyNutritionInsightType.notEnoughData;

  bool get hasComparableTrend =>
      normalizedWeightTrend.isNotEmpty && normalizedCaloriesTrend.isNotEmpty;
}
