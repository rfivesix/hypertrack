import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/chart_data_point.dart';
import 'body_nutrition_analytics_models.dart';
import 'statistics_data_quality_policy.dart';

class BodyNutritionAnalyticsEngine {
  const BodyNutritionAnalyticsEngine._();

  static DateTime normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static BodyNutritionAnalyticsResult build({
    required DateTimeRange range,
    required List<ChartDataPoint> weightPoints,
    required Map<DateTime, double> caloriesByDay,
  }) {
    final allDays = _enumerateDays(range.start, range.end);
    final totalDays = allDays.length;
    final weightByDay = _latestWeightPerDay(weightPoints);
    final loggedCaloriesByDay = <DateTime, double>{};
    final caloriesDaily = <DailyValuePoint>[];
    final weightDaily = <DailyValuePoint>[];

    for (final day in allDays) {
      final calories = caloriesByDay[day] ?? 0.0;
      if (calories > 0) {
        loggedCaloriesByDay[day] = calories;
      }
      caloriesDaily.add(DailyValuePoint(day: day, value: calories));

      final weight = weightByDay[day];
      if (weight != null) {
        weightDaily.add(DailyValuePoint(day: day, value: weight));
      }
    }

    final loggedCalorieDays = loggedCaloriesByDay.length;
    final loggedCaloriesSeries = loggedCaloriesByDay.entries
        .map((entry) => DailyValuePoint(day: entry.key, value: entry.value))
        .toList(growable: false);

    final interpolatedWeight = _interpolateWeightDaily(
      days: allDays,
      observedByDay: weightByDay,
    );

    final smoothedWeightByDay = _windowAverageByDay(
      days: allDays,
      valuesByDay: interpolatedWeight,
      windowRadiusDays: 3,
      minSamples: 2,
    );
    final smoothedCaloriesByDay = _windowAverageByDay(
      days: allDays,
      valuesByDay: loggedCaloriesByDay,
      windowRadiusDays: 3,
      minSamples: 3,
    );

    final smoothedWeight = allDays
        .where((day) => smoothedWeightByDay[day] != null)
        .map((day) =>
            DailyValuePoint(day: day, value: smoothedWeightByDay[day]!))
        .toList(growable: false);
    final smoothedCalories = allDays
        .where((day) => smoothedCaloriesByDay[day] != null)
        .map((day) =>
            DailyValuePoint(day: day, value: smoothedCaloriesByDay[day]!))
        .toList(growable: false);

    final weightTrend = _computeTrendSnapshot(
      series: smoothedWeight.isNotEmpty ? smoothedWeight : weightDaily,
      unit: _TrendUnit.weightKg,
    );
    final calorieTrend = _computeTrendSnapshot(
      series:
          smoothedCalories.isNotEmpty ? smoothedCalories : loggedCaloriesSeries,
      unit: _TrendUnit.caloriesKcal,
    );

    final overlapDays = allDays
        .where(
          (day) =>
              smoothedWeightByDay[day] != null &&
              smoothedCaloriesByDay[day] != null,
        )
        .length;

    final qualitySummary = BodyNutritionDataQualitySummary(
      spanDays: totalDays,
      weightDays: weightDaily.length,
      calorieDays: loggedCalorieDays,
      overlapDays: overlapDays,
      weightCoverage: totalDays <= 0 ? 0.0 : weightDaily.length / totalDays,
      calorieCoverage: totalDays <= 0 ? 0.0 : loggedCalorieDays / totalDays,
      overlapCoverage: totalDays <= 0 ? 0.0 : overlapDays / totalDays,
      weightLargestGapDays: _largestGapDays(
        days: allDays,
        observedDays: weightByDay.keys.toSet(),
      ),
      calorieLargestGapDays: _largestGapDays(
        days: allDays,
        observedDays: loggedCaloriesByDay.keys.toSet(),
      ),
    );

    final confidence = _classifyConfidence(
      quality: qualitySummary,
      weightTrend: weightTrend,
      calorieTrend: calorieTrend,
    );
    final relationship = _classifyRelationship(
      confidence: confidence,
      weightTrend: weightTrend.direction,
      calorieTrend: calorieTrend.direction,
    );

    final normalizedComparison = _buildNormalizedComparison(
      days: allDays,
      smoothedWeightByDay: smoothedWeightByDay,
      smoothedCaloriesByDay: smoothedCaloriesByDay,
    );

    final currentWeightKg = weightDaily.isEmpty ? null : weightDaily.last.value;
    final weightChangeKg = weightChange(smoothedWeight, weightDaily);
    final avgDailyCalories = loggedCalorieDays <= 0
        ? 0.0
        : loggedCaloriesSeries.fold<double>(0.0, (sum, p) => sum + p.value) /
            loggedCalorieDays;

    final insightType = _legacyInsightType(
      relationship: relationship,
      weightTrend: weightTrend.direction,
      calorieTrend: calorieTrend.direction,
    );

    return BodyNutritionAnalyticsResult(
      range: range,
      totalDays: totalDays,
      currentWeightKg: currentWeightKg,
      weightChangeKg: weightChangeKg,
      avgDailyCalories: avgDailyCalories,
      weightDays: weightDaily.length,
      loggedCalorieDays: loggedCalorieDays,
      weightDaily: weightDaily,
      smoothedWeight: smoothedWeight,
      caloriesDaily: caloriesDaily,
      smoothedCalories: smoothedCalories,
      normalizedWeightTrend: normalizedComparison.weightSeries,
      normalizedCaloriesTrend: normalizedComparison.calorieSeries,
      normalizedTrendRange: normalizedComparison.range,
      weightTrend: weightTrend,
      calorieTrend: calorieTrend,
      relationship: relationship,
      confidence: confidence,
      qualitySummary: qualitySummary,
      insightType: insightType,
      insightDataQuality: StatisticsDataQualityAssessment(
        hasSufficientData: confidence != BodyNutritionConfidence.insufficient,
        reasonHook: switch (confidence) {
          BodyNutritionConfidence.high => 'quality:body-nutrition:high',
          BodyNutritionConfidence.moderate => 'quality:body-nutrition:moderate',
          BodyNutritionConfidence.low => 'quality:body-nutrition:low',
          BodyNutritionConfidence.insufficient =>
            'quality:body-nutrition:insufficient',
        },
      ),
    );
  }

