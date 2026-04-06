import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/database_helper.dart';
import '../../../models/chart_data_point.dart';
import '../../../models/fluid_entry.dart';
import '../../../services/health/steps_sync_service.dart';
import '../../../data/drift_database.dart' as db;
import '../domain/goal_models.dart';
import '../domain/recommendation_models.dart';

class RecommendationInputAdapter {
  static const int defaultPriorStepsLookbackDays = 21;

  final DatabaseHelper _databaseHelper;

  const RecommendationInputAdapter({
    required DatabaseHelper databaseHelper,
  }) : _databaseHelper = databaseHelper;

  static DateTime normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  Future<RecommendationGenerationInput> buildInput({
    required DateTime now,
    int rollingWindowDays = 21,
    PriorActivityLevel declaredActivityLevel = PriorActivityLevel.moderate,
    ExtraCardioHoursOption extraCardioHoursOption = ExtraCardioHoursOption.h0,
  }) async {
    final windowEndDay = normalizeDay(now);
    final windowStartDay = windowEndDay
        .subtract(Duration(days: math.max(rollingWindowDays, 1) - 1));

    final rangeStart = windowStartDay;
    final rangeEnd = endOfDay(windowEndDay);

    final results = await Future.wait<dynamic>([
      _databaseHelper.getChartDataForTypeAndRange(
        'weight',
        DateTimeRange(start: rangeStart, end: rangeEnd),
      ),
      _databaseHelper.getFoodCaloriesByDayForDateRange(rangeStart, rangeEnd),
      _databaseHelper.getFluidEntriesForDateRange(rangeStart, rangeEnd),
      _databaseHelper.getUserProfile(),
      _databaseHelper.getGoalsForDate(now),
      _databaseHelper.getLatestBodyFatPercentageBefore(rangeEnd),
      _databaseHelper.getAverageCompletedWorkoutsPerWeek(now: rangeEnd),
      _databaseHelper.getAppSettings(),
    ]);

    final weightPoints = results[0] as List<ChartDataPoint>;
    final foodCaloriesResult = results[1] as FoodCaloriesByDayResult;
    final fluidEntries = results[2] as List<FluidEntry>;
    final profile = results[3] as db.Profile?;
    final activeGoals = results[4] as db.DailyGoalsHistoryData?;
    final bodyFatPercent = results[5] as double?;
    final averageCompletedWorkoutsPerWeek = results[6] as double;
    final appSettings = results[7] as db.AppSetting?;
    final recentAverageActualSteps = await loadRecentAverageActualSteps(
      databaseHelper: _databaseHelper,
      endDay: windowEndDay,
      lookbackDays: rollingWindowDays,
    );

    final caloriesByDay = _buildCaloriesByDay(
      foodCaloriesByDay: foodCaloriesResult.caloriesByDay,
      fluidEntries: fluidEntries,
    );

    final weightByDay = _latestWeightByDay(weightPoints);
    final sortedWeightDays = weightByDay.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    final sortedWeightSeries = sortedWeightDays
        .map((day) => _WeightedDayPoint(day: day, value: weightByDay[day]!))
        .toList(growable: false);

    final smoothedWeightSeries = _ewma(
      sortedWeightSeries,
      alpha: 0.35,
    );
    final weightSlopeKgPerWeek =
        _trendSlopeKgPerWeek(smoothedWeightSeries, sortedWeightSeries);

    final intakeLoggedDays =
        caloriesByDay.values.where((value) => value > 0).length;
    final loggedCaloriesTotal = caloriesByDay.values
        .where((value) => value > 0)
        .fold<double>(0.0, (sum, value) => sum + value);
    final avgLoggedCalories =
        intakeLoggedDays == 0 ? 0.0 : loggedCaloriesTotal / intakeLoggedDays;

    final currentWeightKg =
        sortedWeightSeries.isNotEmpty ? sortedWeightSeries.last.value : 75.0;
    final priorMaintenanceCalories = estimatePriorMaintenanceCalories(
      profile: profile,
      currentWeightKg: currentWeightKg,
      bodyFatPercent: bodyFatPercent,
      declaredActivityLevel: declaredActivityLevel,
      extraCardioHoursOption: extraCardioHoursOption,
      averageCompletedWorkoutsPerWeek: averageCompletedWorkoutsPerWeek,
      targetSteps: appSettings?.targetSteps,
      recentAverageSteps: recentAverageActualSteps,
      now: now,
    );

    final windowDays = _usableWindowDays(
      weightDays: sortedWeightDays,
      caloriesByDay: caloriesByDay,
    );

    final qualityFlags = <String>[];
    if (weightSlopeKgPerWeek == null) {
      qualityFlags.add('weight_trend_unavailable');
    }
    if (intakeLoggedDays < 5) {
      qualityFlags.add('sparse_intake_logs');
    }
    if (sortedWeightSeries.length < 3) {
      qualityFlags.add('sparse_weight_logs');
    }
    if (foodCaloriesResult.unresolvedEntryCount > 0) {
      qualityFlags.add('unresolved_food_calories');
    }

    return RecommendationGenerationInput(
      windowStart: windowStartDay,
      windowEnd: rangeEnd,
      windowDays: windowDays,
      weightLogCount: sortedWeightSeries.length,
      intakeLoggedDays: intakeLoggedDays,
      smoothedWeightSlopeKgPerWeek: weightSlopeKgPerWeek,
      avgLoggedCalories: avgLoggedCalories,
      currentWeightKg: currentWeightKg,
      priorMaintenanceCalories: priorMaintenanceCalories,
      activeTargetCalories: activeGoals?.targetCalories,
      qualityFlags: qualityFlags,
    );
  }

