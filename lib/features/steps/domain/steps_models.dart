class StepsBucket {
  const StepsBucket({
    required this.start,
    required this.steps,
  });

  final DateTime start;
  final int steps;
}

enum StepsScope { day, week, month }

class DayStepsAggregation {
  const DayStepsAggregation({
    required this.date,
    required this.hourlyBuckets,
    required this.totalSteps,
  });

  final DateTime date;
  final List<StepsBucket> hourlyBuckets;
  final int totalSteps;
}

class WeekStepsAggregation {
  const WeekStepsAggregation({
    required this.weekStart,
    required this.dailyTotals,
    required this.totalSteps,
    required this.averageDailySteps,
  });

  final DateTime weekStart;
  final List<StepsBucket> dailyTotals;
  final int totalSteps;
  final double averageDailySteps;
}

class MonthStepsAggregation {
  const MonthStepsAggregation({
    required this.monthStart,
    required this.dailyTotals,
    required this.totalSteps,
  });

  final DateTime monthStart;
  final List<StepsBucket> dailyTotals;
  final int totalSteps;
}
