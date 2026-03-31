import '../derived/nightly_sleep_analysis.dart';
import 'sleep_period_aggregations.dart';

WeekSleepAggregation aggregateWeeklySleep({
  required DateTime weekStart,
  required List<NightlySleepAnalysis> analyses,
}) {
  return const SleepPeriodAggregationEngine().aggregateWeek(
    weekStart: weekStart,
    analyses: analyses,
  );
}
