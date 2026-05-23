import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/sleep/data/sleep_day_repository.dart';
import 'package:train_libre/features/sleep/domain/sleep_domain.dart';
import 'package:train_libre/features/sleep/presentation/day/sleep_day_view_model.dart';
import 'package:train_libre/features/sleep/platform/permissions/sleep_permission_models.dart';
import 'package:train_libre/features/sleep/platform/sleep_sync_service.dart';

class FakeSleepDayDataRepository implements SleepDayDataRepository {
  final StreamController<SleepDayOverviewData?> controller =
      StreamController<SleepDayOverviewData?>.broadcast();

  int fetchCount = 0;
  int watchCount = 0;
  int disposeCount = 0;
  SleepDayOverviewData? mockOverviewData;
  bool throwError = false;

  @override
  Future<SleepDayOverviewData?> fetchOverview(DateTime day) async {
    fetchCount += 1;
    if (throwError) throw Exception('Database error');
    return mockOverviewData;
  }

  @override
  Stream<SleepDayOverviewData?> watchOverview(DateTime day) {
    watchCount += 1;
    if (throwError) {
      return Stream.error(Exception('Database stream error'));
    }
    return controller.stream;
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
    await controller.close();
  }
}

class FakeSleepImportService implements SleepImportService {
  int importRecentCalls = 0;
  int importRecentIfDueCalls = 0;
  int disposeCalls = 0;

  SleepSyncResult mockSyncResult = const SleepSyncResult(
    success: true,
    permissionState: SleepPermissionState.ready,
    importedSessions: 2,
  );

  @override
  Future<SleepSyncResult> importRecent({int lookbackDays = 30}) async {
    importRecentCalls += 1;
    return mockSyncResult;
  }

