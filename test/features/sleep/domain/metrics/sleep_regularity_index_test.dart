import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/domain/metrics/sleep_regularity_index.dart';

void main() {
  DailySleepWakeState dayState(
    DateTime day, {
    required int sleepStartMinute,
    required int sleepEndMinuteExclusive,
  }) {
    final vector = Uint8List(sleepRegularityMinutesPerDay);
    final start = sleepStartMinute.clamp(0, sleepRegularityMinutesPerDay - 1);
    final end =
        sleepEndMinuteExclusive.clamp(0, sleepRegularityMinutesPerDay).toInt();
    for (var minute = start; minute < end; minute++) {
      vector[minute] = 1;
    }
    return DailySleepWakeState(
      day: DateTime(day.year, day.month, day.day),
      sleepByMinute: vector,
      hasSleepData: true,
    );
  }

  test('returns unavailable with fewer than five valid days', () {
    final result = calculateSleepRegularityIndex(
      dailyStates: [
        dayState(DateTime.utc(2026, 3, 1),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 2),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 3),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 4),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
      ],
    );
    expect(result.available, isFalse);
    expect(result.stable, isFalse);
    expect(result.validDays, 4);
    expect(result.sri, isNull);
  });

  test('returns 100 for identical schedules across five days', () {
    final result = calculateSleepRegularityIndex(
      dailyStates: [
        dayState(DateTime.utc(2026, 3, 1),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 2),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 3),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 4),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 5),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
      ],
    );
    expect(result.available, isTrue);
    expect(result.stable, isFalse);
    expect(result.validDays, 5);
    expect(result.sri, closeTo(100, 0.0001));
  });

  test('marks >=7 valid days as stable and yields bounded 0..100 score', () {
    final result = calculateSleepRegularityIndex(
      dailyStates: [
        dayState(DateTime.utc(2026, 3, 1),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 2),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 3),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 4),
            sleepStartMinute: 1290, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 5),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 6),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 7),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
      ],
    );
    expect(result.available, isTrue);
    expect(result.stable, isTrue);
    expect(result.validDays, 7);
    expect(result.sri, isNotNull);
    expect(result.sri!, inInclusiveRange(0, 100));
    expect(result.sri!, lessThan(100));
  });

  test('requires true 24h pairs and skips non-consecutive days', () {
    final result = calculateSleepRegularityIndex(
      dailyStates: [
        dayState(DateTime.utc(2026, 3, 1),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 3),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 5),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 7),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
        dayState(DateTime.utc(2026, 3, 9),
            sleepStartMinute: 1320, sleepEndMinuteExclusive: 1440),
      ],
    );
    expect(result.validDays, 5);
    expect(result.available, isFalse);
    expect(result.stable, isFalse);
    expect(result.sri, isNull);
  });
}
