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
import 'package:hypertrack/screens/statistics_hub_screen.dart';

class _FakeStepsRepository implements StepsAggregationRepository {
  @override
  Future<RangeStepsAggregation> getRangeAggregation({
    required DateTime endDate,
    required int daysBack,
  }) async {
    final start = DateTime(endDate.year, endDate.month, endDate.day)
        .subtract(Duration(days: daysBack - 1));
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
  Future<MonthStepsAggregation> getMonthAggregation(DateTime dateInMonth) async =>
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
  Future<bool> isTrackingEnabled() async => true;

  @override
  Future<StepsRefreshResult> refresh({bool force = false, DateTime? now}) async =>
      const StepsRefreshResult(
        didRun: true,
        permissionGranted: true,
        skipped: false,
        fetchedCount: 0,
        upsertedCount: 0,
      );
}

void main() {
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
        range: DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 30)),
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
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticsHubScreen(
          stepsRepository: _FakeStepsRepository(),
          fetchHubAnalytics: fakeFetch,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Steps'), findsOneWidget);
    expect(find.textContaining('Last 30 days'), findsOneWidget);

    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Last 7 days'), findsOneWidget);
  });
}
