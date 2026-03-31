import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/domain/heart_rate_sample.dart';
import 'package:hypertrack/features/sleep/domain/metrics/heart_rate_metrics.dart';

void main() {
  test('nightly HR metrics use 5th percentile min and average', () {
    final metrics = calculateNightlyHeartRateMetrics(
      sleepWindowSamples: List.generate(
        10,
        (i) => HeartRateSample(
          id: 'hr-$i',
          sessionId: 's1',
          sampledAtUtc: DateTime.utc(2026, 3, 1, 23, i),
          bpm: 50 + i.toDouble(),
          sourcePlatform: 'healthkit',
        ),
      ),
      minimumSampleCount: 5,
    );
    expect(metrics.coverageSufficient, isTrue);
    expect(metrics.sleepHrAvg, closeTo(54.5, 0.001));
    expect(metrics.sleepHrMin, 50);
  });

  test('baseline requires at least 10 valid nights', () {
    final immature = calculateSleepHeartRateBaseline(
      List<double>.generate(9, (i) => 50 + i.toDouble()),
    );
    expect(immature.isEstablished, isFalse);
    expect(immature.baselineSleepHr, isNull);

    final mature = calculateSleepHeartRateBaseline(
      List<double>.generate(12, (i) => 50 + i.toDouble()),
    );
    expect(mature.isEstablished, isTrue);
    expect(mature.baselineSleepHr, isNotNull);
  });
}
