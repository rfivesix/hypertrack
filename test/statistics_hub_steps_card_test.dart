import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/data/workout_database_helper.dart';
import 'package:train_libre/features/statistics/data/statistics_hub_data_adapter.dart';
import 'package:train_libre/features/statistics/domain/body_nutrition_analytics_models.dart';
import 'package:train_libre/features/statistics/domain/consistency_payload_models.dart';
import 'package:train_libre/features/statistics/domain/hub_payload_models.dart';
import 'package:train_libre/features/statistics/domain/recovery_domain_service.dart';
import 'package:train_libre/features/statistics/domain/recovery_payload_models.dart';
import 'package:train_libre/features/statistics/domain/statistics_data_quality_policy.dart';
import 'package:train_libre/features/statistics/domain/statistics_range_policy.dart';
import 'package:train_libre/features/pulse/data/pulse_repository.dart';
import 'package:train_libre/features/pulse/application/pulse_tracking_service.dart';
import 'package:train_libre/features/pulse/domain/pulse_models.dart';
import 'package:train_libre/features/steps/data/steps_aggregation_repository.dart';
import 'package:train_libre/features/steps/domain/steps_models.dart';
import 'package:train_libre/features/sleep/presentation/day/sleep_day_overview_page.dart';
import 'package:train_libre/features/sleep/platform/sleep_sync_service.dart';
import 'package:train_libre/features/sleep/presentation/sleep_navigation.dart';
import 'package:train_libre/features/sleep/data/sleep_hub_summary_repository.dart';
import 'package:train_libre/screens/measurements_screen.dart';
import 'package:train_libre/screens/statistics_hub_screen.dart';
import 'package:train_libre/services/health/steps_sync_service.dart';
import 'package:train_libre/services/theme_service.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/services/workout_session_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStepsRepository implements StepsAggregationRepository {
  _FakeStepsRepository({this.trackingEnabled = true});

  final bool trackingEnabled;

  @override
  Future<RangeStepsAggregation> getRangeAggregation({
    required DateTime endDate,
    required int daysBack,
  }) async {
    final start = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).subtract(Duration(days: daysBack - 1));
    final buckets = List.generate(
      daysBack,
      (index) => StepsBucket(
        start: start.add(Duration(days: index)),
        steps: 1000 + index * 100,
      ),
    );
    final total = buckets.fold<int>(0, (sum, b) => sum + b.steps);
    return RangeStepsAggregation(
      start: start,
      end: DateTime(endDate.year, endDate.month, endDate.day),
      dailyTotals: buckets,
      totalSteps: total,
      averageDailySteps: total / buckets.length,
    );
  }

  @override
  Future<DayStepsAggregation> getDayAggregation(DateTime date) async =>
      throw UnimplementedError();

  @override
  Future<MonthStepsAggregation> getMonthAggregation(
    DateTime dateInMonth,
  ) async =>
      throw UnimplementedError();

  @override
  Future<WeekStepsAggregation> getWeekAggregation(DateTime dateInWeek) async =>
      throw UnimplementedError();

  @override
  Future<DateTime?> getEarliestAvailableDate() async =>
      DateTime.now().subtract(const Duration(days: 40));

  @override
  Future<DateTime?> getLastUpdatedAt() async => DateTime.now().toUtc();

  @override
  Future<bool> isTrackingEnabled() async => trackingEnabled;

  @override
  Future<StepsRefreshResult> refresh({
    bool force = false,
    DateTime? now,
  }) async =>
      const StepsRefreshResult(
        didRun: true,
        permissionGranted: true,
        skipped: false,
        fetchedCount: 0,
        upsertedCount: 0,
      );
}

class _FakeSleepSummaryRepository extends SleepHubSummaryRepository {
  _FakeSleepSummaryRepository(this.summary, {this.onFetch});

  final SleepHubSummary summary;
  final Future<SleepHubSummary> Function()? onFetch;
  int fetchCount = 0;

  @override
  Future<SleepHubSummary> fetchSummary({
    required DateTime endDate,
    required int daysBack,
  }) async {
    fetchCount++;
    final loader = onFetch;
    if (loader != null) return loader();
    return summary;
  }

  @override
  Future<void> dispose() async {}
}

class _FakePulseRepository implements PulseAnalysisRepository {
  _FakePulseRepository({
    this.summary,
    this.onAnalysis,
  });

  final PulseAnalysisSummary? summary;
  bool trackingEnabled = true;
  final Future<PulseAnalysisSummary> Function(PulseAnalysisWindow window)?
      onAnalysis;

