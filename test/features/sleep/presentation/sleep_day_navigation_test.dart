import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/data/sleep_day_repository.dart';
import 'package:hypertrack/features/sleep/domain/derived/nightly_sleep_analysis.dart';
import 'package:hypertrack/features/sleep/domain/sleep_domain.dart';
import 'package:hypertrack/features/sleep/presentation/day/sleep_day_overview_page.dart';
import 'package:hypertrack/features/sleep/presentation/day/sleep_day_view_model.dart';
import 'package:hypertrack/features/sleep/presentation/sleep_navigation.dart';

class _FakeSleepDayRepository implements SleepDayDataRepository {
  _FakeSleepDayRepository(this.data);

  final SleepDayOverviewData? data;

  @override
  Future<SleepDayOverviewData?> fetchOverview(DateTime day) async => data;

  @override
  Future<void> dispose() async {}
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
    isHrBaselineEstablished: true,
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
    stageDataConfidence: SleepStageConfidence.high,
  );
}

void main() {
  testWidgets('navigates from day tiles to detail routes', (tester) async {
    final overview = _sampleOverview();
    final model = SleepDayViewModel(repository: _FakeSleepDayRepository(overview));

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepDayOverviewPage(viewModel: model),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Duration'));
    await tester.pumpAndSettle();
    expect(find.text('Duration'), findsWidgets);
    expect(find.text('Adults often do best with roughly 7–9 hours. This benchmark helps you see where your night sits in that range.'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Heart rate'));
    await tester.pumpAndSettle();
    expect(find.text('Heart rate'), findsWidgets);
  });

  testWidgets('renders empty state without crash', (tester) async {
    final model = SleepDayViewModel(repository: _FakeSleepDayRepository(null));
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: SleepNavigation.onGenerateRoute,
        home: SleepDayOverviewPage(viewModel: model),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No sleep data available for this day.'), findsOneWidget);
  });
}
