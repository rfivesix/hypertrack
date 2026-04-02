import 'dart:typed_data';

const int sleepRegularityMinutesPerDay = 1440;

class DailySleepWakeState {
  const DailySleepWakeState({
    required this.day,
    required this.sleepByMinute,
    required this.hasSleepData,
  });

  /// Calendar day anchor used for 24h-apart comparisons.
  ///
  /// Pipeline currently uses UTC day conventions for nightly keys.
  final DateTime day;

  /// 0 = wake, 1 = sleep for each minute in the day.
  final Uint8List sleepByMinute;

  /// True only when this day has enough observed sleep signal to be counted
  /// as a valid day in SRI computation.
  final bool hasSleepData;
}

class SleepRegularityIndexResult {
  const SleepRegularityIndexResult({
    required this.sri,
    required this.validDays,
    required this.available,
    required this.stable,
  });

  /// Probability of matching sleep/wake state 24h apart, 0..100.
  final double? sri;
  final int validDays;
  final bool available;
  final bool stable;
}

/// Calculates Sleep Regularity Index (SRI) using 1-minute epochs.
///
/// Evidence-backed concept:
/// - SRI is based on probability that sleep/wake state matches at time points
///   24 hours apart.
///
/// Implementation note:
/// - This implementation uses 1-minute binary sleep/wake vectors and returns
///   a 0..100 probability score.
SleepRegularityIndexResult calculateSleepRegularityIndex({
  required List<DailySleepWakeState> dailyStates,
  int minimumValidDays = 5,
  int stableValidDays = 7,
}) {
  final sorted = List<DailySleepWakeState>.from(dailyStates)
    ..sort((a, b) => a.day.compareTo(b.day));
  final valid = sorted.where((state) => state.hasSleepData).toList();
  final validDays = valid.length;
  if (validDays < minimumValidDays || valid.length < 2) {
    return SleepRegularityIndexResult(
      sri: null,
      validDays: validDays,
      available: false,
      stable: false,
    );
  }

  var matches = 0;
  var comparisons = 0;
  for (var i = 1; i < valid.length; i++) {
    final previousDay = valid[i - 1].day;
    final currentDay = valid[i].day;
    if (_calendarDayDistance(previousDay, currentDay) != 1) {
      // SRI relies on state matching at true 24h-apart time points.
      // Do not compare non-consecutive days.
      continue;
    }
    final previous = valid[i - 1].sleepByMinute;
    final current = valid[i].sleepByMinute;
    final length =
        previous.length < current.length ? previous.length : current.length;
    final comparedLength = length < sleepRegularityMinutesPerDay
        ? length
        : sleepRegularityMinutesPerDay;
    for (var minute = 0; minute < comparedLength; minute++) {
      if (previous[minute] == current[minute]) {
        matches += 1;
      }
    }
    comparisons += comparedLength;
  }

  if (comparisons <= 0) {
    return SleepRegularityIndexResult(
      sri: null,
      validDays: validDays,
      available: false,
      stable: false,
    );
  }

  final sri = (matches / comparisons) * 100.0;
  return SleepRegularityIndexResult(
    sri: sri.clamp(0, 100).toDouble(),
    validDays: validDays,
    available: true,
    stable: validDays >= stableValidDays,
  );
}

int _calendarDayDistance(DateTime a, DateTime b) {
  final aDay = DateTime.utc(a.year, a.month, a.day);
  final bDay = DateTime.utc(b.year, b.month, b.day);
  return bDay.difference(aDay).inDays;
}