  @override
  Future<PulseAnalysisSummary> getAnalysis({
    required PulseAnalysisWindow window,
  }) async {
    final loader = onAnalysis;
    if (loader != null) return loader(window);
    return summary ??
        PulseAnalysisSummary(
          window: window,
          samples: const [],
          chartSamples: const [],
          sampleCount: 0,
          quality: PulseDataQuality.noData,
          noDataReason: PulseNoDataReason.noSamples,
        );
  }

  @override
  Future<bool> isTrackingEnabled() async => trackingEnabled;
}

typedef _ConsistencySectionResult = ({
  List<Map<String, dynamic>> workoutsPerWeek,
  List<WeeklyConsistencyMetricPayload> weeklyConsistencyMetrics,
  TrainingStatsPayload trainingStats,
});

typedef _ConsistencySectionLoader = Future<_ConsistencySectionResult> Function(
  int selectedRangeIndex,
);

typedef _PerformanceSectionResult = ({
  List<Map<String, dynamic>> recentPrs,
  List<Map<String, dynamic>> notableImprovements,
});

typedef _PerformanceSectionLoader = Future<_PerformanceSectionResult> Function(
  int selectedRangeIndex,
);

typedef _VolumeMusclesSectionResult = ({
  List<Map<String, dynamic>> weeklyVolume,
  Map<String, dynamic> muscleAnalytics,
});

typedef _VolumeMusclesSectionLoader = Future<_VolumeMusclesSectionResult>
    Function(int selectedRangeIndex);

class _FakeSectionHubDataAdapter extends StatisticsHubDataAdapter {
  _FakeSectionHubDataAdapter({
    Future<RecoveryAnalyticsPayload> Function(int selectedRangeIndex)?
        recoveryLoader,
    _ConsistencySectionLoader? consistencyLoader,
    _PerformanceSectionLoader? performanceLoader,
    _VolumeMusclesSectionLoader? volumeMusclesLoader,
    Future<BodyNutritionAnalyticsResult> Function(int selectedRangeIndex)?
        bodyNutritionLoader,
  })  : _recoveryLoader = recoveryLoader,
        _consistencyLoader = consistencyLoader,
        _performanceLoader = performanceLoader,
        _volumeMusclesLoader = volumeMusclesLoader,
        _bodyNutritionLoader = bodyNutritionLoader,
        super(workoutDatabaseHelper: WorkoutDatabaseHelper.instance);

  final Future<RecoveryAnalyticsPayload> Function(int selectedRangeIndex)?
      _recoveryLoader;
  final _ConsistencySectionLoader? _consistencyLoader;
  final _PerformanceSectionLoader? _performanceLoader;
  final _VolumeMusclesSectionLoader? _volumeMusclesLoader;
  final Future<BodyNutritionAnalyticsResult> Function(int selectedRangeIndex)?
      _bodyNutritionLoader;

  @override
  Future<RecoveryAnalyticsPayload> fetchRecovery({
    required int selectedTimeRangeIndex,
  }) {
    return _recoveryLoader?.call(selectedTimeRangeIndex) ??
        Future.value(_emptyRecoveryPayload);
  }

  @override
  Future<
      ({
        List<Map<String, dynamic>> workoutsPerWeek,
        List<WeeklyConsistencyMetricPayload> weeklyConsistencyMetrics,
        TrainingStatsPayload trainingStats,
      })> fetchConsistency({required int selectedTimeRangeIndex}) {
    return _consistencyLoader?.call(selectedTimeRangeIndex) ??
        Future.value((
          workoutsPerWeek: const <Map<String, dynamic>>[],
          weeklyConsistencyMetrics: const <WeeklyConsistencyMetricPayload>[],
          trainingStats: _emptyTrainingStats,
        ));
  }

  @override
  Future<
      ({
        List<Map<String, dynamic>> recentPrs,
        List<Map<String, dynamic>> notableImprovements,
      })> fetchPerformanceRecords({required int selectedTimeRangeIndex}) {
    return _performanceLoader?.call(selectedTimeRangeIndex) ??
        Future.value((
          recentPrs: const <Map<String, dynamic>>[],
          notableImprovements: const <Map<String, dynamic>>[],
        ));
  }

  @override
  Future<
      ({
        List<Map<String, dynamic>> weeklyVolume,
        Map<String, dynamic> muscleAnalytics,
      })> fetchVolumeMuscles({required int selectedTimeRangeIndex}) {
    return _volumeMusclesLoader?.call(selectedTimeRangeIndex) ??
        Future.value((
          weeklyVolume: const <Map<String, dynamic>>[],
          muscleAnalytics: const <String, dynamic>{},
        ));
  }

