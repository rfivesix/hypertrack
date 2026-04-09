import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/generated/app_localizations.dart';
import 'package:hypertrack/features/sleep/data/sleep_day_repository.dart';
import 'package:hypertrack/features/sleep/data/repository/sleep_query_repository.dart';
import 'package:hypertrack/features/sleep/domain/sleep_domain.dart';
import 'package:hypertrack/features/sleep/presentation/day/sleep_day_overview_page.dart';
import 'package:hypertrack/features/sleep/presentation/day/sleep_day_view_model.dart';
import 'package:hypertrack/features/sleep/presentation/month/sleep_month_overview_page.dart';
import 'package:hypertrack/features/sleep/presentation/sleep_navigation.dart';
import 'package:hypertrack/features/sleep/presentation/week/sleep_week_overview_page.dart';
import 'package:hypertrack/features/sleep/platform/permissions/sleep_permission_models.dart';
import 'package:hypertrack/features/sleep/platform/sleep_sync_service.dart';
import 'package:hypertrack/widgets/measurement_chart_widget.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSleepDayRepository implements SleepDayDataRepository {
  _FakeSleepDayRepository(this.data);

  final SleepDayOverviewData? data;
  int fetchCount = 0;

  @override
  Future<SleepDayOverviewData?> fetchOverview(DateTime day) async {
    fetchCount += 1;
    return data;
  }

  @override
  Future<void> dispose() async {}
}

class _FakeSleepImportService implements SleepImportService {
  _FakeSleepImportService(this.result);

  final SleepSyncResult result;
  int calls = 0;

  @override
  Future<SleepSyncResult> importRecent({int lookbackDays = 30}) async {
    calls += 1;
    return result;
  }

  @override
  Future<SleepSyncResult?> importRecentIfDue({
    int lookbackDays = 30,
    Duration minInterval = const Duration(hours: 6),
    bool force = false,
  }) async {
    return null;
  }

  @override
  Future<void> dispose() async {}
}

class _FakeSleepQueryRepository implements SleepQueryRepository {
  _FakeSleepQueryRepository(this.items);

  final List<NightlySleepAnalysis> items;

