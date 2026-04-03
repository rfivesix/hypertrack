import 'dart:math' as math;

import '../derived/nightly_sleep_analysis.dart';
import '../sleep_enums.dart';

class SleepDayAggregate {
  const SleepDayAggregate({
    required this.date,
    required this.score,
    required this.sleepQuality,
    this.totalSleepMinutes,
  });

  final DateTime date;
  final double? score;
  final SleepQualityBucket sleepQuality;
  final int? totalSleepMinutes;
}

class SleepWindowSegment {
  const SleepWindowSegment({
    required this.date,
    this.startMinutes,
    this.endMinutes,
    this.hasData = false,
  });

  final DateTime date;
  final int? startMinutes;
  final int? endMinutes;
  final bool hasData;
}

class WeekSleepAggregation {
  const WeekSleepAggregation({
    required this.weekStart,
    required this.days,
    required this.sleepWindows,
    required this.meanScore,
    required this.weekdayAverageDuration,
    required this.weekendAverageDuration,
  });

  final DateTime weekStart;
  final List<SleepDayAggregate> days;
  final List<SleepWindowSegment> sleepWindows;
  final double? meanScore;
  final Duration? weekdayAverageDuration;
  final Duration? weekendAverageDuration;
}

class MonthSleepAggregation {
  const MonthSleepAggregation({
    required this.monthStart,
    required this.days,
    required this.meanScore,
    required this.weekdayAverageDuration,
    required this.weekendAverageDuration,
  });

  final DateTime monthStart;
  final List<SleepDayAggregate> days;
  final double? meanScore;
  final Duration? weekdayAverageDuration;
  final Duration? weekendAverageDuration;
}

class SleepPeriodAggregationEngine {
  const SleepPeriodAggregationEngine();

  WeekSleepAggregation aggregateWeek({
    required DateTime weekStart,
    required List<NightlySleepAnalysis> analyses,
  }) {
    final normalizedStart = _normalizeDate(weekStart);
    final byDate = _latestByDate(analyses);
    final days = <SleepDayAggregate>[];
    final windows = <SleepWindowSegment>[];
    for (var i = 0; i < 7; i++) {
      final date = normalizedStart.add(Duration(days: i));
      final analysis = byDate[date];
      days.add(
        SleepDayAggregate(
          date: date,
          score: analysis?.score,
          sleepQuality:
              analysis?.sleepQuality ?? SleepQualityBucket.unavailable,
          totalSleepMinutes: analysis?.totalSleepMinutes,
        ),
      );
      windows.add(_toWindow(date, analysis));
    }
    return WeekSleepAggregation(
      weekStart: normalizedStart,
      days: days,
      sleepWindows: windows,
      meanScore: _meanScore(days),
      weekdayAverageDuration: _averageDuration(
        days.where((day) => day.date.weekday <= DateTime.friday).toList(),
      ),
      weekendAverageDuration: _averageDuration(
        days.where((day) => day.date.weekday >= DateTime.saturday).toList(),
      ),
    );
  }

  MonthSleepAggregation aggregateMonth({
    required DateTime monthStart,
    required List<NightlySleepAnalysis> analyses,
  }) {
    final normalizedMonthStart = DateTime(monthStart.year, monthStart.month, 1);
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
    final byDate = _latestByDate(analyses);
    final days = <SleepDayAggregate>[];
    for (var date = normalizedMonthStart;
        !date.isAfter(monthEnd);
        date = date.add(const Duration(days: 1))) {
      final analysis = byDate[date];
      days.add(
        SleepDayAggregate(
          date: date,
          score: analysis?.score,
          sleepQuality:
              analysis?.sleepQuality ?? SleepQualityBucket.unavailable,
          totalSleepMinutes: analysis?.totalSleepMinutes,
        ),
      );
    }

    return MonthSleepAggregation(
      monthStart: normalizedMonthStart,
      days: days,
      meanScore: _meanScore(days),
      weekdayAverageDuration: _averageDuration(
        days.where((day) => day.date.weekday <= DateTime.friday).toList(),
      ),
      weekendAverageDuration: _averageDuration(
        days.where((day) => day.date.weekday >= DateTime.saturday).toList(),
      ),
    );
  }

  Map<DateTime, NightlySleepAnalysis> _latestByDate(
    List<NightlySleepAnalysis> analyses,
  ) {
    final byDate = <DateTime, NightlySleepAnalysis>{};
    for (final analysis in analyses) {
      final key = _normalizeDate(analysis.nightDate);
      final existing = byDate[key];
      if (existing == null ||
          analysis.analyzedAtUtc.isAfter(existing.analyzedAtUtc)) {
        byDate[key] = analysis;
      }
    }
    return byDate;
  }

  SleepWindowSegment _toWindow(DateTime date, NightlySleepAnalysis? analysis) {
    final totalMinutes = analysis?.totalSleepMinutes;
    if (totalMinutes == null || totalMinutes <= 0) {
      return SleepWindowSegment(date: date, hasData: false);
    }
    const wakeAnchor = 6 * 60;
    final start = ((wakeAnchor - totalMinutes) % 1440 + 1440) % 1440;
    final end = wakeAnchor;
    return SleepWindowSegment(
      date: date,
      startMinutes: start,
      endMinutes: end,
      hasData: true,
    );
  }

  double? _meanScore(List<SleepDayAggregate> days) {
    final values = days.map((day) => day.score).whereType<double>().toList();
    if (values.isEmpty) return null;
    final sum = values.fold<double>(0, (total, value) => total + value);
    return sum / values.length;
  }

  Duration? _averageDuration(List<SleepDayAggregate> days) {
    final durations = days
        .map((day) => day.totalSleepMinutes)
        .whereType<int>()
        .where((minutes) => minutes > 0)
        .toList();
    if (durations.isEmpty) return null;
    final sum = durations.fold<int>(0, (total, value) => total + value);
    return Duration(minutes: (sum / durations.length).round());
  }

  DateTime _normalizeDate(DateTime value) => DateTime(
        value.year,
        value.month,
        value.day,
      );
}

extension SleepWindowSegmentX on SleepWindowSegment {
  int get displayEndMinutes {
    if (!hasData || startMinutes == null || endMinutes == null) return 0;
    if (endMinutes! <= startMinutes!) return endMinutes! + 1440;
    return endMinutes!;
  }

  int get displayStartMinutes {
    if (!hasData || startMinutes == null) return 0;
    final end = displayEndMinutes;
    final start = startMinutes!;
    if (end <= 0) return start;
    if (start > end) return start - 1440;
    return start;
  }

  double normalizedTop({int minMinutes = 20 * 60, int maxMinutes = 36 * 60}) {
    if (!hasData) return 0;
    final range = math.max(1, maxMinutes - minMinutes);
    final start = displayStartMinutes;
    return ((start - minMinutes) / range).clamp(0.0, 1.0).toDouble();
  }

  double normalizedHeight({
    int minMinutes = 20 * 60,
    int maxMinutes = 36 * 60,
  }) {
    if (!hasData || startMinutes == null || endMinutes == null) return 0;
    final range = math.max(1, maxMinutes - minMinutes);
    final duration = math.max(1, displayEndMinutes - displayStartMinutes);
    return (duration / range).clamp(0.0, 1.0).toDouble();
  }
}