  static int estimatePriorMaintenanceCalories({
    required db.Profile? profile,
    required double currentWeightKg,
    required DateTime now,
    double? bodyFatPercent,
    PriorActivityLevel declaredActivityLevel = PriorActivityLevel.moderate,
    ExtraCardioHoursOption extraCardioHoursOption = ExtraCardioHoursOption.h0,
    double? averageCompletedWorkoutsPerWeek,
    int? targetSteps,
    int? recentAverageSteps,
    int fallbackHeightCm = 175,
  }) {
    final weightKg = currentWeightKg > 0 ? currentWeightKg : 75.0;
    final heightCm = profile?.height ?? fallbackHeightCm;
    final ageYears = _estimateAgeYears(profile?.birthday, now) ?? 30;
    final gender = profile?.gender;

    // If body-fat percentage is available, use a lean-mass-aware prior via
    // Katch-McArdle; otherwise fall back to a profile-based Mifflin prior.
    final validBodyFatPercent =
        (bodyFatPercent != null && bodyFatPercent > 3 && bodyFatPercent < 70)
            ? bodyFatPercent
            : null;

    late final double rmr;
    if (validBodyFatPercent != null) {
      final leanMassKg = weightKg * (1 - (validBodyFatPercent / 100.0));
      rmr = 370 + (21.6 * leanMassKg);
    } else {
      final baseMifflin = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears);
      if (gender == 'male') {
        rmr = baseMifflin + 5;
      } else if (gender == 'female') {
        rmr = baseMifflin - 161;
      } else {
        rmr = baseMifflin - 78;
      }
    }

    final activityFactor = _activityFactorFor(
      declaredActivityLevel: declaredActivityLevel,
      extraCardioHoursOption: extraCardioHoursOption,
      averageCompletedWorkoutsPerWeek: averageCompletedWorkoutsPerWeek,
      targetSteps: targetSteps,
      recentAverageSteps: recentAverageSteps,
    );