  @override
  Future<List<NightlySleepAnalysis>> getAnalysesInRange({
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) async {
    return items
        .where(
          (item) =>
              !item.nightDate.isBefore(fromInclusive) &&
              !item.nightDate.isAfter(toInclusive),
        )
        .toList(growable: false);
  }

  @override
  Future<NightlySleepAnalysis?> getNightlyAnalysisByDate(DateTime day) async {
    for (final item in items) {
      if (item.nightDate.year == day.year &&
          item.nightDate.month == day.month &&
          item.nightDate.day == day.day) {
        return item;
      }
    }
    return null;
  }
}

String _dayLabel(DateTime day, {String localeCode = 'en'}) {
  return DateFormat.yMMMd(localeCode).format(day);
}

String _weekLabel(DateTime day, {String localeCode = 'en'}) {
  final normalized = DateTime(day.year, day.month, day.day);
  final start = normalized.subtract(
    Duration(days: normalized.weekday - DateTime.monday),
  );
  final end = start.add(const Duration(days: 6));
  return '${DateFormat.MMMd(localeCode).format(start)} - ${DateFormat.MMMd(localeCode).format(end)}';
}

String _monthLabel(DateTime day, {String localeCode = 'en'}) {
  return DateFormat.yMMMM(localeCode).format(DateTime(day.year, day.month, 1));
}

Future<void> _pumpRouteTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _tapMetricTile(WidgetTester tester, String title) async {
  final titleFinder = find.text(title);
  await tester.scrollUntilVisible(
    titleFinder,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(titleFinder);
  await tester.tap(titleFinder);
  await _pumpRouteTransition(tester);
}

Widget _testApp({
  RouteFactory? onGenerateRoute,
  Widget? home,
  String? initialRoute,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    onGenerateRoute: onGenerateRoute,
    home: home,
    initialRoute: initialRoute,
  );
}

SleepDayOverviewData _sampleOverview() {
  final session = SleepSession(
    id: 'session-1',
    startAtUtc: DateTime.utc(2026, 3, 30, 22, 0),
    endAtUtc: DateTime.utc(2026, 3, 31, 6, 0),
    sessionType: SleepSessionType.mainSleep,
    sourcePlatform: 'healthkit',
  );
  return SleepDayOverviewData(
    analysis: NightlySleepAnalysis(
      id: 'analysis-1',
      sessionId: session.id,
      nightDate: DateTime.utc(2026, 3, 31),
      analysisVersion: 'a1',
      normalizationVersion: 'n1',
      analyzedAtUtc: DateTime.utc(2026, 3, 31, 7, 0),
      score: 82,
      sleepQuality: SleepQualityBucket.good,
    ),
    session: session,
    timelineSegments: [
      SleepStageSegment(
        id: 'seg-1',
        sessionId: session.id,
        stage: CanonicalSleepStage.light,
        startAtUtc: DateTime.utc(2026, 3, 30, 22, 0),
        endAtUtc: DateTime.utc(2026, 3, 30, 23, 0),
        sourcePlatform: 'healthkit',
      ),
      SleepStageSegment(
        id: 'seg-2',
        sessionId: session.id,
        stage: CanonicalSleepStage.deep,
        startAtUtc: DateTime.utc(2026, 3, 30, 23, 0),
        endAtUtc: DateTime.utc(2026, 3, 31, 0, 0),
        sourcePlatform: 'healthkit',
      ),
    ],
    totalSleepMinutes: 420,
    sleepHrAvg: 53,
    baselineSleepHr: 55,
    deltaSleepHr: -2,
    interruptionsCount: 1,
    interruptionsWakeDuration: const Duration(minutes: 10),
    deepDuration: const Duration(minutes: 90),
    lightDuration: const Duration(minutes: 210),
    remDuration: const Duration(minutes: 120),
    regularityNights: [
      SleepRegularityNight(
        nightDate: DateTime.utc(2026, 3, 25),
        bedtimeMinutes: 22 * 60 + 45,
        wakeMinutes: 6 * 60 + 30,
      ),
    ],
    heartRateSamples: [
      HeartRateSample(
        id: 'hr-1',
        sessionId: session.id,
        sampledAtUtc: DateTime.utc(2026, 3, 30, 22, 30),
        bpm: 56,
        sourcePlatform: 'healthkit',
      ),
      HeartRateSample(
        id: 'hr-2',
        sessionId: session.id,
        sampledAtUtc: DateTime.utc(2026, 3, 30, 23, 45),
        bpm: 53,
        sourcePlatform: 'healthkit',
      ),
      HeartRateSample(
        id: 'hr-3',
        sessionId: session.id,
        sampledAtUtc: DateTime.utc(2026, 3, 31, 1, 15),
        bpm: 52,
        sourcePlatform: 'healthkit',
      ),
      HeartRateSample(
        id: 'hr-4',
        sessionId: session.id,
        sampledAtUtc: DateTime.utc(2026, 3, 31, 3, 0),
        bpm: 54,
        sourcePlatform: 'healthkit',
      ),
    ],
    stageDataConfidence: SleepStageConfidence.high,
  );
}

SleepDayOverviewData _baselineMissingOverview() {
  final base = _sampleOverview();
  return SleepDayOverviewData(
    analysis: base.analysis,
    session: base.session,
    timelineSegments: base.timelineSegments,
    stageDataConfidence: base.stageDataConfidence,
    totalSleepMinutes: base.totalSleepMinutes,
    sleepHrAvg: base.sleepHrAvg,
    baselineSleepHr: null,
    deltaSleepHr: null,
    interruptionsCount: base.interruptionsCount,
    interruptionsWakeDuration: base.interruptionsWakeDuration,
    deepDuration: base.deepDuration,
    lightDuration: base.lightDuration,
    remDuration: base.remDuration,
    regularityNights: base.regularityNights,
    heartRateSamples: base.heartRateSamples,
  );
}

SleepDayOverviewData _lowConfidenceDepthOverview() {
  final base = _sampleOverview();
  return SleepDayOverviewData(
    analysis: base.analysis,
    session: base.session,
    timelineSegments: base.timelineSegments,
    stageDataConfidence: SleepStageConfidence.low,
    totalSleepMinutes: base.totalSleepMinutes,
    sleepHrAvg: base.sleepHrAvg,
    baselineSleepHr: base.baselineSleepHr,
    deltaSleepHr: base.deltaSleepHr,
    interruptionsCount: base.interruptionsCount,
    interruptionsWakeDuration: base.interruptionsWakeDuration,
    deepDuration: base.deepDuration,
    lightDuration: base.lightDuration,
    remDuration: base.remDuration,
    regularityNights: base.regularityNights,
  );
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'HyperTrack',
      packageName: 'com.rfivesix.hypertrack',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Intl.defaultLocale = 'en';
  });

