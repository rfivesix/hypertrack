import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_scheduler.dart';

void main() {
  group('RecommendationScheduler', () {
    test('dueWeekKeyFor anchors week to Monday', () {
      expect(
        RecommendationScheduler.dueWeekKeyFor(DateTime(2026, 4, 6, 9, 0)),
        '2026-04-06',
      );
      expect(
        RecommendationScheduler.dueWeekKeyFor(DateTime(2026, 4, 7, 9, 0)),
        '2026-04-06',
      );
      expect(
        RecommendationScheduler.dueWeekKeyFor(DateTime(2026, 4, 12, 23, 0)),
        '2026-04-06',
      );
      expect(
        RecommendationScheduler.dueWeekKeyFor(DateTime(2026, 4, 13, 0, 1)),
        '2026-04-13',
      );
    });

    test('shouldGenerateForWeek enforces one recommendation per due week', () {
      expect(
        RecommendationScheduler.shouldGenerateForWeek(
          dueWeekKey: '2026-04-06',
          lastGeneratedDueWeekKey: null,
        ),
        isTrue,
      );
      expect(
        RecommendationScheduler.shouldGenerateForWeek(
          dueWeekKey: '2026-04-06',
          lastGeneratedDueWeekKey: '2026-04-06',
        ),
        isFalse,
      );
      expect(
        RecommendationScheduler.shouldGenerateForWeek(
          dueWeekKey: '2026-04-13',
          lastGeneratedDueWeekKey: '2026-04-06',
        ),
        isTrue,
      );
    });

    test('stableWindowEndDayForDueWeek stays fixed within the same due week',
        () {
      expect(
        RecommendationScheduler.stableWindowEndDayForDueWeek(
          DateTime(2026, 4, 6, 0, 1),
        ),
        DateTime(2026, 4, 5),
      );
      expect(
        RecommendationScheduler.stableWindowEndDayForDueWeek(
          DateTime(2026, 4, 8, 18, 30),
        ),
        DateTime(2026, 4, 5),
      );
      expect(
        RecommendationScheduler.stableWindowEndDayForDueWeek(
          DateTime(2026, 4, 12, 23, 59),
        ),
        DateTime(2026, 4, 5),
      );
      expect(
        RecommendationScheduler.stableWindowEndDayForDueWeek(
          DateTime(2026, 4, 13, 0, 1),
        ),
        DateTime(2026, 4, 12),
      );
    });
  });
}
