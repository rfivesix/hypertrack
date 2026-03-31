import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/steps/data/steps_aggregation_repository.dart';
import 'package:hypertrack/features/steps/domain/steps_models.dart';

class _FakeStepsRepository implements StepsAggregationRepository {
  int refreshCalls = 0;
  bool lastForce = false;

  @override
  Future<StepsRefreshResult> refresh({
    bool force = false,
    DateTime? now,
  }) async {
    refreshCalls += 1;
    lastForce = force;
    return const StepsRefreshResult(
      didRun: true,
      permissionGranted: true,
      skipped: false,
      fetchedCount: 1,
      upsertedCount: 1,
    );
  }

  @override
  Future<DayStepsAggregation> getDayAggregation(DateTime date) async =>
      throw UnimplementedError();

  @override
  Future<WeekStepsAggregation> getWeekAggregation(DateTime dateInWeek) async =>
      throw UnimplementedError();

  @override
  Future<MonthStepsAggregation> getMonthAggregation(
    DateTime dateInMonth,
  ) async => throw UnimplementedError();

  @override
  Future<RangeStepsAggregation> getRangeAggregation({
    required DateTime endDate,
    required int daysBack,
  }) async => throw UnimplementedError();

  @override
  Future<DateTime?> getEarliestAvailableDate() async => null;

  @override
  Future<DateTime?> getLastUpdatedAt() async => null;

  @override
  Future<bool> isTrackingEnabled() async => true;
}

void main() {
  test('refresh API is force-capable for pull-to-refresh path', () async {
    final repo = _FakeStepsRepository();
    await repo.refresh(force: true);

    expect(repo.refreshCalls, 1);
    expect(repo.lastForce, isTrue);
  });
}
