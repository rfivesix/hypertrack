import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/presentation/details/regularity_chart_math.dart';

void main() {
  test('unwrapWakeMinutes wraps midnight correctly', () {
    expect(
      unwrapWakeMinutes(bedtimeMinutes: 23 * 60 + 30, wakeMinutes: 6 * 60 + 15),
      24 * 60 + 6 * 60 + 15,
    );
  });

  test('regularityToSleepWindowMinutes keeps evening bedtimes on prior day',
      () {
    final window = regularityToSleepWindowMinutes(
      bedtimeMinutes: 23 * 60 + 30,
      wakeMinutes: 6 * 60 + 15,
    );
    expect(window.startMinutes, 23 * 60 + 30);
    expect(window.endMinutes, 24 * 60 + 6 * 60 + 15);
  });

  test('regularityToSleepWindowMinutes shifts after-midnight bedtimes', () {
    final window = regularityToSleepWindowMinutes(
      bedtimeMinutes: 1 * 60 + 10,
      wakeMinutes: 8 * 60 + 5,
    );
    expect(window.startMinutes, 24 * 60 + 1 * 60 + 10);
    expect(window.endMinutes, 24 * 60 + 8 * 60 + 5);
  });

  test('circularAverageMinutes handles around-midnight cluster', () {
    final avg = circularAverageMinutes([
      23 * 60 + 45,
      0 * 60 + 10,
      23 * 60 + 55,
    ]);
    expect(avg == 0 || avg > 23 * 60 + 30, isTrue);
  });
}
