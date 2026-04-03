import 'dart:math';

import '../../../data/database_helper.dart';
import '../../../services/health/health_models.dart';
import '../../../services/health/steps_sync_service.dart';
import '../domain/steps_models.dart';

abstract class StepsAggregationRepository {
  Future<DayStepsAggregation> getDayAggregation(DateTime date);
  Future<WeekStepsAggregation> getWeekAggregation(DateTime dateInWeek);
  Future<MonthStepsAggregation> getMonthAggregation(DateTime dateInMonth);
  Future<RangeStepsAggregation> getRangeAggregation({
    required DateTime endDate,
    required int daysBack,
  });
  Future<DateTime?> getEarliestAvailableDate();
  Future<StepsRefreshResult> refresh({bool force = false, DateTime? now});
  Future<DateTime?> getLastUpdatedAt();
  Future<bool> isTrackingEnabled();
}

class InMemoryStepsAggregationRepository implements StepsAggregationRepository {
  const InMemoryStepsAggregationRepository();

  @override
  Future<DayStepsAggregation> getDayAggregation(DateTime date) async {
    final targetDate = _atStartOfDay(date);
    final seed =
        targetDate.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
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
    final seed =
        weekStart.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
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
  Future<MonthStepsAggregation> getMonthAggregation(
    DateTime dateInMonth,
  ) async {
    final monthStart = DateTime(dateInMonth.year, dateInMonth.month, 1);
    final nextMonth = DateTime(dateInMonth.year, dateInMonth.month + 1, 1);
    final daysInMonth = nextMonth.difference(monthStart).inDays;
    final seed =
        monthStart.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
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

  @override
  Future<RangeStepsAggregation> getRangeAggregation({
    required DateTime endDate,
    required int daysBack,
  }) async {
    final safeDays = daysBack < 1 ? 1 : daysBack;
    final normalizedEnd = _atStartOfDay(endDate);
    final normalizedStart = normalizedEnd.subtract(
      Duration(days: safeDays - 1),
    );
    final seed =
        normalizedStart.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final rng = Random(seed);
    final buckets = List.generate(safeDays, (index) {
      final day = normalizedStart.add(Duration(days: index));
      return StepsBucket(start: day, steps: 3000 + rng.nextInt(7000));
    });
    final total = buckets.fold<int>(0, (sum, bucket) => sum + bucket.steps);
    return RangeStepsAggregation(
      start: normalizedStart,
      end: normalizedEnd,
      dailyTotals: buckets,
      totalSteps: total,
      averageDailySteps: buckets.isEmpty ? 0 : total / buckets.length,
    );
  }

  @override
  Future<DateTime?> getEarliestAvailableDate() async =>
      DateTime.now().subtract(const Duration(days: 29));

  @override
  Future<StepsRefreshResult> refresh({
    bool force = false,
    DateTime? now,
  }) async {
    return StepsRefreshResult(
      didRun: true,
      permissionGranted: true,
      skipped: false,
      fetchedCount: 0,
      upsertedCount: 0,
      lastUpdatedAtUtc: (now ?? DateTime.now()).toUtc(),
    );
  }

  @override
  Future<DateTime?> getLastUpdatedAt() async => DateTime.now().toUtc();

  @override
  Future<bool> isTrackingEnabled() async => true;

  DateTime _atStartOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _startOfWeek(DateTime date) {
    final day = _atStartOfDay(date);
    final offset = day.weekday - DateTime.monday;
    return day.subtract(Duration(days: offset));
  }
}

class HealthStepsAggregationRepository implements StepsAggregationRepository {
  HealthStepsAggregationRepository({
    DatabaseHelper? dbHelper,
    StepsSyncService? stepsSyncService,
  })  : dbHelper = dbHelper ?? DatabaseHelper.instance,
        stepsSyncService = stepsSyncService ?? StepsSyncService();

  final DatabaseHelper dbHelper;
  final StepsSyncService stepsSyncService;

  @override
  Future<DayStepsAggregation> getDayAggregation(DateTime date) async {
    final targetDay = _atStartOfDay(date);
    final provider = await _providerFilterRaw();
    final sourcePolicy = await _sourcePolicyRaw();
    final rows = await dbHelper.getHourlyStepsTotalsForDay(
      dayLocal: targetDay,
      providerFilter: provider,
      sourcePolicy: sourcePolicy,
    );
    final byHour = <int, int>{
      for (final row in rows) row['hour'] as int: row['totalSteps'] as int,
    };
    final hourly = List.generate(24, (hour) {
      return StepsBucket(
        start: targetDay.add(Duration(hours: hour)),
        steps: byHour[hour] ?? 0,
      );
    });
    final total = hourly.fold<int>(0, (sum, bucket) => sum + bucket.steps);
    return DayStepsAggregation(
      date: targetDay,
      hourlyBuckets: hourly,
      totalSteps: total,
    );
  }

  @override
  Future<WeekStepsAggregation> getWeekAggregation(DateTime dateInWeek) async {
    final weekStart = _startOfWeek(dateInWeek);
    final range = await getRangeAggregation(
      endDate: weekStart.add(const Duration(days: 6)),
      daysBack: 7,
    );
    return WeekStepsAggregation(
      weekStart: weekStart,
      dailyTotals: range.dailyTotals,
      totalSteps: range.totalSteps,
      averageDailySteps: range.averageDailySteps,
    );
  }

  @override
  Future<MonthStepsAggregation> getMonthAggregation(
    DateTime dateInMonth,
  ) async {
    final monthStart = DateTime(dateInMonth.year, dateInMonth.month, 1);
    final nextMonth = DateTime(dateInMonth.year, dateInMonth.month + 1, 1);
    final days = nextMonth.difference(monthStart).inDays;
    final range = await getRangeAggregation(
      endDate: monthStart.add(Duration(days: days - 1)),
      daysBack: days,
    );
    return MonthStepsAggregation(
      monthStart: monthStart,
      dailyTotals: range.dailyTotals,
      totalSteps: range.totalSteps,
    );
  }

  @override
  Future<RangeStepsAggregation> getRangeAggregation({
    required DateTime endDate,
    required int daysBack,
  }) async {
    final safeDays = daysBack < 1 ? 1 : daysBack;
    final normalizedEnd = _atStartOfDay(endDate);
    final normalizedStart = normalizedEnd.subtract(
      Duration(days: safeDays - 1),
    );
    final provider = await _providerFilterRaw();
    final sourcePolicy = await _sourcePolicyRaw();
    final rows = await dbHelper.getDailyStepsTotalsForRange(
      startLocal: normalizedStart,
      endLocal: normalizedEnd,
      providerFilter: provider,
      sourcePolicy: sourcePolicy,
    );
    final byDay = <String, int>{
      for (final row in rows)
        row['dayLocal'] as String: row['totalSteps'] as int,
    };
    final buckets = List.generate(safeDays, (index) {
      final day = normalizedStart.add(Duration(days: index));
      final dayKey = _dayKey(day);
      return StepsBucket(start: day, steps: byDay[dayKey] ?? 0);
    });
    final total = buckets.fold<int>(0, (sum, bucket) => sum + bucket.steps);
    return RangeStepsAggregation(
      start: normalizedStart,
      end: normalizedEnd,
      dailyTotals: buckets,
      totalSteps: total,
      averageDailySteps: buckets.isEmpty ? 0 : total / buckets.length,
    );
  }

  @override
  Future<StepsRefreshResult> refresh({
    bool force = false,
    DateTime? now,
  }) async {
    final enabled = await stepsSyncService.isTrackingEnabled();
    if (!enabled) {
      return const StepsRefreshResult(
        didRun: false,
        permissionGranted: false,
        skipped: true,
        fetchedCount: 0,
        upsertedCount: 0,
      );
    }
    final availability = await stepsSyncService.getAvailability();
    if (availability == StepsAvailability.notAvailable) {
      return const StepsRefreshResult(
        didRun: false,
        permissionGranted: false,
        skipped: true,
        fetchedCount: 0,
        upsertedCount: 0,
      );
    }

    final hasPermission = await stepsSyncService.requestPermissions();
    if (!hasPermission) {
      return const StepsRefreshResult(
        didRun: true,
        permissionGranted: false,
        skipped: true,
        fetchedCount: 0,
        upsertedCount: 0,
      );
    }

    final syncResult = await stepsSyncService.sync(
      now: now,
      forceRefresh: force,
    );
    final updatedAt = await stepsSyncService.getLastSyncAt();
    return StepsRefreshResult(
      didRun: true,
      permissionGranted: true,
      skipped: syncResult.skipped,
      fetchedCount: syncResult.fetchedCount,
      upsertedCount: syncResult.upsertedCount,
      lastUpdatedAtUtc: updatedAt,
    );
  }

  @override
  Future<DateTime?> getEarliestAvailableDate() async {
    final provider = await _providerFilterRaw();
    return dbHelper.getEarliestHealthStepsDateLocal(providerFilter: provider);
  }

  @override
  Future<DateTime?> getLastUpdatedAt() => stepsSyncService.getLastSyncAt();

  @override
  Future<bool> isTrackingEnabled() => stepsSyncService.isTrackingEnabled();

  DateTime _atStartOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _startOfWeek(DateTime date) {
    final day = _atStartOfDay(date);
    final offset = day.weekday - DateTime.monday;
    return day.subtract(Duration(days: offset));
  }

  Future<String> _providerFilterRaw() async {
    final filter = await stepsSyncService.getProviderFilter();
    return StepsSyncService.providerFilterToRaw(filter);
  }

  Future<String> _sourcePolicyRaw() async {
    final policy = await stepsSyncService.getSourcePolicy();
    return StepsSyncService.sourcePolicyToRaw(policy);
  }

  String _dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