    final maintenance = rmr * activityFactor;
    return maintenance.round().clamp(1200, 5000);
  }

  static double _activityFactorFor({
    required PriorActivityLevel declaredActivityLevel,
    required ExtraCardioHoursOption extraCardioHoursOption,
    required double? averageCompletedWorkoutsPerWeek,
    required int? targetSteps,
    required int? recentAverageSteps,
  }) {
    var factor = switch (declaredActivityLevel) {
      PriorActivityLevel.low => 1.35,
      PriorActivityLevel.moderate => 1.50,
      PriorActivityLevel.high => 1.65,
      PriorActivityLevel.veryHigh => 1.75,
    };

    final workoutsPerWeek = averageCompletedWorkoutsPerWeek ?? 0;
    if (workoutsPerWeek >= 5) {
      factor += 0.06;
    } else if (workoutsPerWeek >= 3) {
      factor += 0.04;
    } else if (workoutsPerWeek >= 1) {
      factor += 0.02;
    }

    final steps = _effectiveStepsForPrior(
      recentAverageSteps: recentAverageSteps,
      targetSteps: targetSteps,
    );
    if (steps >= 13000) {
      factor += 0.05;
    } else if (steps >= 10000) {
      factor += 0.03;
    } else if (steps < 7000) {
      factor -= 0.03;
    }

    // Extra cardio/endurance hours are explicitly intended for sessions
    // outside app-captured workouts, so we apply a small bounded uplift.
    factor += _extraCardioFactorAdjustment(extraCardioHoursOption);

    return factor.clamp(1.20, 1.95);
  }

  static double _extraCardioFactorAdjustment(ExtraCardioHoursOption option) {
    switch (option) {
      case ExtraCardioHoursOption.h0:
        return 0.00;
      case ExtraCardioHoursOption.h1:
        return 0.01;
      case ExtraCardioHoursOption.h2:
        return 0.02;
      case ExtraCardioHoursOption.h3:
        return 0.03;
      case ExtraCardioHoursOption.h5:
        return 0.05;
      case ExtraCardioHoursOption.h7Plus:
        return 0.07;
    }
  }

  static int _effectiveStepsForPrior({
    required int? recentAverageSteps,
    required int? targetSteps,
  }) {
    if (recentAverageSteps != null && recentAverageSteps > 0) {
      return recentAverageSteps;
    }
    return targetSteps ?? 8000;
  }

  static int? _estimateAgeYears(DateTime? birthday, DateTime now) {
    if (birthday == null) {
      return null;
    }
    var years = now.year - birthday.year;
    final hadBirthdayThisYear = now.month > birthday.month ||
        (now.month == birthday.month && now.day >= birthday.day);
    if (!hadBirthdayThisYear) {
      years -= 1;
    }
    return years < 0 ? null : years;
  }

  int _usableWindowDays({
    required List<DateTime> weightDays,
    required Map<DateTime, double> caloriesByDay,
  }) {
    final intakeDays = caloriesByDay.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList(growable: false);

    final allDataDays = <DateTime>{...weightDays, ...intakeDays}.toList()
      ..sort((a, b) => a.compareTo(b));

    if (allDataDays.isEmpty) {
      return 0;
    }

    final first = allDataDays.first;
    final last = allDataDays.last;
    return normalizeDay(last).difference(normalizeDay(first)).inDays + 1;
  }

  Map<DateTime, double> _buildCaloriesByDay({
    required Map<DateTime, double> foodCaloriesByDay,
    required List<FluidEntry> fluidEntries,
  }) {
    final caloriesByDay = <DateTime, double>{...foodCaloriesByDay};

    for (final entry in fluidEntries) {
      final day = normalizeDay(entry.timestamp);
      final addedCalories = (entry.kcal ?? 0).toDouble();
      caloriesByDay[day] = (caloriesByDay[day] ?? 0.0) + addedCalories;
    }

    return caloriesByDay;
  }

  Map<DateTime, double> _latestWeightByDay(List<ChartDataPoint> points) {
    final sorted = points.toList()..sort((a, b) => a.date.compareTo(b.date));
    final byDay = <DateTime, double>{};

    for (final point in sorted) {
      byDay[normalizeDay(point.date)] = point.value;
    }

    return byDay;
  }

  List<_WeightedDayPoint> _ewma(
    List<_WeightedDayPoint> source, {
    required double alpha,
  }) {
    if (source.isEmpty) {
      return const [];
    }

    final smoothed = <_WeightedDayPoint>[];
    var previous = source.first.value;

    for (final point in source) {
      final next = (alpha * point.value) + ((1 - alpha) * previous);
      smoothed.add(_WeightedDayPoint(day: point.day, value: next));
      previous = next;
    }

    return smoothed;
  }

  double? _trendSlopeKgPerWeek(
    List<_WeightedDayPoint> smoothed,
    List<_WeightedDayPoint> raw,
  ) {
    // Use EWMA-smoothed series whenever possible, then fit a linear
    // regression (weight over day-index) and convert slope to kg/week.
    final source = smoothed.length >= 2 ? smoothed : raw;
    if (source.length < 2) {
      return null;
    }

    final anchorDay = normalizeDay(source.first.day);
    final xValues = <double>[];
    final yValues = <double>[];

    for (final point in source) {
      final x = normalizeDay(point.day).difference(anchorDay).inDays.toDouble();
      xValues.add(x);
      yValues.add(point.value);
    }

    final count = source.length;
    final meanX =
        xValues.fold<double>(0.0, (sum, value) => sum + value) / count;
    final meanY =
        yValues.fold<double>(0.0, (sum, value) => sum + value) / count;

    var numerator = 0.0;
    var denominator = 0.0;
    for (var i = 0; i < count; i++) {
      final xDelta = xValues[i] - meanX;
      final yDelta = yValues[i] - meanY;
      numerator += xDelta * yDelta;
      denominator += xDelta * xDelta;
    }

    if (denominator <= 0) {
      return null;
    }

    final slopeKgPerDay = numerator / denominator;
    return slopeKgPerDay * 7;
  }

  static Future<int?> loadRecentAverageActualSteps({
    required DatabaseHelper databaseHelper,
    required DateTime endDay,
    required int lookbackDays,
  }) async {
    final safeLookback = math.max(lookbackDays, 1);
    final normalizedEndDay = normalizeDay(endDay);
    final startDay = normalizedEndDay.subtract(
      Duration(days: safeLookback - 1),
    );
    final stepsSyncService = StepsSyncService(dbHelper: databaseHelper);
    final providerFilter = StepsSyncService.providerFilterToRaw(
      await stepsSyncService.getProviderFilter(),
    );
    final sourcePolicy = StepsSyncService.sourcePolicyToRaw(
      await stepsSyncService.getSourcePolicy(),
    );

    final rows = await databaseHelper.getDailyStepsTotalsForRange(
      startLocal: startDay,
      endLocal: normalizedEndDay,
      providerFilter: providerFilter,
      sourcePolicy: sourcePolicy,
    );
    final usableDayTotals = rows
        .map((row) => row['totalSteps'] as int? ?? 0)
        .where((total) => total > 0)
        .toList(growable: false);

    if (usableDayTotals.isEmpty) {
      return null;
    }

    final total = usableDayTotals.fold<int>(0, (sum, steps) => sum + steps);
    return (total / usableDayTotals.length).round();
  }
}

class _WeightedDayPoint {
  final DateTime day;
  final double value;

  const _WeightedDayPoint({
    required this.day,
    required this.value,
  });
}