  @override
  Future<SleepSyncResult?> importRecentIfDue({
    int lookbackDays = 30,
    Duration minInterval = const Duration(hours: 6),
    bool force = false,
  }) async {
    importRecentIfDueCalls += 1;
    return mockSyncResult;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}

void main() {
  group('SleepDayViewModel Unit Tests', () {
    late FakeSleepDayDataRepository mockRepository;
    late FakeSleepImportService mockSyncService;
    late DateTime testDate;

    setUp(() {
      mockRepository = FakeSleepDayDataRepository();
      mockSyncService = FakeSleepImportService();
      // Using a mid-summer local date to avoid any Daylight Saving Time (DST) transition boundaries in March/October.
      testDate = DateTime(2026, 6, 15);
    });

    SleepDayOverviewData createSampleOverview() {
      final session = SleepSession(
        id: 'session-1',
        startAtUtc: DateTime.utc(2026, 6, 14, 22, 0),
        endAtUtc: DateTime.utc(2026, 6, 15, 6, 0),
        sessionType: SleepSessionType.mainSleep,
        sourcePlatform: 'healthkit',
      );
      return SleepDayOverviewData(
        analysis: NightlySleepAnalysis(
          id: 'analysis-1',
          sessionId: session.id,
          nightDate: testDate,
          analysisVersion: 'v1',
          normalizationVersion: 'n1',
          analyzedAtUtc: DateTime.utc(2026, 6, 15, 7, 0),
          score: 85,
          sleepQuality: SleepQualityBucket.good,
        ),
        session: session,
        timelineSegments: const [],
        stageDataConfidence: SleepStageConfidence.high,
        totalSleepMinutes: 480,
        sleepHrAvg: 55,
      );
    }

    test('initializes state correctly', () {
      final vm = SleepDayViewModel(
        repository: mockRepository,
        syncService: mockSyncService,
        selectedDay: testDate,
      );

      expect(vm.selectedDay, testDate);
      expect(vm.isLoading, isTrue);
      expect(vm.overview, isNull);
      expect(vm.errorMessage, isNull);
      expect(vm.isDayScope, isTrue);
      expect(vm.selectedScopeIndex, SleepPeriodScope.day.index);
    });

    test('load sets isLoading, watches repository overview, handles data stream emission, and triggers background sync', () async {
      final vm = SleepDayViewModel(
        repository: mockRepository,
        syncService: mockSyncService,
        selectedDay: testDate,
      );

      int notifyCount = 0;
      vm.addListener(() {
        notifyCount += 1;
      });

      final overview = createSampleOverview();

      // Trigger load (async)
      final loadFuture = vm.load();

      // Check loading state immediately set and listeners notified
      expect(vm.isLoading, isTrue);
      expect(notifyCount, 1);

      // Emit overview data through fake repository stream
      mockRepository.controller.add(overview);

      await loadFuture;
      // Yield to let stream listener process the event
      await Future<void>.delayed(Duration.zero);

      expect(vm.isLoading, isFalse);
      expect(vm.overview, overview);
      expect(vm.errorMessage, isNull);
      expect(mockRepository.watchCount, 1);
      expect(mockSyncService.importRecentIfDueCalls, 1);
      expect(notifyCount, greaterThan(1));
    });

    test('load propagates stream error gracefully to errorMessage', () async {
      final vm = SleepDayViewModel(
        repository: mockRepository,
        syncService: mockSyncService,
        selectedDay: testDate,
      );

      mockRepository.throwError = true;

      await vm.load();
      await Future<void>.delayed(Duration.zero);

      expect(vm.isLoading, isFalse);
      expect(vm.overview, isNull);
      expect(vm.errorMessage, 'Unable to load sleep day.');
    });

    test('setSelectedDay updates selectedDay and re-triggers load', () async {
      final vm = SleepDayViewModel(
        repository: mockRepository,
        syncService: mockSyncService,
        selectedDay: testDate,
      );

      final nextDay = testDate.add(const Duration(days: 1));
      await vm.setSelectedDay(nextDay);

      expect(vm.selectedDay, nextDay);
      // Since construction doesn't trigger load, calling setSelectedDay triggers the watchOverview stream exactly once.
      expect(mockRepository.watchCount, 1);
    });

    test('setScopeIndex transitions scope indices and handles non-day scopes cleanly', () async {
      final vm = SleepDayViewModel(
        repository: mockRepository,
        syncService: mockSyncService,
        selectedDay: testDate,
      );

      await vm.load();
      expect(mockRepository.watchCount, 1);

      // Transition to week scope
      vm.setScopeIndex(SleepPeriodScope.week.index);

      expect(vm.isDayScope, isFalse);
      expect(vm.selectedScopeIndex, SleepPeriodScope.week.index);
      // Under non-day scope, subscription is cancelled and overview set to null
      expect(vm.overview, isNull);
      expect(vm.isLoading, isFalse);
    });

    test('shiftPeriod correctly shifts day, week, and month scopes', () {
      final vm = SleepDayViewModel(
        repository: mockRepository,
        syncService: mockSyncService,
        selectedDay: testDate,
      );

      // Day Shift
      vm.shiftPeriod(1);
      expect(vm.selectedDay, DateTime(2026, 6, 16));

      vm.shiftPeriod(-2);
      expect(vm.selectedDay, DateTime(2026, 6, 14));

      // Week Shift
      vm.setScopeIndex(SleepPeriodScope.week.index);
      vm.shiftPeriod(1);
      expect(vm.selectedDay, DateTime(2026, 6, 21)); // Shifts by 7 days

      vm.shiftPeriod(-2);
      expect(vm.selectedDay, DateTime(2026, 6, 7)); // Shifts by -14 days

      // Month Shift
      vm.setScopeIndex(SleepPeriodScope.month.index);
      vm.shiftPeriod(1);
      expect(vm.selectedDay, DateTime(2026, 7, 7)); // Shifts by 1 month

      vm.shiftPeriod(-2);
      expect(vm.selectedDay, DateTime(2026, 5, 7)); // Shifts by -2 months
    });

    test('importNow triggers sync, loads on success, and handles failure cleanly', () async {
      final vm = SleepDayViewModel(
        repository: mockRepository,
        syncService: mockSyncService,
        selectedDay: testDate,
      );

      // Test Success Path
      final success = await vm.importNow();
      expect(success, isTrue);
      expect(mockSyncService.importRecentCalls, 1);
      // importNow reloads by calling load() which watches the stream exactly once.
      expect(mockRepository.watchCount, 1);

      // Test Failure Path
      mockSyncService.mockSyncResult = const SleepSyncResult(
        success: false,
        permissionState: SleepPermissionState.denied,
        importedSessions: 0,
      );

      final failed = await vm.importNow();
      expect(failed, isFalse);
      expect(mockSyncService.importRecentCalls, 2);
      expect(vm.isLoading, isFalse);
    });

    test('dispose cancels active stream subscription and disposes repositories & services', () async {
      final vm = SleepDayViewModel(
        repository: mockRepository,
        syncService: mockSyncService,
        selectedDay: testDate,
      );

      await vm.load();
      vm.dispose();

      expect(mockRepository.disposeCount, 1);
      expect(mockSyncService.disposeCalls, 1);
    });
  });
}
