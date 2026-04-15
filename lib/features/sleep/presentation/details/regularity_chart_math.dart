import 'dart:math' as math;

int unwrapWakeMinutes({required int bedtimeMinutes, required int wakeMinutes}) {
  final bed = _normalizeMinutes(bedtimeMinutes);
  var wake = _normalizeMinutes(wakeMinutes);
  if (wake <= bed) {
    wake += 1440;
  }
  return wake;
}

({int startMinutes, int endMinutes}) regularityToSleepWindowMinutes({
  required int bedtimeMinutes,
  required int wakeMinutes,
}) {
  final bed = _normalizeMinutes(bedtimeMinutes);
  final wake = _normalizeMinutes(wakeMinutes);

  final sameDateAsWake = bed <= wake;
  final startMinutes = sameDateAsWake ? bed + 1440 : bed;
  final endMinutes = wake + 1440;
  return (startMinutes: startMinutes, endMinutes: endMinutes);
}

int circularAverageMinutes(Iterable<int> minutesValues) {
  final values = minutesValues.toList(growable: false);
  if (values.isEmpty) return 0;

  double sumSin = 0;
  double sumCos = 0;
  for (final value in values) {
    final angle = (_normalizeMinutes(value) / 1440.0) * 2 * math.pi;
    sumSin += math.sin(angle);
    sumCos += math.cos(angle);
  }
  final avgAngle = math.atan2(sumSin / values.length, sumCos / values.length);
  var normalized = (avgAngle / (2 * math.pi)) * 1440.0;
  if (normalized < 0) normalized += 1440;
  return normalized.round();
}

int _normalizeMinutes(int value) => ((value % 1440) + 1440) % 1440;
