import 'dart:math';

import '../domain/steps_models.dart';

abstract class StepsAggregationRepository {
  Future<DayStepsAggregation> getDayAggregation(DateTime date);
  Future<WeekStepsAggregation> getWeekAggregation(DateTime dateInWeek);
  Future<MonthStepsAggregation> getMonthAggregation(DateTime dateInMonth);
}

class InMemoryStepsAggregationRepository implements StepsAggregationRepository {
  const InMemoryStepsAggregationRepository();

  @override
  Future<DayStepsAggregation> getDayAggregation(DateTime date) async {
    final targetDate = _atStartOfDay(date);
    final seed = targetDate.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final rng = Random(seed);

    final hourly = List.generate(24, (index) {
      final hourStart = targetDate.add(Duration(hours: index));
      final baseline = index >= 6 && index <= 21 ? 180 : 30;
      final variance = index >= 8 && index <= 19 ? 320 : 80;
      return StepsBucket(
        start: hourStart,
        steps: baseline + rng.nextInt(variance + 1),
      );
    });

    final total = hourly.fold<int>(0, (sum, bucket) => sum + bucket.steps);
    return DayStepsAggregation(
      date: targetDate,
      hourlyBuckets: hourly,
      totalSteps: total,
    );
  }

  @override
  Future<WeekStepsAggregation> getWeekAggregation(DateTime dateInWeek) async {
    final weekStart = _startOfWeek(dateInWeek);
    final seed = weekStart.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final rng = Random(seed);

    final daily = List.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      final weekdayBoost = index < 5 ? 1200 : 400;
      final steps = 3500 + weekdayBoost + rng.nextInt(5200);
      return StepsBucket(start: day, steps: steps);
    });

    final total = daily.fold<int>(0, (sum, bucket) => sum + bucket.steps);
    return WeekStepsAggregation(
      weekStart: weekStart,
      dailyTotals: daily,
      totalSteps: total,
      averageDailySteps: total / daily.length,
    );
  }

  @override
  Future<MonthStepsAggregation> getMonthAggregation(DateTime dateInMonth) async {
    final monthStart = DateTime(dateInMonth.year, dateInMonth.month, 1);
    final nextMonth = DateTime(dateInMonth.year, dateInMonth.month + 1, 1);
    final daysInMonth = nextMonth.difference(monthStart).inDays;
    final seed = monthStart.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final rng = Random(seed);

    final daily = List.generate(daysInMonth, (index) {
      final day = monthStart.add(Duration(days: index));
      final weekday = day.weekday;
      final weekdayBoost = weekday <= DateTime.friday ? 900 : 250;
      final steps = 2400 + weekdayBoost + rng.nextInt(6000);
      return StepsBucket(start: day, steps: steps);
    });

    final total = daily.fold<int>(0, (sum, bucket) => sum + bucket.steps);
    return MonthStepsAggregation(
      monthStart: monthStart,
      dailyTotals: daily,
      totalSteps: total,
    );
  }

  DateTime _atStartOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  DateTime _startOfWeek(DateTime date) {
    final day = _atStartOfDay(date);
    final offset = day.weekday - DateTime.monday;
    return day.subtract(Duration(days: offset));
  }
}
