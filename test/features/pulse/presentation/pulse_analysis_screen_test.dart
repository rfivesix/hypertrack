import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/pulse/data/pulse_repository.dart';
import 'package:hypertrack/features/pulse/domain/pulse_models.dart';
import 'package:hypertrack/features/pulse/presentation/pulse_analysis_screen.dart';
import 'package:hypertrack/generated/app_localizations.dart';
import 'package:hypertrack/widgets/measurement_chart_widget.dart';

class _FakePulseRepository implements PulseAnalysisRepository {
  _FakePulseRepository(this.summaryBuilder);

  final PulseAnalysisSummary Function(PulseAnalysisWindow window)
      summaryBuilder;
  final windows = <PulseAnalysisWindow>[];

  @override
  Future<PulseAnalysisSummary> getAnalysis({
    required PulseAnalysisWindow window,
  }) async {
    windows.add(window);
    return summaryBuilder(window);
  }

  @override
  Future<bool> isTrackingEnabled() async => true;
}

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

PulseAnalysisSummary _summaryWithSamples(PulseAnalysisWindow window) {
  final start = window.startUtc;
  final samples = [
    PulseSamplePoint(
        sampledAtUtc: start.add(const Duration(hours: 1)), bpm: 60),
    PulseSamplePoint(
        sampledAtUtc: start.add(const Duration(hours: 2)), bpm: 70),
    PulseSamplePoint(
        sampledAtUtc: start.add(const Duration(hours: 3)), bpm: 80),
  ];
  return PulseAnalysisSummary(
    window: window,
    samples: samples,
    chartSamples: samples,
    sampleCount: samples.length,
    quality: PulseDataQuality.ready,
    noDataReason: PulseNoDataReason.none,
    averageBpm: 70,
    minBpm: 60,
    maxBpm: 80,
    restingBpm: 60,
  );
}

void main() {
  testWidgets('renders KPI metrics and reused measurement chart',
      (tester) async {
    final repository = _FakePulseRepository(_summaryWithSamples);

    await tester.pumpWidget(
      _wrap(
        PulseAnalysisScreen(
          repository: repository,
          initialDate: DateTime(2026, 4, 20),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Range'), findsOneWidget);
    expect(find.text('60-80 bpm'), findsOneWidget);
    expect(find.text('Average'), findsOneWidget);
    expect(find.text('70 bpm'), findsWidgets);
    expect(find.text('Resting'), findsOneWidget);
    expect(find.byType(MeasurementChartWidget), findsOneWidget);
  });

  testWidgets('scope and period controls drive selected analysis window',
      (tester) async {
    final repository = _FakePulseRepository(_summaryWithSamples);

    await tester.pumpWidget(
      _wrap(
        PulseAnalysisScreen(
          repository: repository,
          initialDate: DateTime(2026, 4, 22),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(repository.windows.last.startUtc, DateTime(2026, 4, 20).toUtc());
    expect(repository.windows.last.endUtc, DateTime(2026, 4, 27).toUtc());

    await tester.tap(find.byKey(const Key('sleep-period-prev')));
    await tester.pumpAndSettle();

    expect(repository.windows.last.startUtc, DateTime(2026, 4, 13).toUtc());
    expect(repository.windows.last.endUtc, DateTime(2026, 4, 20).toUtc());
  });

  testWidgets('shows disabled empty state honestly', (tester) async {
    final repository = _FakePulseRepository(
      (window) => PulseAnalysisSummary(
        window: window,
        samples: const [],
        chartSamples: const [],
        sampleCount: 0,
        quality: PulseDataQuality.noData,
        noDataReason: PulseNoDataReason.disabled,
      ),
    );

    await tester.pumpWidget(
      _wrap(
        PulseAnalysisScreen(
          repository: repository,
          initialDate: DateTime(2026, 4, 20),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.text('Pulse analysis is disabled in Settings.'), findsOneWidget);
    expect(find.byType(MeasurementChartWidget), findsNothing);
  });
}