  @override
  Future<BodyNutritionAnalyticsResult> fetchBodyNutrition({
    required int selectedTimeRangeIndex,
  }) {
    return _bodyNutritionLoader?.call(selectedTimeRangeIndex) ??
        Future.value(_emptyBodyNutritionResult());
  }
}

const _emptyTrainingStats = TrainingStatsPayload(
  totalWorkouts: 0,
  thisWeekCount: 0,
  avgPerWeek: 0,
  streakWeeks: 0,
);

const _emptyRecoveryPayload = RecoveryAnalyticsPayload(
  hasData: false,
  overallState: '',
  totals: RecoveryTotalsPayload(
    recovering: 0,
    ready: 0,
    fresh: 0,
    tracked: 0,
  ),
  muscles: [],
);

const _sleepSummary = SleepHubSummary(
  averageScore: 79,
  averageDuration: Duration(hours: 7, minutes: 15),
  averageBedtimeMinutes: 23 * 60,
  averageInterruptions: 1.0,
  averageWakeDuration: Duration(minutes: 12),
  nightsCount: 5,
);

BodyNutritionAnalyticsResult _emptyBodyNutritionResult() {
  return BodyNutritionAnalyticsResult(
    range: DateTimeRange(
      start: DateTime(2026),
      end: DateTime(2026, 1, 30),
    ),
    totalDays: 30,
    currentWeightKg: null,
    weightChangeKg: null,
    avgDailyCalories: 0,
    weightDays: 0,
    loggedCalorieDays: 0,
    weightDaily: const [],
    smoothedWeight: const [],
    caloriesDaily: const [],
    smoothedCalories: const [],
    weightTrend: const BodyNutritionTrendSnapshot(
      direction: BodyNutritionTrendDirection.unclear,
      slopePerWeek: null,
      netChange: null,
      signalToNoise: 0,
    ),
    calorieTrend: const BodyNutritionTrendSnapshot(
      direction: BodyNutritionTrendDirection.unclear,
      slopePerWeek: null,
      netChange: null,
      signalToNoise: 0,
    ),
    relationship: BodyNutritionRelationshipType.insufficientData,
    confidence: BodyNutritionConfidence.insufficient,
    qualitySummary: const BodyNutritionDataQualitySummary(
      spanDays: 30,
      weightDays: 0,
      calorieDays: 0,
      overlapDays: 0,
      weightCoverage: 0,
      calorieCoverage: 0,
      overlapCoverage: 0,
      weightLargestGapDays: 30,
      calorieLargestGapDays: 30,
    ),
    insightType: BodyNutritionInsightType.notEnoughData,
    insightDataQuality: const StatisticsDataQualityAssessment(
      hasSufficientData: false,
      reasonHook: 'quality:body-nutrition:insufficient',
    ),
  );
}