  testWidgets('navigates from day tiles to detail routes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final overview = _sampleOverview();
    final model = SleepDayViewModel(
      repository: _FakeSleepDayRepository(overview),
    );

    await tester.pumpWidget(
      _testApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepDayOverviewPage(viewModel: model),
      ),
    );
    await tester.pumpAndSettle();

    await _tapMetricTile(tester, 'Duration');
    expect(find.text('Duration'), findsWidgets);
    expect(
      find.text(
        'Adults often do best with roughly 7–9 hours. This benchmark helps you see where your night sits in that range.',
      ),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    await _tapMetricTile(tester, 'Heart rate');
    expect(find.text('Heart rate'), findsWidgets);
    expect(find.byType(MeasurementChartWidget), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tapMetricTile(tester, 'Regularity');
    expect(find.text('Average bedtime'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tapMetricTile(tester, 'Depth');
    expect(find.text('Depth'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tapMetricTile(tester, 'Interruptions');
    expect(find.text('Interruptions'), findsWidgets);
  });

  testWidgets('sleep state placeholder routes render without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        initialRoute: SleepRouteNames.connectHealthData,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Connect health data'), findsOneWidget);
  });

  testWidgets('week and month screens render sparse data safely', (
    tester,
  ) async {
    final repo = _FakeSleepQueryRepository([
      NightlySleepAnalysis(
        id: 'a1',
        sessionId: 's1',
        nightDate: DateTime(2026, 3, 31),
        analysisVersion: 'v1',
        normalizationVersion: 'n1',
        analyzedAtUtc: DateTime.utc(2026, 3, 31, 8),
        score: 78,
        totalSleepMinutes: 430,
        sleepQuality: SleepQualityBucket.average,
      ),
    ]);
    await tester.pumpWidget(
      _testApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepWeekOverviewPage(
          anchorDay: DateTime(2026, 3, 31),
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Week summary'), findsOneWidget);
    expect(find.text('Daily score'), findsOneWidget);

    await tester.pumpWidget(
      _testApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepMonthOverviewPage(
          anchorDay: DateTime(2026, 3, 31),
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Month summary'), findsOneWidget);
    expect(find.text('Daily score states'), findsOneWidget);
  });

  testWidgets('week window axis adapts to earliest sleep and latest wake', (
    tester,
  ) async {
    final startUtc = DateTime.utc(2026, 3, 30, 20, 0);
    final endUtc = DateTime.utc(2026, 3, 31, 12, 0);
    final startLocal = startUtc.toLocal();
    final endLocal = endUtc.toLocal();
    final startFloor = (startLocal.hour * 60 + startLocal.minute) ~/ 60 * 60;
    final startBoundary =
        (startLocal.minute == 0 ? startFloor - 60 : startFloor);
    final endCeil = ((endLocal.hour * 60 + endLocal.minute + 59) ~/ 60) * 60;
    final endBoundary = (endLocal.minute == 0 ? endCeil + 60 : endCeil);
    String formatHourLabel(int minute) {
      var hours = (minute ~/ 60) % 24;
      if (hours < 0) hours += 24;
      return '$hours:00';
    }

    final repo = _FakeSleepQueryRepository([
      NightlySleepAnalysis(
        id: 'w1',
        sessionId: 's1',
        nightDate: DateTime(2026, 3, 31),
        analysisVersion: 'v1',
        normalizationVersion: 'n1',
        analyzedAtUtc: DateTime.utc(2026, 3, 31, 8),
        score: 80,
        totalSleepMinutes: 420,
        sessionStartAtUtc: startUtc,
        sessionEndAtUtc: endUtc,
        sleepQuality: SleepQualityBucket.good,
      ),
    ]);

    await tester.pumpWidget(
      _testApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepWeekOverviewPage(
          anchorDay: DateTime(2026, 3, 31),
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(formatHourLabel(startBoundary)), findsOneWidget);
    expect(find.text(formatHourLabel(endBoundary)), findsOneWidget);
  });

  testWidgets('day scope switch opens week and month screens', (tester) async {
    final overview = _sampleOverview();
    final model = SleepDayViewModel(
      repository: _FakeSleepDayRepository(overview),
      selectedDay: DateTime(2026, 3, 31),
    );
    final repo = _FakeSleepQueryRepository(const <NightlySleepAnalysis>[]);

    await tester.pumpWidget(
      Provider<SleepQueryRepository>.value(
        value: repo,
        child: _testApp(
          onGenerateRoute: SleepNavigation.onGenerateRoute,
          home: SleepDayOverviewPage(viewModel: model),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.text('Week summary'), findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('Month summary'), findsOneWidget);
  });

  testWidgets('renders empty state without crash', (tester) async {
    final model = SleepDayViewModel(
      repository: _FakeSleepDayRepository(null),
      syncService: _FakeSleepImportService(
        const SleepSyncResult(
          success: false,
          permissionState: SleepPermissionState.denied,
          importedSessions: 0,
        ),
      ),
    );
    await tester.pumpWidget(
      _testApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepDayOverviewPage(viewModel: model),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No sleep data available for this day.'), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
    expect(find.text('Import now'), findsOneWidget);
  });

  testWidgets('heart-rate detail shows neutral baseline-missing state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final model = SleepDayViewModel(
      repository: _FakeSleepDayRepository(_baselineMissingOverview()),
    );
    await tester.pumpWidget(
      _testApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepDayOverviewPage(viewModel: model),
      ),
    );
    await tester.pumpAndSettle();

    await _tapMetricTile(tester, 'Heart rate');
    expect(find.text('Baseline not established'), findsOneWidget);
    expect(find.byType(MeasurementChartWidget), findsOneWidget);
  });

  testWidgets('heart-rate detail shows fallback when samples are missing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final base = _sampleOverview();
    final noSamples = SleepDayOverviewData(
      analysis: base.analysis,
      session: base.session,
      timelineSegments: base.timelineSegments,
      stageDataConfidence: base.stageDataConfidence,
      totalSleepMinutes: base.totalSleepMinutes,
      sleepHrAvg: base.sleepHrAvg,
      baselineSleepHr: base.baselineSleepHr,
      deltaSleepHr: base.deltaSleepHr,
      interruptionsCount: base.interruptionsCount,
      interruptionsWakeDuration: base.interruptionsWakeDuration,
      deepDuration: base.deepDuration,
      lightDuration: base.lightDuration,
      remDuration: base.remDuration,
      regularityNights: base.regularityNights,
      heartRateSamples: const [],
    );
    final model = SleepDayViewModel(
      repository: _FakeSleepDayRepository(noSamples),
    );

    await tester.pumpWidget(
      _testApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepDayOverviewPage(viewModel: model),
      ),
    );
    await tester.pumpAndSettle();

    await _tapMetricTile(tester, 'Heart rate');
    expect(
      find.text(
        'No heart-rate samples were stored for this night. Trend chart is unavailable.',
      ),
      findsOneWidget,
    );
    expect(find.byType(MeasurementChartWidget), findsNothing);
  });

  testWidgets('depth detail shows low-confidence fallback', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final model = SleepDayViewModel(
      repository: _FakeSleepDayRepository(_lowConfidenceDepthOverview()),
    );
    await tester.pumpWidget(
      _testApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepDayOverviewPage(viewModel: model),
      ),
    );
    await tester.pumpAndSettle();

    await _tapMetricTile(tester, 'Depth');
    expect(
      find.text('Stage confidence is too low for a reliable depth breakdown.'),
      findsOneWidget,
    );
  });

  testWidgets('period navigation shifts day and reloads', (tester) async {
    final repository = _FakeSleepDayRepository(_sampleOverview());
    final model = SleepDayViewModel(
      repository: repository,
      selectedDay: DateTime(2026, 3, 31),
    );

    await tester.pumpWidget(
      _testApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepDayOverviewPage(viewModel: model),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_dayLabel(DateTime(2026, 3, 31))), findsOneWidget);
    final initialFetches = repository.fetchCount;

    await tester.tap(find.byKey(const Key('sleep-period-prev')));
    await tester.pumpAndSettle();
    expect(find.text(_dayLabel(DateTime(2026, 3, 30))), findsOneWidget);
    expect(repository.fetchCount, initialFetches + 1);
  });

  testWidgets('period navigation shifts week labels', (tester) async {
    final repository = _FakeSleepDayRepository(_sampleOverview());
    final model = SleepDayViewModel(
      repository: repository,
      selectedDay: DateTime(2026, 3, 31),
    );
    final queryRepo = _FakeSleepQueryRepository([
      NightlySleepAnalysis(
        id: 'week-1',
        sessionId: 's1',
        nightDate: DateTime(2026, 3, 31),
        analysisVersion: 'v1',
        normalizationVersion: 'n1',
        analyzedAtUtc: DateTime.utc(2026, 3, 31, 8),
        score: 78,
        totalSleepMinutes: 430,
        sleepQuality: SleepQualityBucket.average,
      ),
    ]);

    await tester.pumpWidget(
      Provider<SleepQueryRepository>.value(
        value: queryRepo,
        child: _testApp(
          onGenerateRoute: SleepNavigation.onGenerateRoute,
          home: SleepDayOverviewPage(viewModel: model),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Week'));
    await _pumpRouteTransition(tester);

    expect(find.text(_weekLabel(DateTime(2026, 3, 31))), findsOneWidget);

    await tester.tap(find.byKey(const Key('sleep-period-prev')));
    await _pumpRouteTransition(tester);
    expect(find.text(_weekLabel(DateTime(2026, 3, 24))), findsOneWidget);
  });

  testWidgets('period navigation shifts month labels', (tester) async {
    final repository = _FakeSleepDayRepository(_sampleOverview());
    final model = SleepDayViewModel(
      repository: repository,
      selectedDay: DateTime(2026, 3, 31),
    );
    final queryRepo = _FakeSleepQueryRepository([
      NightlySleepAnalysis(
        id: 'month-1',
        sessionId: 's1',
        nightDate: DateTime(2026, 3, 31),
        analysisVersion: 'v1',
        normalizationVersion: 'n1',
        analyzedAtUtc: DateTime.utc(2026, 3, 31, 8),
        score: 78,
        totalSleepMinutes: 430,
        sleepQuality: SleepQualityBucket.average,
      ),
    ]);

    await tester.pumpWidget(
      Provider<SleepQueryRepository>.value(
        value: queryRepo,
        child: _testApp(
          onGenerateRoute: SleepNavigation.onGenerateRoute,
          home: SleepDayOverviewPage(viewModel: model),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Month'));
    await _pumpRouteTransition(tester);

    expect(find.text(_monthLabel(DateTime(2026, 3, 31))), findsOneWidget);

    await tester.tap(find.byKey(const Key('sleep-period-prev')));
    await _pumpRouteTransition(tester);
    expect(find.text(_monthLabel(DateTime(2026, 2, 28))), findsOneWidget);
  });

  testWidgets('import now action triggers import orchestration', (
    tester,
  ) async {
    final import = _FakeSleepImportService(
      const SleepSyncResult(
        success: true,
        permissionState: SleepPermissionState.ready,
        importedSessions: 1,
      ),
    );
    final model = SleepDayViewModel(
      repository: _FakeSleepDayRepository(null),
      syncService: import,
    );
    await tester.pumpWidget(
      _testApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepDayOverviewPage(viewModel: model),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import now'));
    await tester.pumpAndSettle();
    expect(import.calls, 1);
  });

  testWidgets('successful import refreshes day view model data', (
    tester,
  ) async {
    final repo = _FakeSleepDayRepository(_sampleOverview());
    final import = _FakeSleepImportService(
      const SleepSyncResult(
        success: true,
        permissionState: SleepPermissionState.ready,
        importedSessions: 1,
      ),
    );
    final model = SleepDayViewModel(repository: repo, syncService: import);
    await tester.pumpWidget(
      _testApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepDayOverviewPage(viewModel: model),
      ),
    );
    await tester.pumpAndSettle();
    final initialFetches = repo.fetchCount;

    await model.importNow();
    await tester.pumpAndSettle();
    expect(repo.fetchCount, greaterThan(initialFetches));
  });

  testWidgets('day timeline axis renders readable timestamp ticks', (
    tester,
  ) async {
    final model = SleepDayViewModel(
      repository: _FakeSleepDayRepository(_sampleOverview()),
      selectedDay: DateTime(2026, 3, 31),
    );
    await tester.pumpWidget(
      _testApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepDayOverviewPage(viewModel: model),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sleep-timeline-axis')), findsOneWidget);
    final tickFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
                'sleep-timeline-tick-',
              ),
    );
    expect(tickFinder, findsAtLeastNWidgets(3));
  });

  testWidgets('day timeline axis tick color adapts for light and dark mode', (
    tester,
  ) async {
    final model = SleepDayViewModel(
      repository: _FakeSleepDayRepository(_sampleOverview()),
      selectedDay: DateTime(2026, 3, 31),
    );
    Future<void> pumpWithMode(ThemeMode mode) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: mode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SleepDayOverviewPage(viewModel: model),
        ),
      );
      await tester.pumpAndSettle();
    }

    final tickFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
                'sleep-timeline-tick-',
              ),
    );

    await pumpWithMode(ThemeMode.light);
    final lightTheme = ThemeData.light();
    final lightTick = tester.widget<Text>(tickFinder.first);
    expect(lightTick.style?.color, lightTheme.colorScheme.onSurfaceVariant);

    await pumpWithMode(ThemeMode.dark);
    final darkTheme = ThemeData.dark();
    final darkTick = tester.widget<Text>(tickFinder.first);
    expect(darkTick.style?.color, darkTheme.colorScheme.onSurfaceVariant);
  });

  testWidgets('sleep day list top padding includes app bar height', (
    tester,
  ) async {
    final model = SleepDayViewModel(repository: _FakeSleepDayRepository(null));
    await tester.pumpWidget(
      _testApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepDayOverviewPage(viewModel: model),
      ),
    );
    await tester.pumpAndSettle();

    final listView = tester.widget<ListView>(find.byType(ListView).first);
    final padding = listView.padding as EdgeInsets;
    expect(padding.top, greaterThanOrEqualTo(kToolbarHeight));
  });
}
