import '../derived/nightly_sleep_analysis.dart';
import 'sleep_period_aggregations.dart';

MonthSleepAggregation aggregateMonthlySleep({
  required DateTime monthStart,
  required List<NightlySleepAnalysis> analyses,
}) {
  return const SleepPeriodAggregationEngine().aggregateMonth(
    monthStart: monthStart,
    analyses: analyses,
  );
}
