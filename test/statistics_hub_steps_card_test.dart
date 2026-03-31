import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/generated/app_localizations.dart';
import 'package:hypertrack/features/statistics/domain/body_nutrition_analytics_models.dart';
import 'package:hypertrack/features/statistics/domain/consistency_payload_models.dart';
import 'package:hypertrack/features/statistics/domain/hub_payload_models.dart';
import 'package:hypertrack/features/statistics/domain/recovery_payload_models.dart';
import 'package:hypertrack/features/statistics/domain/statistics_data_quality_policy.dart';
import 'package:hypertrack/features/steps/data/steps_aggregation_repository.dart';
import 'package:hypertrack/features/steps/domain/steps_models.dart';
import 'package:hypertrack/features/sleep/presentation/day/sleep_day_overview_page.dart';
import 'package:hypertrack/screens/statistics_hub_screen.dart';
import 'package:hypertrack/services/health/steps_sync_service.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      StepsSyncService.trackingEnabledKey: true,
    });
    StepsSyncService.trackingEnabledListenable.value = null;
  });

  Future<void> pumpLoaded(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<(StatisticsHubPayload, BodyNutritionAnalyticsResult)> fakeFetch(
    int _,
  ) async {
    return (
      const StatisticsHubPayload(
        recentPrs: [],
        weeklyVolume: [],
        workoutsPerWeek: [],
        weeklyConsistencyMetrics: [],
        muscleAnalytics: {},
        trainingStats: TrainingStatsPayload(
          totalWorkouts: 0,
          thisWeekCount: 0,
          avgPerWeek: 0,
          streakWeeks: 0,
        ),
        recoveryAnalytics: RecoveryAnalyticsPayload(
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
        notableImprovements: [],
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
        insightType: BodyNutritionInsightType.notEnoughData,
        insightDataQuality: const StatisticsDataQualityAssessment(
          hasSufficientData: false,
          reasonHook: 'quality:body-nutrition:insufficient',
        ),
      ),
    );
  }

  testWidgets('statistics hub range switching updates steps card subtitle', (
    WidgetTester tester,
  ) async {
    await StepsSyncService().setTrackingEnabled(true);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticsHubScreen(
          stepsRepository: _FakeStepsRepository(),
          fetchHubAnalytics: fakeFetch,
        ),
      ),
    );
    await pumpLoaded(tester);

    expect(find.text('Steps'), findsOneWidget);
    final initialChips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(initialChips.elementAt(1).selected, isTrue);

    await tester.tap(find.byType(ChoiceChip).first);
    await pumpLoaded(tester);
    final changedChips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(changedChips.first.selected, isTrue);
    expect(find.text('Steps'), findsOneWidget);
  });

  testWidgets('statistics hub hides steps card when tracking is disabled', (
    WidgetTester tester,
  ) async {
    await StepsSyncService().setTrackingEnabled(false);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticsHubScreen(
          stepsRepository: _FakeStepsRepository(trackingEnabled: false),
          fetchHubAnalytics: fakeFetch,
        ),
      ),
    );
    await pumpLoaded(tester);

    expect(find.text('Steps'), findsNothing);
  });

  testWidgets('statistics hub updates steps visibility when setting toggles', (
    WidgetTester tester,
  ) async {
    await StepsSyncService().setTrackingEnabled(true);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticsHubScreen(
          stepsRepository: _FakeStepsRepository(trackingEnabled: true),
          fetchHubAnalytics: fakeFetch,
        ),
      ),
    );
    await pumpLoaded(tester);
    expect(find.text('Steps'), findsOneWidget);

    final stepsService = StepsSyncService();
    await stepsService.setTrackingEnabled(false);
    await pumpLoaded(tester);
    expect(find.text('Steps'), findsNothing);

    await stepsService.setTrackingEnabled(true);
    await pumpLoaded(tester);
    expect(find.text('Steps'), findsOneWidget);
  });

  testWidgets('statistics hub sleep card opens sleep day screen', (
    WidgetTester tester,
  ) async {
    await StepsSyncService().setTrackingEnabled(true);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticsHubScreen(
          stepsRepository: _FakeStepsRepository(),
          fetchHubAnalytics: fakeFetch,
        ),
      ),
    );
    await pumpLoaded(tester);

    expect(find.text('Sleep'), findsOneWidget);
    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();

    expect(find.byType(SleepDayOverviewPage), findsOneWidget);
  });
}
