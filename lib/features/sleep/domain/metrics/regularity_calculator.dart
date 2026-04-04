import 'dart:math' as math;

class RegularityNightInput {
  const RegularityNightInput({
    required this.nightDate,
    required this.bedtimeMinutes,
    required this.wakeMinutes,
  });

  final DateTime nightDate;
  final int bedtimeMinutes;
  final int wakeMinutes;
}

enum RegularityDataState { insufficientData, partialLowConfidence, complete }

class RegularityMetrics {
  const RegularityMetrics({
    required this.state,
    required this.validNights,
    this.averageBedtimeMinutes,
    this.averageWakeMinutes,
    this.bedSdMinutes,
    this.wakeSdMinutes,
    this.midSdMinutes,
    this.regularityMinutes,
  });

  final RegularityDataState state;
  final int validNights;
  final double? averageBedtimeMinutes;
  final double? averageWakeMinutes;
  final double? bedSdMinutes;
  final double? wakeSdMinutes;
  final double? midSdMinutes;
  final double? regularityMinutes;
}

RegularityMetrics calculateRegularityMetrics(
  List<RegularityNightInput> nights,
) {
  final sorted = List<RegularityNightInput>.from(nights)
    ..sort((a, b) => a.nightDate.compareTo(b.nightDate));
  final window =
      sorted.length <= 7 ? sorted : sorted.sublist(sorted.length - 7);
  final validCount = window.length;
  if (validCount < 3) {
    return RegularityMetrics(
      state: RegularityDataState.insufficientData,
      validNights: validCount,
    );
  }

  final bedtimes =
      window.map((night) => night.bedtimeMinutes.toDouble()).toList();
  final wakeTimes =
      window.map((night) => night.wakeMinutes.toDouble()).toList();
  final mids = window.map((night) {
    final wake = _unwrapWake(
      bedtimeMinutes: night.bedtimeMinutes,
      wakeMinutes: night.wakeMinutes,
    );
    return ((night.bedtimeMinutes + wake) / 2) % 1440;
  }).toList();

  final bedSd = circularStandardDeviationMinutes(bedtimes);
  final wakeSd = circularStandardDeviationMinutes(wakeTimes);
  return RegularityMetrics(
    state: validCount == 7
        ? RegularityDataState.complete
        : RegularityDataState.partialLowConfidence,
    validNights: validCount,
    averageBedtimeMinutes: circularMeanMinutes(bedtimes),
    averageWakeMinutes: circularMeanMinutes(wakeTimes),
    bedSdMinutes: bedSd,
    wakeSdMinutes: wakeSd,
    midSdMinutes: circularStandardDeviationMinutes(mids),
    regularityMinutes: 0.5 * bedSd + 0.5 * wakeSd,
  );
}

double circularMeanMinutes(List<double> values) {
  if (values.isEmpty) return 0;
  var sinSum = 0.0;
  var cosSum = 0.0;
  for (final value in values) {
    final angle = (_normalizeMinutes(value) / 1440.0) * 2 * math.pi;
    sinSum += math.sin(angle);
    cosSum += math.cos(angle);
  }
  final meanAngle = math.atan2(sinSum / values.length, cosSum / values.length);
  var normalized = (meanAngle / (2 * math.pi)) * 1440.0;
  if (normalized < 0) normalized += 1440.0;
  return normalized;
}

double circularStandardDeviationMinutes(List<double> values) {
  if (values.length <= 1) return 0;
  var sinSum = 0.0;
  var cosSum = 0.0;
  for (final value in values) {
    final angle = (_normalizeMinutes(value) / 1440.0) * 2 * math.pi;
    sinSum += math.sin(angle);
    cosSum += math.cos(angle);
  }
  final r = math.sqrt(sinSum * sinSum + cosSum * cosSum) / values.length;
  if (r <= 0) return 720.0;
  final stdRadians = math.sqrt(-2 * math.log(r));
  return (stdRadians / (2 * math.pi)) * 1440.0;
}

double _normalizeMinutes(double value) => ((value % 1440.0) + 1440.0) % 1440.0;

int _unwrapWake({required int bedtimeMinutes, required int wakeMinutes}) {
  var wake = wakeMinutes;
  while (wake <= bedtimeMinutes) {
    wake += 1440;
  }
  return wake;
}
