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
    required this.insightType,
    required this.insightDataQuality,
  });

  bool get hasAnyData => weightDays > 0 || loggedCalorieDays > 0;

  bool get hasEnoughForInsight =>
      insightType != BodyNutritionInsightType.notEnoughData;
}
