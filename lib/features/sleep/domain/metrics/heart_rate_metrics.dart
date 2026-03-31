import '../heart_rate_sample.dart';

class NightlyHeartRateMetrics {
  const NightlyHeartRateMetrics({
    required this.sleepHrAvg,
    required this.sleepHrMin,
    required this.coverageSufficient,
  });

  final double? sleepHrAvg;
  final double? sleepHrMin;
  final bool coverageSufficient;
}

class SleepHeartRateBaseline {
  const SleepHeartRateBaseline({
    required this.baselineSleepHr,
    required this.isEstablished,
    required this.validNights,
  });

  final double? baselineSleepHr;
  final bool isEstablished;
  final int validNights;
}

class SleepHeartRateDelta {
  const SleepHeartRateDelta({
    required this.deltaSleepHr,
    required this.baselineEstablished,
    required this.coverageSufficient,
  });

  final double? deltaSleepHr;
  final bool baselineEstablished;
  final bool coverageSufficient;
}

NightlyHeartRateMetrics calculateNightlyHeartRateMetrics({
  required List<HeartRateSample> sleepWindowSamples,
  int minimumSampleCount = 5,
}) {
  if (sleepWindowSamples.length < minimumSampleCount) {
    return const NightlyHeartRateMetrics(
      sleepHrAvg: null,
      sleepHrMin: null,
      coverageSufficient: false,
    );
  }
  final bpms = sleepWindowSamples.map((sample) => sample.bpm).toList()..sort();
  final avg = bpms.fold<double>(0, (sum, bpm) => sum + bpm) / bpms.length;
  final p5Index = ((bpms.length - 1) * 0.05).floor();
  return NightlyHeartRateMetrics(
    sleepHrAvg: avg,
    sleepHrMin: bpms[p5Index],
    coverageSufficient: true,
  );
}

SleepHeartRateBaseline calculateSleepHeartRateBaseline(
  List<double> nightlyAverageHeartRates,
) {
  final valid =
      nightlyAverageHeartRates.where((value) => value.isFinite).toList();
  if (valid.length < 10) {
    return SleepHeartRateBaseline(
      baselineSleepHr: null,
      isEstablished: false,
      validNights: valid.length,
    );
  }
  final windowStart = valid.length <= 30 ? 0 : valid.length - 30;
  final window = valid.sublist(windowStart);
  final sortedWindow = List<double>.from(window)..sort();
  return SleepHeartRateBaseline(
    baselineSleepHr: _median(sortedWindow),
    isEstablished: true,
    validNights: valid.length,
  );
}

SleepHeartRateDelta calculateSleepHeartRateDelta({
  required NightlyHeartRateMetrics nightly,
  required SleepHeartRateBaseline baseline,
}) {
  if (!nightly.coverageSufficient ||
      nightly.sleepHrAvg == null ||
      !baseline.isEstablished ||
      baseline.baselineSleepHr == null) {
    return SleepHeartRateDelta(
      deltaSleepHr: null,
      baselineEstablished: baseline.isEstablished,
      coverageSufficient: nightly.coverageSufficient,
    );
  }
  return SleepHeartRateDelta(
    deltaSleepHr: nightly.sleepHrAvg! - baseline.baselineSleepHr!,
    baselineEstablished: true,
    coverageSufficient: true,
  );
}

double _median(List<double> sortedValues) {
  if (sortedValues.isEmpty) return 0;
  final middle = sortedValues.length ~/ 2;
  if (sortedValues.length.isOdd) return sortedValues[middle];
  return (sortedValues[middle - 1] + sortedValues[middle]) / 2;
}
