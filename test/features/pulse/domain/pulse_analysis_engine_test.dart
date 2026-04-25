import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/pulse/domain/pulse_analysis_engine.dart';
import 'package:hypertrack/features/pulse/domain/pulse_models.dart';

void main() {
  const engine = PulseAnalysisEngine();

  test('uses time-aware average for unevenly spaced samples', () {
    final start = DateTime.utc(2026, 4, 20, 10);
    final window = PulseAnalysisWindow(
      startUtc: start,
      endUtc: start.add(const Duration(hours: 1)),
    );

    final summary = engine.analyze(
      window: window,
      rawSamples: [
        PulseSamplePoint(sampledAtUtc: start, bpm: 60),
        PulseSamplePoint(
          sampledAtUtc: start.add(const Duration(minutes: 10)),
          bpm: 120,
        ),
        PulseSamplePoint(
          sampledAtUtc: start.add(const Duration(minutes: 60)),
          bpm: 120,
        ),
      ],
    );

    expect(summary.averageBpm, closeTo(115, 0.001));
  });

  test('calculates conservative resting pulse from lowest sample window', () {
    final start = DateTime.utc(2026, 4, 20, 10);
    final window = PulseAnalysisWindow(
      startUtc: start,
      endUtc: start.add(const Duration(hours: 1)),
    );
    final values = [80, 75, 71, 69, 66, 65, 90, 88, 72, 77];

    final summary = engine.analyze(
      window: window,
      rawSamples: [
        for (var i = 0; i < values.length; i++)
          PulseSamplePoint(
            sampledAtUtc: start.add(Duration(minutes: i * 5)),
            bpm: values[i].toDouble(),
          ),
      ],
    );

    expect(summary.restingBpm, closeTo(65.5, 0.001));
  });

  test('deduplicates timestamps and preserves insufficient data state', () {
    final start = DateTime.utc(2026, 4, 20, 10);
    final window = PulseAnalysisWindow(
      startUtc: start,
      endUtc: start.add(const Duration(hours: 1)),
    );

    final summary = engine.analyze(
      window: window,
      rawSamples: [
        PulseSamplePoint(sampledAtUtc: start, bpm: 60),
        PulseSamplePoint(sampledAtUtc: start, bpm: 64),
        PulseSamplePoint(
          sampledAtUtc: start.add(const Duration(minutes: 10)),
          bpm: 70,
        ),
        PulseSamplePoint(
          sampledAtUtc: start.add(const Duration(minutes: 70)),
          bpm: 180,
        ),
      ],
    );

    expect(summary.sampleCount, 2);
    expect(summary.samples.first.bpm, closeTo(62, 0.001));
    expect(summary.quality, PulseDataQuality.insufficient);
    expect(summary.canRenderChart, isFalse);
  });
}