  static List<DailyValuePoint> normalizedSeries(List<DailyValuePoint> points) {
    if (points.isEmpty) return const [];
    final minValue = points.map((p) => p.value).reduce(math.min);
    final maxValue = points.map((p) => p.value).reduce(math.max);
    final span = (maxValue - minValue).abs();
    if (span < 0.0001) {
      return points
          .map((p) => DailyValuePoint(day: p.day, value: 0.5))
          .toList(growable: false);
    }
    return points
        .map((p) =>
            DailyValuePoint(day: p.day, value: (p.value - minValue) / span))
        .toList(growable: false);
  }

  static Map<DateTime, double> _latestWeightPerDay(
      List<ChartDataPoint> points) {
    final sorted = points.toList()..sort((a, b) => a.date.compareTo(b.date));
    final map = <DateTime, double>{};
    for (final point in sorted) {
      map[normalizeDay(point.date)] = point.value;
    }
    return map;
  }

  static List<DateTime> _enumerateDays(DateTime start, DateTime end) {
    final normalizedStart = normalizeDay(start);
    final normalizedEnd = normalizeDay(end);
    final result = <DateTime>[];
    var cursor = normalizedStart;
    while (!cursor.isAfter(normalizedEnd)) {
      result.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  static Map<DateTime, double> _interpolateWeightDaily({
    required List<DateTime> days,
    required Map<DateTime, double> observedByDay,
  }) {
    if (observedByDay.isEmpty) return const {};
    final observedDays = observedByDay.keys.toList()..sort();
    final result = <DateTime, double>{
      for (final day in observedDays) day: observedByDay[day]!
    };
    const maxInterpolationGapDays = 14;

    for (var i = 0; i < observedDays.length - 1; i++) {
      final startDay = observedDays[i];
      final endDay = observedDays[i + 1];
      final gap = endDay.difference(startDay).inDays;
      if (gap <= 1 || gap > maxInterpolationGapDays) continue;
      final startValue = observedByDay[startDay]!;
      final endValue = observedByDay[endDay]!;
      for (var offset = 1; offset < gap; offset++) {
        final day = startDay.add(Duration(days: offset));
        final t = offset / gap;
        result[day] = startValue + (endValue - startValue) * t;
      }
    }

    final first = observedDays.first;
    final last = observedDays.last;
    for (var i = 1; i <= 2; i++) {
      final before = first.subtract(Duration(days: i));
      final after = last.add(Duration(days: i));
      if (days.contains(before)) {
        result.putIfAbsent(before, () => observedByDay[first]!);
      }
      if (days.contains(after)) {
        result.putIfAbsent(after, () => observedByDay[last]!);
      }
    }

    return result;
  }

  static Map<DateTime, double?> _windowAverageByDay({
    required List<DateTime> days,
    required Map<DateTime, double> valuesByDay,
    required int windowRadiusDays,
    required int minSamples,
  }) {
    final result = <DateTime, double?>{};
    for (var i = 0; i < days.length; i++) {
      final start = math.max(0, i - windowRadiusDays);
      final end = math.min(days.length - 1, i + windowRadiusDays);
      final values = <double>[];
      for (var j = start; j <= end; j++) {
        final value = valuesByDay[days[j]];
        if (value != null && value.isFinite) {
          values.add(value);
        }
      }
      if (values.length >= minSamples) {
        final avg =
            values.fold<double>(0.0, (sum, v) => sum + v) / values.length;
        result[days[i]] = avg;
      } else {
        result[days[i]] = null;
      }
    }
    return result;
  }

  static BodyNutritionTrendSnapshot _computeTrendSnapshot({
    required List<DailyValuePoint> series,
    required _TrendUnit unit,
  }) {
    if (series.length < 3) {
      return const BodyNutritionTrendSnapshot(
        direction: BodyNutritionTrendDirection.unclear,
        slopePerWeek: null,
        netChange: null,
        signalToNoise: 0,
      );
    }

    final firstDay = normalizeDay(series.first.day);
    final xs = series
        .map((point) =>
            normalizeDay(point.day).difference(firstDay).inDays.toDouble())
        .toList(growable: false);
    final ys = series.map((point) => point.value).toList(growable: false);

    final meanX = xs.reduce((a, b) => a + b) / xs.length;
    final meanY = ys.reduce((a, b) => a + b) / ys.length;

    var cov = 0.0;
    var varX = 0.0;
    for (var i = 0; i < xs.length; i++) {
      cov += (xs[i] - meanX) * (ys[i] - meanY);
      varX += (xs[i] - meanX) * (xs[i] - meanX);
    }
    final slopePerDay = varX <= 0 ? 0.0 : cov / varX;
    final intercept = meanY - (slopePerDay * meanX);

    var residualSquare = 0.0;
    for (var i = 0; i < xs.length; i++) {
      final predicted = intercept + slopePerDay * xs[i];
      final residual = ys[i] - predicted;
      residualSquare += residual * residual;
    }
    final noise = math.sqrt(residualSquare / math.max(1, xs.length - 1));

    final netChange = ys.last - ys.first;
    final spanDays = math.max(1.0, xs.last - xs.first);
    final slopePerWeek = slopePerDay * 7.0;
    final trendSpanChange = slopePerDay * spanDays;
    final signalMagnitude = math.max(netChange.abs(), trendSpanChange.abs());
    final signalToNoise = signalMagnitude / math.max(0.0001, noise);

    final direction = _classifyDirection(
      unit: unit,
      slopePerWeek: slopePerWeek,
      netChange: netChange,
      signalToNoise: signalToNoise,
      spanDays: spanDays,
    );

    return BodyNutritionTrendSnapshot(
      direction: direction,
      slopePerWeek: slopePerWeek,
      netChange: netChange,
      signalToNoise: signalToNoise,
    );
  }

  static BodyNutritionTrendDirection _classifyDirection({
    required _TrendUnit unit,
    required double slopePerWeek,
    required double netChange,
    required double signalToNoise,
    required double spanDays,
  }) {
    if (spanDays < 7) return BodyNutritionTrendDirection.unclear;

    final stableSlope = switch (unit) {
      _TrendUnit.weightKg => 0.08,
      _TrendUnit.caloriesKcal => 45.0,
    };
    final stableNet = switch (unit) {
      _TrendUnit.weightKg => 0.30,
      _TrendUnit.caloriesKcal => 120.0,
    };
    final directionalSlope = switch (unit) {
      _TrendUnit.weightKg => 0.12,
      _TrendUnit.caloriesKcal => 60.0,
    };
    final directionalNet = switch (unit) {
      _TrendUnit.weightKg => 0.35,
      _TrendUnit.caloriesKcal => 160.0,
    };

    final isStable =
        slopePerWeek.abs() <= stableSlope && netChange.abs() <= stableNet;
    if (isStable) return BodyNutritionTrendDirection.stable;

    if (signalToNoise < 0.55) return BodyNutritionTrendDirection.unclear;

    if (slopePerWeek >= directionalSlope && netChange >= directionalNet) {
      return BodyNutritionTrendDirection.rising;
    }
    if (slopePerWeek <= -directionalSlope && netChange <= -directionalNet) {
      return BodyNutritionTrendDirection.falling;
    }
    return BodyNutritionTrendDirection.unclear;
  }

  static int _largestGapDays({
    required List<DateTime> days,
    required Set<DateTime> observedDays,
  }) {
    var currentGap = 0;
    var largestGap = 0;
    for (final day in days) {
      if (observedDays.contains(day)) {
        largestGap = math.max(largestGap, currentGap);
        currentGap = 0;
      } else {
        currentGap += 1;
      }
    }
    largestGap = math.max(largestGap, currentGap);
    return largestGap;
  }

  static BodyNutritionConfidence _classifyConfidence({
    required BodyNutritionDataQualitySummary quality,
    required BodyNutritionTrendSnapshot weightTrend,
    required BodyNutritionTrendSnapshot calorieTrend,
  }) {
    final hardInsufficient = quality.spanDays < 14 ||
        quality.weightDays < 4 ||
        quality.calorieDays < 7 ||
        quality.overlapDays < 5;
    if (hardInsufficient) return BodyNutritionConfidence.insufficient;

    var score = 0;
    if (quality.spanDays >= 21) score += 1;
    if (quality.spanDays >= 56) score += 1;
    if (quality.weightDays >= 6) score += 1;
    if (quality.weightDays >= 12) score += 1;
    if (quality.calorieDays >= 10) score += 1;
    if (quality.calorieDays >= 20) score += 1;
    if (quality.overlapDays >= 7) score += 1;
    if (quality.overlapDays >= 14) score += 1;
    if (quality.weightLargestGapDays <= 7) score += 1;
    if (quality.calorieLargestGapDays <= 5) score += 1;
    if (weightTrend.signalToNoise >= 0.70) score += 1;
    if (calorieTrend.signalToNoise >= 0.70) score += 1;

    if (score >= 10) return BodyNutritionConfidence.high;
    if (score >= 7) return BodyNutritionConfidence.moderate;
    return BodyNutritionConfidence.low;
  }

  static BodyNutritionRelationshipType _classifyRelationship({
    required BodyNutritionConfidence confidence,
    required BodyNutritionTrendDirection weightTrend,
    required BodyNutritionTrendDirection calorieTrend,
  }) {
    if (confidence == BodyNutritionConfidence.insufficient) {
      return BodyNutritionRelationshipType.insufficientData;
    }
    if (weightTrend == BodyNutritionTrendDirection.unclear ||
        calorieTrend == BodyNutritionTrendDirection.unclear) {
      return BodyNutritionRelationshipType.mixedOrUnclear;
    }
    if (weightTrend == BodyNutritionTrendDirection.stable &&
        calorieTrend == BodyNutritionTrendDirection.stable) {
      return BodyNutritionRelationshipType.stableMaintenanceLike;
    }
    if (weightTrend == BodyNutritionTrendDirection.falling &&
        calorieTrend == BodyNutritionTrendDirection.falling) {
      return BodyNutritionRelationshipType.alignedCutLike;
    }
    if (weightTrend == BodyNutritionTrendDirection.rising &&
        calorieTrend == BodyNutritionTrendDirection.rising) {
      return BodyNutritionRelationshipType.alignedBulkLike;
    }
    return BodyNutritionRelationshipType.mixedOrUnclear;
  }

  static _NormalizedComparisonResult _buildNormalizedComparison({
    required List<DateTime> days,
    required Map<DateTime, double?> smoothedWeightByDay,
    required Map<DateTime, double?> smoothedCaloriesByDay,
  }) {
    DateTime? start;
    for (final day in days) {
      if (smoothedWeightByDay[day] != null &&
          smoothedCaloriesByDay[day] != null) {
        start = day;
        break;
      }
    }
    if (start == null) {
      return const _NormalizedComparisonResult(
        range: null,
        weightSeries: <DailyValuePoint>[],
        calorieSeries: <DailyValuePoint>[],
      );
    }

    final baselineWeight = smoothedWeightByDay[start]!;
    final baselineCalories = smoothedCaloriesByDay[start]!;
    if (!baselineWeight.isFinite ||
        !baselineCalories.isFinite ||
        baselineWeight == 0 ||
        baselineCalories == 0) {
      return const _NormalizedComparisonResult(
        range: null,
        weightSeries: <DailyValuePoint>[],
        calorieSeries: <DailyValuePoint>[],
      );
    }

    final normalizedWeight = <DailyValuePoint>[];
    final normalizedCalories = <DailyValuePoint>[];
    for (final day in days.where((candidate) => !candidate.isBefore(start!))) {
      final weight = smoothedWeightByDay[day];
      final calories = smoothedCaloriesByDay[day];
      if (weight == null || calories == null) continue;
      normalizedWeight.add(
        DailyValuePoint(day: day, value: ((weight / baselineWeight) - 1) * 100),
      );
      normalizedCalories.add(
        DailyValuePoint(
          day: day,
          value: ((calories / baselineCalories) - 1) * 100,
        ),
      );
    }

    if (normalizedWeight.isEmpty || normalizedCalories.isEmpty) {
      return const _NormalizedComparisonResult(
        range: null,
        weightSeries: <DailyValuePoint>[],
        calorieSeries: <DailyValuePoint>[],
      );
    }

    return _NormalizedComparisonResult(
      range: DateTimeRange(
        start: normalizedWeight.first.day,
        end: normalizedWeight.last.day,
      ),
      weightSeries: normalizedWeight,
      calorieSeries: normalizedCalories,
    );
  }

  static BodyNutritionInsightType _legacyInsightType({
    required BodyNutritionRelationshipType relationship,
    required BodyNutritionTrendDirection weightTrend,
    required BodyNutritionTrendDirection calorieTrend,
  }) {
    switch (relationship) {
      case BodyNutritionRelationshipType.insufficientData:
        return BodyNutritionInsightType.notEnoughData;
      case BodyNutritionRelationshipType.alignedBulkLike:
        return BodyNutritionInsightType.weightUpCaloriesUp;
      case BodyNutritionRelationshipType.alignedCutLike:
        return BodyNutritionInsightType.weightDownCaloriesDown;
      case BodyNutritionRelationshipType.stableMaintenanceLike:
        return BodyNutritionInsightType.stableWeightCaloriesUp;
      case BodyNutritionRelationshipType.mixedOrUnclear:
        if (calorieTrend == BodyNutritionTrendDirection.falling &&
            (weightTrend == BodyNutritionTrendDirection.stable ||
                weightTrend == BodyNutritionTrendDirection.unclear)) {
          return BodyNutritionInsightType.caloriesDownWeightNotYetChanged;
        }
        return BodyNutritionInsightType.mixed;
    }
  }

  static List<DailyValuePoint> movingAverage({
    required List<DailyValuePoint> series,
    required int windowSize,
  }) {
    if (series.isEmpty) return const [];
    if (windowSize <= 1) return List<DailyValuePoint>.from(series);

    final values = series.map((p) => p.value).toList(growable: false);
    final result = <DailyValuePoint>[];

    for (var i = 0; i < series.length; i++) {
      final start = (i - windowSize + 1).clamp(0, i);
      final slice = values.sublist(start, i + 1);
      final avg =
          slice.fold<double>(0.0, (sum, value) => sum + value) / slice.length;
      result.add(DailyValuePoint(day: series[i].day, value: avg));
    }

    return result;
  }

  static double? weightChange(
    List<DailyValuePoint> smoothedWeight,
    List<DailyValuePoint> rawWeight,
  ) {
    final source = smoothedWeight.length >= 2 ? smoothedWeight : rawWeight;
    if (source.length < 2) return null;
    return source.last.value - source.first.value;
  }

  static BodyNutritionInsightType deriveInsight({
    required DateTimeRange range,
    required int totalDays,
    required List<DailyValuePoint> weightDaily,
    required List<DailyValuePoint> smoothedWeight,
    required List<DailyValuePoint> caloriesDaily,
    required List<DailyValuePoint> smoothedCalories,
    required int loggedCalorieDays,
    required double? weightChangeKg,
    StatisticsDataQualityAssessment? qualityAssessment,
  }) {
    final _ = weightChangeKg; // kept for backward compatibility
    final usedWeight = smoothedWeight.isNotEmpty ? smoothedWeight : weightDaily;
    final usedCalories =
        smoothedCalories.isNotEmpty ? smoothedCalories : caloriesDaily;
    final weightTrend = _computeTrendSnapshot(
      series: usedWeight,
      unit: _TrendUnit.weightKg,
    );
    final calorieTrend = _computeTrendSnapshot(
      series: usedCalories.where((p) => p.value > 0).toList(growable: false),
      unit: _TrendUnit.caloriesKcal,
    );

    final quality = BodyNutritionDataQualitySummary(
      spanDays: totalDays,
      weightDays: weightDaily.length,
      calorieDays: loggedCalorieDays,
      overlapDays: math.min(weightDaily.length, loggedCalorieDays),
      weightCoverage: totalDays <= 0 ? 0 : weightDaily.length / totalDays,
      calorieCoverage: totalDays <= 0 ? 0 : loggedCalorieDays / totalDays,
      overlapCoverage: totalDays <= 0
          ? 0
          : math.min(weightDaily.length, loggedCalorieDays) / totalDays,
      weightLargestGapDays: totalDays,
      calorieLargestGapDays: totalDays,
    );
    final confidence = _classifyConfidence(
      quality: quality,
      weightTrend: weightTrend,
      calorieTrend: calorieTrend,
    );
    final relationship = _classifyRelationship(
      confidence: confidence,
      weightTrend: weightTrend.direction,
      calorieTrend: calorieTrend.direction,
    );

    final fromQuality = qualityAssessment?.hasSufficientData == false;
    if (fromQuality) return BodyNutritionInsightType.notEnoughData;

    return _legacyInsightType(
      relationship: relationship,
      weightTrend: weightTrend.direction,
      calorieTrend: calorieTrend.direction,
    );
  }

  static double? seriesHalfDelta(List<DailyValuePoint> series) {
    if (series.length < 8) return null;
    final half = (series.length / 2).floor();
    if (half <= 0 || half >= series.length) return null;

    final first = series.sublist(0, half);
    final second = series.sublist(half);

    final firstAvg =
        first.fold<double>(0.0, (sum, p) => sum + p.value) / first.length;
    final secondAvg =
        second.fold<double>(0.0, (sum, p) => sum + p.value) / second.length;

    return secondAvg - firstAvg;
  }
}

enum _TrendUnit { weightKg, caloriesKcal }

class _NormalizedComparisonResult {
  const _NormalizedComparisonResult({
    required this.range,
    required this.weightSeries,
    required this.calorieSeries,
  });

  final DateTimeRange? range;
  final List<DailyValuePoint> weightSeries;
  final List<DailyValuePoint> calorieSeries;
}
