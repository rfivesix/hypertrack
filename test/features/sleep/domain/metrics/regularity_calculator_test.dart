import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/domain/metrics/regularity_calculator.dart';

void main() {
  test('returns insufficient-data state with fewer than 3 nights', () {
    final result = calculateRegularityMetrics([
      RegularityNightInput(
        nightDate: DateTime.utc(2026, 3, 1),
        bedtimeMinutes: 23 * 60,
        wakeMinutes: 7 * 60,
      ),
      RegularityNightInput(
        nightDate: DateTime.utc(2026, 3, 2),
        bedtimeMinutes: 23 * 60 + 30,
        wakeMinutes: 7 * 60 + 15,
      ),
    ]);
    expect(result.state, RegularityDataState.insufficientData);
    expect(result.regularityMinutes, isNull);
  });

  test('handles midnight wrap and partial state with 3-6 nights', () {
    final result = calculateRegularityMetrics([
      RegularityNightInput(
        nightDate: DateTime.utc(2026, 3, 1),
        bedtimeMinutes: 23 * 60 + 30,
        wakeMinutes: 6 * 60 + 30,
      ),
      RegularityNightInput(
        nightDate: DateTime.utc(2026, 3, 2),
        bedtimeMinutes: 15,
        wakeMinutes: 6 * 60 + 20,
      ),
      RegularityNightInput(
        nightDate: DateTime.utc(2026, 3, 3),
        bedtimeMinutes: 23 * 60 + 50,
        wakeMinutes: 6 * 60 + 40,
      ),
    ]);
    expect(result.state, RegularityDataState.partialLowConfidence);
    expect(result.averageBedtimeMinutes, isNotNull);
    expect(result.regularityMinutes, isNotNull);
  });
}
