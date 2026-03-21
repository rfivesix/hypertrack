import 'package:flutter/material.dart';

enum StatisticsRangeSemantics {
  selected,
  fixed,
  capped,
  dynamicAll,
}

enum StatisticsMetricId {
  bodyNutritionTrend,
  muscleAnalytics,
  hubMuscleAnalytics,
  hubNotablePrImprovements,
  prNotableImprovements,
  consistencyWeeklyMetrics,
  consistencyCalendar,
  hubWeeklyVolume,
  hubWorkoutsPerWeek,
  hubConsistencyMetrics,
  bodyNutritionInsightKpi,
}

class StatisticsMetricRangeMetadata {
  final StatisticsMetricId metricId;
  final StatisticsRangeSemantics semantics;
  final int? fixedDays;
  final int? fixedWeeks;
  final int? capDays;
  final String disclosureHook;

  const StatisticsMetricRangeMetadata({
    required this.metricId,
    required this.semantics,
    required this.disclosureHook,
    this.fixedDays,
    this.fixedWeeks,
    this.capDays,
  });
}

class StatisticsResolvedRange {
  final StatisticsRangeSemantics semantics;
  final int? effectiveDays;
  final int? effectiveWeeks;
  final DateTimeRange? dateRange;
  final String disclosureHook;

  const StatisticsResolvedRange({
    required this.semantics,
    required this.disclosureHook,
    this.effectiveDays,
    this.effectiveWeeks,
    this.dateRange,
  });
}

class StatisticsRangePolicyService {
  const StatisticsRangePolicyService._();

  static const StatisticsRangePolicyService instance =
      StatisticsRangePolicyService._();

  static const List<int> selectableDayRanges = [7, 30, 90, 180, 3650];

  static const Map<StatisticsMetricId, StatisticsMetricRangeMetadata> metadata = {
    StatisticsMetricId.bodyNutritionTrend: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.bodyNutritionTrend,
      semantics: StatisticsRangeSemantics.dynamicAll,
      disclosureHook: 'range:dynamic-all',
    ),
    StatisticsMetricId.muscleAnalytics: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.muscleAnalytics,
      semantics: StatisticsRangeSemantics.selected,
      disclosureHook: 'range:selected',
    ),
    StatisticsMetricId.hubMuscleAnalytics: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.hubMuscleAnalytics,
      semantics: StatisticsRangeSemantics.selected,
      fixedWeeks: 8,
      disclosureHook: 'range:selected+fixed-weeks',
    ),
    StatisticsMetricId.hubNotablePrImprovements: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.hubNotablePrImprovements,
      semantics: StatisticsRangeSemantics.capped,
      capDays: 90,
      disclosureHook: 'range:capped-90d',
    ),
    StatisticsMetricId.prNotableImprovements: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.prNotableImprovements,
      semantics: StatisticsRangeSemantics.selected,
      disclosureHook: 'range:selected',
    ),
    StatisticsMetricId.consistencyWeeklyMetrics: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.consistencyWeeklyMetrics,
      semantics: StatisticsRangeSemantics.fixed,
      fixedWeeks: 12,
      disclosureHook: 'range:fixed-12w',
    ),
    StatisticsMetricId.consistencyCalendar: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.consistencyCalendar,
      semantics: StatisticsRangeSemantics.fixed,
      fixedDays: 120,
      disclosureHook: 'range:fixed-120d',
    ),
    StatisticsMetricId.hubWeeklyVolume: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.hubWeeklyVolume,
      semantics: StatisticsRangeSemantics.fixed,
      fixedWeeks: 6,
      disclosureHook: 'range:fixed-6w',
    ),
    StatisticsMetricId.hubWorkoutsPerWeek: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.hubWorkoutsPerWeek,
      semantics: StatisticsRangeSemantics.fixed,
      fixedWeeks: 6,
      disclosureHook: 'range:fixed-6w',
    ),
    StatisticsMetricId.hubConsistencyMetrics: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.hubConsistencyMetrics,
      semantics: StatisticsRangeSemantics.fixed,
      fixedWeeks: 6,
      disclosureHook: 'range:fixed-6w',
    ),
    StatisticsMetricId.bodyNutritionInsightKpi: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.bodyNutritionInsightKpi,
      semantics: StatisticsRangeSemantics.dynamicAll,
      disclosureHook: 'range:dynamic-all',
    ),
  };

  int selectedDaysFromIndex(int index) {
    if (index < 0 || index >= selectableDayRanges.length) {
      return 30;
    }
    return selectableDayRanges[index];
  }

  bool isAllRangeIndex(int index) => index == selectableDayRanges.length - 1;

  StatisticsResolvedRange resolve({
    required StatisticsMetricId metricId,
    int? selectedRangeIndex,
    int? selectedDays,
    DateTime? now,
    DateTime? earliestAvailableDay,
    int? effectiveWeeks,
  }) {
    final policy = metadata[metricId]!;
    final anchor = _normalizeDay(now ?? DateTime.now());
    final resolvedSelectedDays =
        selectedDays ?? selectedDaysFromIndex(selectedRangeIndex ?? 1);
    final isAllSelection = selectedRangeIndex != null &&
        isAllRangeIndex(selectedRangeIndex) &&
        selectedDays == null;

    int? days = policy.fixedDays;
    switch (policy.semantics) {
      case StatisticsRangeSemantics.selected:
        days = resolvedSelectedDays;
        break;
      case StatisticsRangeSemantics.fixed:
        days = policy.fixedDays;
        break;
      case StatisticsRangeSemantics.capped:
        final cap = policy.capDays ?? resolvedSelectedDays;
        days = resolvedSelectedDays < cap ? resolvedSelectedDays : cap;
        break;
      case StatisticsRangeSemantics.dynamicAll:
        if (isAllSelection) {
          if (earliestAvailableDay != null) {
            final start = _normalizeDay(earliestAvailableDay);
            final dynamicDays = anchor.difference(start).inDays + 1;
            days = dynamicDays > 0 ? dynamicDays : 1;
          } else {
            days = 1;
          }
        } else {
          days = resolvedSelectedDays;
        }
        break;
    }

    final hasRange = days != null && days > 0;
    final range = hasRange
        ? DateTimeRange(
            start: anchor.subtract(Duration(days: days! - 1)),
            end: _endOfDay(anchor),
          )
        : null;

    return StatisticsResolvedRange(
      semantics: policy.semantics,
      disclosureHook: policy.disclosureHook,
      effectiveDays: days,
      effectiveWeeks: effectiveWeeks ?? policy.fixedWeeks,
      dateRange: range,
    );
  }

  int resolveWeeksBack({
    required StatisticsMetricId metricId,
    int? effectiveDays,
  }) {
    final policy = metadata[metricId]!;
    if (policy.fixedWeeks != null) {
      return policy.fixedWeeks!;
    }

    if (metricId == StatisticsMetricId.muscleAnalytics && effectiveDays != null) {
      final derived = (effectiveDays / 7).ceil();
      return derived.clamp(4, 16);
    }

    return 1;
  }

  DateTime _normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);
}