const _sleepConnectChannel =
    MethodChannel('trainlibre.health/sleep_health_connect');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      StepsSyncService.trackingEnabledKey: true,
      SleepSyncService.trackingEnabledKey: true,
    });
    StepsSyncService.trackingEnabledListenable.value = null;
    SleepSyncService.trackingEnabledListenable.value = null;
    PulseTrackingService.trackingEnabledListenable.value = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_sleepConnectChannel, (call) async {
      if (call.method == 'getAvailability') return 'unavailable';
      if (call.method == 'checkPermissions') {
        return <String, dynamic>{
          'sleepGranted': false,
          'heartRateGranted': false,
        };
      }
      if (call.method == 'requestPermissions') {
        return <String, dynamic>{
          'sleepGranted': false,
          'heartRateGranted': false,
        };
      }
      if (call.method == 'readSleepAndHeartRate') {
        return <String, dynamic>{
          'sessions': const <dynamic>[],
          'stageSegments': const <dynamic>[],
          'heartRateSamples': const <dynamic>[],
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_sleepConnectChannel, null);
  });

  Future<void> pumpLoaded(WidgetTester tester) async {
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpUntil(
    WidgetTester tester,
    bool Function() condition,
  ) async {
    for (var i = 0; i < 80; i++) {
      if (condition()) return;
      await tester.pump(const Duration(milliseconds: 50));
    }
    fail('Timed out waiting for condition.');
  }

  (StatisticsHubPayload, BodyNutritionAnalyticsResult) hubResult({
    String? topExerciseName,
  }) {
    final notableImprovements = topExerciseName == null
        ? <Map<String, dynamic>>[]
        : <Map<String, dynamic>>[
            {
              'exerciseName': topExerciseName,
              'improvementPct': 12.3,
            },
          ];

    return (
      StatisticsHubPayload(
        recentPrs: const [],
        weeklyVolume: const [],
        workoutsPerWeek: const [],
        weeklyConsistencyMetrics: const [],
        muscleAnalytics: const {},
        trainingStats: const TrainingStatsPayload(
          totalWorkouts: 0,
          thisWeekCount: 0,
          avgPerWeek: 0,
          streakWeeks: 0,
        ),
        recoveryAnalytics: const RecoveryAnalyticsPayload(
          hasData: false,
          overallState: '',
          totals: RecoveryTotalsPayload(
            recovering: 0,
            ready: 0,
            fresh: 0,
            tracked: 0,
          ),
          muscles: [],
        ),
        notableImprovements: notableImprovements,
      ),
      BodyNutritionAnalyticsResult(
        range: DateTimeRange(
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 1, 30),
        ),
        totalDays: 30,
        currentWeightKg: null,
        weightChangeKg: null,
        avgDailyCalories: 0,
        weightDays: 0,
        loggedCalorieDays: 0,
        weightDaily: const [],
        smoothedWeight: const [],
        caloriesDaily: const [],
        smoothedCalories: const [],
        weightTrend: const BodyNutritionTrendSnapshot(
          direction: BodyNutritionTrendDirection.unclear,
          slopePerWeek: null,
          netChange: null,
          signalToNoise: 0,
        ),
        calorieTrend: const BodyNutritionTrendSnapshot(
          direction: BodyNutritionTrendDirection.unclear,
          slopePerWeek: null,
          netChange: null,
          signalToNoise: 0,
        ),
        relationship: BodyNutritionRelationshipType.insufficientData,
        confidence: BodyNutritionConfidence.insufficient,
        qualitySummary: const BodyNutritionDataQualitySummary(
          spanDays: 30,
          weightDays: 0,
          calorieDays: 0,
          overlapDays: 0,
          weightCoverage: 0,
          calorieCoverage: 0,
          overlapCoverage: 0,
          weightLargestGapDays: 30,
          calorieLargestGapDays: 30,
        ),
        insightType: BodyNutritionInsightType.notEnoughData,
        insightDataQuality: const StatisticsDataQualityAssessment(
          hasSufficientData: false,
          reasonHook: 'quality:body-nutrition:insufficient',
        ),
      ),
    );
  }

  Future<(StatisticsHubPayload, BodyNutritionAnalyticsResult)> fakeFetch(
    int _,
  ) async {
    return hubResult();
  }

  _PerformanceSectionResult performanceSectionResult(String exerciseName) {
    return (
      recentPrs: const <Map<String, dynamic>>[],
      notableImprovements: <Map<String, dynamic>>[
        {
          'exerciseName': exerciseName,
          'improvementPct': 12.3,
        },
      ],
    );
  }

  Widget wrapWithSessionManager(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WorkoutSessionManager>.value(
          value: WorkoutSessionManager(),
        ),
        ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
        ChangeNotifierProvider<UnitService>(create: (_) => UnitService()),
      ],
      child: child,
    );
  }

  Finder stepsSectionHeader() {
    return find.descendant(
      of: find.byType(StatisticsHubScreen),
      matching: find.text('STEPS'),
    );
  }

  StatisticsHubScreen buildHub({
    required StepsAggregationRepository stepsRepository,
    PulseAnalysisRepository? pulseRepository,
    SleepHubSummaryRepository? sleepSummaryRepository,
    StatisticsHubDataAdapter? hubDataAdapter,
    Future<bool> Function()? isSleepTrackingEnabled,
    Future<(StatisticsHubPayload, BodyNutritionAnalyticsResult)> Function(int)?
        fetchHubAnalytics,
  }) {
    return StatisticsHubScreen(
      hubDataAdapter: hubDataAdapter,
      stepsRepository: stepsRepository,
      pulseRepository: pulseRepository,
      sleepSummaryRepository:
          sleepSummaryRepository ?? _FakeSleepSummaryRepository(_sleepSummary),
      fetchHubAnalytics: hubDataAdapter == null
          ? fetchHubAnalytics ?? fakeFetch
          : fetchHubAnalytics,
      importSleepIfDue: ({
        int lookbackDays = 30,
        Duration minInterval = const Duration(hours: 6),
        bool force = false,
      }) async {
        return null;
      },
      isSleepTrackingEnabled: isSleepTrackingEnabled ?? () async => true,
      targetStepsLoader: () async => StepsSyncService.defaultStepsGoal,
      stepsProviderNameLoader: () async => 'Local',
    );
  }

  testWidgets('statistics hub range switching updates steps card subtitle', (
    WidgetTester tester,
  ) async {
    await StepsSyncService().setTrackingEnabled(true);
    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(stepsRepository: _FakeStepsRepository()),
        ),
      ),
    );
    await pumpLoaded(tester);

    expect(stepsSectionHeader(), findsOneWidget);
    final initialChips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(initialChips.elementAt(1).selected, isTrue);

    await tester.tap(find.byType(ChoiceChip).first);
    await pumpLoaded(tester);
    final changedChips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(changedChips.first.selected, isTrue);
    expect(stepsSectionHeader(), findsOneWidget);
  });

  testWidgets('statistics hub ignores stale overlapping range loads', (
    WidgetTester tester,
  ) async {
    await StepsSyncService().setTrackingEnabled(true);
    final pendingFetches = <int,
        Completer<(StatisticsHubPayload, BodyNutritionAnalyticsResult)>>{};

    Future<(StatisticsHubPayload, BodyNutritionAnalyticsResult)> delayedFetch(
      int rangeIndex,
    ) {
      return pendingFetches
          .putIfAbsent(
            rangeIndex,
            () => Completer<
                (StatisticsHubPayload, BodyNutritionAnalyticsResult)>(),
          )
          .future;
    }

    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(),
            fetchHubAnalytics: delayedFetch,
          ),
        ),
      ),
    );

    await pumpUntil(tester, () => pendingFetches.containsKey(1));
    pendingFetches[1]!.complete(hubResult(topExerciseName: 'Initial range'));
    await pumpLoaded(tester);
    expect(find.text('73,500'), findsOneWidget);

    await tester.tap(find.byType(ChoiceChip).first);
    await pumpUntil(tester, () => pendingFetches.containsKey(0));

    await tester.tap(find.byType(ChoiceChip).at(2));
    await pumpUntil(tester, () => pendingFetches.containsKey(2));

    pendingFetches[2]!.complete(hubResult(topExerciseName: 'Fresh range'));
    await pumpLoaded(tester);
    expect(find.text('490,500'), findsOneWidget);

    pendingFetches[0]!.complete(hubResult(topExerciseName: 'Stale range'));
    await pumpLoaded(tester);
    expect(find.text('490,500'), findsOneWidget);
    expect(find.text('9,100'), findsNothing);
  });

  testWidgets('statistics hub clears loading when aggregate load throws', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await StepsSyncService().setTrackingEnabled(true);

    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(),
            fetchHubAnalytics: (_) async => throw StateError('boom'),
          ),
        ),
      ),
    );

    await pumpLoaded(tester);

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('statistics_section_error_performanceRecords')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('statistics_section_loading_performanceRecords')),
      findsNothing,
    );
  });

  testWidgets('slow section does not block completed statistics sections', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await StepsSyncService().setTrackingEnabled(true);
    final pendingBody = Completer<BodyNutritionAnalyticsResult>();

    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(),
            hubDataAdapter: _FakeSectionHubDataAdapter(
              performanceLoader: (_) async =>
                  performanceSectionResult('Fast section'),
              bodyNutritionLoader: (_) => pendingBody.future,
            ),
          ),
        ),
      ),
    );

    await pumpUntil(
        tester, () => find.text('Fast section').evaluate().isNotEmpty);

    expect(find.text('Fast section'), findsOneWidget);
    expect(
      find.byKey(const Key('statistics_section_loading_bodyNutrition')),
      findsOneWidget,
    );

    pendingBody.complete(_emptyBodyNutritionResult());
    await pumpLoaded(tester);
  });

  testWidgets('failing section clears loading and shows local error', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await StepsSyncService().setTrackingEnabled(true);

    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(),
            hubDataAdapter: _FakeSectionHubDataAdapter(
              performanceLoader: (_) async =>
                  performanceSectionResult('Still rendered'),
              bodyNutritionLoader: (_) async => throw StateError('body boom'),
            ),
          ),
        ),
      ),
    );

    await pumpLoaded(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Still rendered'), findsOneWidget);
    expect(
      find.byKey(const Key('statistics_section_error_bodyNutrition')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('statistics_section_loading_bodyNutrition')),
      findsNothing,
    );
  });

  testWidgets('section range refresh keeps stale data visible until replaced', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await StepsSyncService().setTrackingEnabled(true);
    final pendingPerformance = <int, Completer<_PerformanceSectionResult>>{};

    Future<_PerformanceSectionResult> loadPerformance(int rangeIndex) {
      return pendingPerformance
          .putIfAbsent(rangeIndex, Completer<_PerformanceSectionResult>.new)
          .future;
    }

    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(),
            hubDataAdapter: _FakeSectionHubDataAdapter(
              performanceLoader: loadPerformance,
            ),
          ),
        ),
      ),
    );

    await pumpUntil(tester, () => pendingPerformance.containsKey(1));
    pendingPerformance[1]!.complete(performanceSectionResult('Initial range'));
    await pumpLoaded(tester);
    expect(find.text('Initial range'), findsOneWidget);

    await tester.tap(find.byType(ChoiceChip).at(2));
    await pumpUntil(tester, () => pendingPerformance.containsKey(2));
    await tester.pump();
    expect(find.text('Initial range'), findsOneWidget);

    pendingPerformance[2]!.complete(performanceSectionResult('Fresh range'));
    await pumpLoaded(tester);
    expect(find.text('Fresh range'), findsOneWidget);
    expect(find.text('Initial range'), findsNothing);
  });

  testWidgets('section stale request cannot overwrite newer range result', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await StepsSyncService().setTrackingEnabled(true);
    final pendingPerformance = <int, Completer<_PerformanceSectionResult>>{};

    Future<_PerformanceSectionResult> loadPerformance(int rangeIndex) {
      return pendingPerformance
          .putIfAbsent(rangeIndex, Completer<_PerformanceSectionResult>.new)
          .future;
    }

    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(),
            hubDataAdapter: _FakeSectionHubDataAdapter(
              performanceLoader: loadPerformance,
            ),
          ),
        ),
      ),
    );

    await pumpUntil(tester, () => pendingPerformance.containsKey(1));
    pendingPerformance[1]!.complete(performanceSectionResult('Initial range'));
    await pumpLoaded(tester);

    await tester.tap(find.byType(ChoiceChip).first);
    await pumpUntil(tester, () => pendingPerformance.containsKey(0));

    await tester.tap(find.byType(ChoiceChip).at(2));
    await pumpUntil(tester, () => pendingPerformance.containsKey(2));

    pendingPerformance[2]!.complete(performanceSectionResult('Fresh range'));
    await pumpLoaded(tester);
    expect(find.text('Fresh range'), findsOneWidget);

    pendingPerformance[0]!.complete(performanceSectionResult('Stale range'));
    await pumpLoaded(tester);
    expect(find.text('Fresh range'), findsOneWidget);
    expect(find.text('Stale range'), findsNothing);
  });

  testWidgets('recovery section preserves fixed current-state range policy', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await StepsSyncService().setTrackingEnabled(true);
    final recoveryLookbacks = <int?>[];

    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(),
            hubDataAdapter: _FakeSectionHubDataAdapter(
              recoveryLoader: (rangeIndex) async {
                final resolved = StatisticsRangePolicyService.instance.resolve(
                  metricId: StatisticsMetricId.hubRecoveryReadiness,
                  selectedRangeIndex: rangeIndex,
                );
                recoveryLookbacks.add(resolved.effectiveDays);
                return _emptyRecoveryPayload;
              },
            ),
          ),
        ),
      ),
    );

    await pumpLoaded(tester);
    await tester.tap(find.byType(ChoiceChip).at(3));
    await pumpLoaded(tester);

    expect(recoveryLookbacks,
        contains(RecoveryDomainService.recoveryLookbackDays));
    expect(recoveryLookbacks.toSet(),
        {RecoveryDomainService.recoveryLookbackDays});
  });

  testWidgets('statistics hub hides steps card when tracking is disabled', (
    WidgetTester tester,
  ) async {
    await StepsSyncService().setTrackingEnabled(false);
    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(trackingEnabled: false),
          ),
        ),
      ),
    );
    await pumpLoaded(tester);

    expect(stepsSectionHeader(), findsNothing);
  });

  testWidgets('statistics hub updates steps visibility when setting toggles', (
    WidgetTester tester,
  ) async {
    await StepsSyncService().setTrackingEnabled(true);
    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(trackingEnabled: true),
          ),
        ),
      ),
    );
    await pumpLoaded(tester);
    expect(stepsSectionHeader(), findsOneWidget);

    final stepsService = StepsSyncService();
    await stepsService.setTrackingEnabled(false);
    await pumpLoaded(tester);
    expect(stepsSectionHeader(), findsNothing);

    await stepsService.setTrackingEnabled(true);
    await pumpLoaded(tester);
    expect(stepsSectionHeader(), findsOneWidget);
  });

  testWidgets('statistics hub hides sleep card when tracking is disabled', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final sleepRepository = _FakeSleepSummaryRepository(_sleepSummary);

    await StepsSyncService().setTrackingEnabled(true);
    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(),
            sleepSummaryRepository: sleepRepository,
            isSleepTrackingEnabled: () async => false,
          ),
        ),
      ),
    );
    await pumpLoaded(tester);

    expect(find.text('Sleep score'), findsNothing);
    expect(
      find.byKey(const Key('statistics_section_loading_sleep')),
      findsNothing,
    );
    expect(
        find.byKey(const Key('statistics_section_error_sleep')), findsNothing);
    expect(sleepRepository.fetchCount, 0);
  });

  testWidgets('statistics hub hides sleep card after tracking toggles off', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var sleepEnabled = true;

    await StepsSyncService().setTrackingEnabled(true);
    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(),
            isSleepTrackingEnabled: () async => sleepEnabled,
          ),
        ),
      ),
    );
    await pumpLoaded(tester);
    expect(find.text('Sleep score'), findsOneWidget);

    sleepEnabled = false;
    SleepSyncService.trackingEnabledListenable.value = false;
    await tester.pump();

    expect(find.text('Sleep score'), findsNothing);
    expect(
      find.byKey(const Key('statistics_section_loading_sleep')),
      findsNothing,
    );
    expect(
        find.byKey(const Key('statistics_section_error_sleep')), findsNothing);
  });

  testWidgets('in-flight sleep load cannot re-render after tracking disables', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var sleepEnabled = true;
    var fetchCount = 0;
    final pendingRefresh = Completer<SleepHubSummary>();
    final sleepRepository = _FakeSleepSummaryRepository(
      _sleepSummary,
      onFetch: () {
        fetchCount++;
        if (fetchCount == 1) return Future.value(_sleepSummary);
        return pendingRefresh.future;
      },
    );

    await StepsSyncService().setTrackingEnabled(true);
    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(),
            sleepSummaryRepository: sleepRepository,
            isSleepTrackingEnabled: () async => sleepEnabled,
          ),
        ),
      ),
    );
    await pumpLoaded(tester);
    expect(find.text('Sleep score'), findsOneWidget);

    await tester.tap(find.byType(ChoiceChip).at(2));
    await pumpUntil(tester, () => sleepRepository.fetchCount >= 2);

    sleepEnabled = false;
    SleepSyncService.trackingEnabledListenable.value = false;
    await tester.pump();
    expect(find.text('Sleep score'), findsNothing);

    pendingRefresh.complete(_sleepSummary);
    await pumpLoaded(tester);
    expect(find.text('Sleep score'), findsNothing);
  });

  testWidgets('sleep card loads again after tracking toggles back on', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var sleepEnabled = false;

    await StepsSyncService().setTrackingEnabled(true);
    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(),
            isSleepTrackingEnabled: () async => sleepEnabled,
          ),
        ),
      ),
    );
    await pumpLoaded(tester);
    expect(find.text('Sleep score'), findsNothing);

    sleepEnabled = true;
    SleepSyncService.trackingEnabledListenable.value = true;
    await pumpLoaded(tester);

    expect(find.text('Sleep score'), findsOneWidget);
  });

  testWidgets('in-flight pulse load cannot re-render after tracking disables', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final initialWindow = PulseAnalysisWindow(
      startUtc: DateTime.utc(2026, 1),
      endUtc: DateTime.utc(2026, 1, 31),
    );
    var analysisCount = 0;
    final pendingRefresh = Completer<PulseAnalysisSummary>();
    final pulseRepository = _FakePulseRepository(
      summary: PulseAnalysisSummary(
        window: initialWindow,
        samples: const [],
        chartSamples: const [],
        sampleCount: 12,
        quality: PulseDataQuality.ready,
        noDataReason: PulseNoDataReason.none,
        minBpm: 50,
        maxBpm: 90,
        averageBpm: 70,
        restingBpm: 55,
      ),
      onAnalysis: (window) {
        analysisCount++;
        if (analysisCount == 1) {
          return Future.value(PulseAnalysisSummary(
            window: initialWindow,
            samples: const [],
            chartSamples: const [],
            sampleCount: 12,
            quality: PulseDataQuality.ready,
            noDataReason: PulseNoDataReason.none,
            minBpm: 50,
            maxBpm: 90,
            averageBpm: 70,
            restingBpm: 55,
          ));
        }
        return pendingRefresh.future;
      },
    );

    await StepsSyncService().setTrackingEnabled(true);
    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(),
            pulseRepository: pulseRepository,
          ),
        ),
      ),
    );
    await pumpLoaded(tester);
    expect(find.byKey(const Key('statistics_pulse_card')), findsOneWidget);

    await tester.tap(find.byType(ChoiceChip).at(2));
    await pumpUntil(tester, () => analysisCount >= 2);

    pulseRepository.trackingEnabled = false;
    PulseTrackingService.trackingEnabledListenable.value = false;
    await tester.pump();
    expect(find.byKey(const Key('statistics_pulse_card')), findsNothing);

    pendingRefresh.complete(PulseAnalysisSummary(
      window: initialWindow,
      samples: const [],
      chartSamples: const [],
      sampleCount: 8,
      quality: PulseDataQuality.ready,
      noDataReason: PulseNoDataReason.none,
      minBpm: 52,
      maxBpm: 88,
      averageBpm: 68,
      restingBpm: 54,
    ));
    await pumpLoaded(tester);
    expect(find.byKey(const Key('statistics_pulse_card')), findsNothing);
  });

  testWidgets('statistics hub sleep card opens sleep day screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await StepsSyncService().setTrackingEnabled(true);
    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: SleepNavigation.onGenerateRoute,
          home: buildHub(stepsRepository: _FakeStepsRepository()),
        ),
      ),
    );
    await pumpLoaded(tester);

    final sleepScoreLabel = find.text('Sleep score');
    await tester.tap(sleepScoreLabel);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(SleepDayOverviewPage), findsOneWidget);
  });

  testWidgets('statistics hub pulse card shows selected range and KPI values', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await StepsSyncService().setTrackingEnabled(true);
    final window = PulseAnalysisWindow(
      startUtc: DateTime.utc(2026, 1),
      endUtc: DateTime.utc(2026, 1, 31),
    );
    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(
            stepsRepository: _FakeStepsRepository(),
            pulseRepository: _FakePulseRepository(
              summary: PulseAnalysisSummary(
                window: window,
                samples: const [],
                chartSamples: const [],
                sampleCount: 12,
                quality: PulseDataQuality.ready,
                noDataReason: PulseNoDataReason.none,
                minBpm: 50,
                maxBpm: 90,
                averageBpm: 70,
                restingBpm: 55,
              ),
            ),
          ),
        ),
      ),
    );
    await pumpLoaded(tester);

    final pulseCard = find.byKey(const Key('statistics_pulse_card'));
    expect(pulseCard, findsOneWidget);
    expect(
      find.descendant(of: pulseCard, matching: find.text('Jan 1 - Jan 30')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: pulseCard, matching: find.text('Range')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: pulseCard, matching: find.text('50-90 bpm')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: pulseCard, matching: find.text('Average')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: pulseCard, matching: find.text('70 bpm')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: pulseCard, matching: find.text('Resting')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: pulseCard, matching: find.text('55 bpm')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: pulseCard,
        matching: find.text('12 samples - Good coverage'),
      ),
      findsOneWidget,
    );
    expect(find.text('Opt-in'), findsNothing);
  });

  testWidgets('statistics hub body section shows measurements link', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await StepsSyncService().setTrackingEnabled(true);
    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(stepsRepository: _FakeStepsRepository()),
        ),
      ),
    );
    await pumpLoaded(tester);

    final measurementsLink = find.byKey(
      const Key('statistics_measurements_link_card'),
    );
    expect(measurementsLink, findsOneWidget);
    expect(find.text('Body measurements'), findsWidgets);
  });

  testWidgets('statistics hub measurements link opens measurements screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await StepsSyncService().setTrackingEnabled(true);
    await tester.pumpWidget(
      wrapWithSessionManager(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildHub(stepsRepository: _FakeStepsRepository()),
        ),
      ),
    );
    await pumpLoaded(tester);

    final measurementsLink = find.byKey(
      const Key('statistics_measurements_link_card'),
    );
    expect(measurementsLink, findsOneWidget);
    await tester.tap(measurementsLink);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(MeasurementsScreen), findsOneWidget);
  });
}
