import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/util/muscle_analytics_utils.dart';

void main() {
  group('MuscleAnalyticsUtils', () {
    test('applies equivalent-set weighting and frequency threshold', () {
      final now = DateTime(2026, 3, 9);
      final data = MuscleAnalyticsUtils.buildSummary(
        now: now,
        daysBack: 30,
        weeksBack: 8,
        contributions: [
          {
            'day': DateTime(2026, 3, 1, 10),
            'muscleGroup': 'Chest',
            'equivalentSets': 1.0,
          },
          {
            'day': DateTime(2026, 3, 1, 10),
            'muscleGroup': 'Triceps',
            'equivalentSets': 0.5,
          },
          {
            'day': DateTime(2026, 3, 3, 11),
            'muscleGroup': 'Triceps',
            'equivalentSets': 0.5,
          },
          {
            'day': DateTime(2026, 3, 3, 11),
            'muscleGroup': 'Triceps',
            'equivalentSets': 0.5,
          },
        ],
      );

      final muscles =
          (data['muscles'] as List<dynamic>).cast<Map<String, dynamic>>();
      final chest = muscles.firstWhere((m) => m['muscleGroup'] == 'Chest');
      final triceps = muscles.firstWhere((m) => m['muscleGroup'] == 'Triceps');

      expect((chest['equivalentSets'] as num).toDouble(), 1.0);
      expect((triceps['equivalentSets'] as num).toDouble(), 1.5);

      expect(chest['trainedDays'], 1);
      expect(triceps['trainedDays'], 1);
    });

    test('suppresses low-quality guidance data', () {
      final now = DateTime(2026, 3, 9);
      final data = MuscleAnalyticsUtils.buildSummary(
        now: now,
        daysBack: 30,
        weeksBack: 8,
        contributions: [
          {
            'day': DateTime(2026, 3, 1),
            'muscleGroup': 'Chest',
            'equivalentSets': 2.0,
          },
          {
            'day': DateTime(2026, 3, 3),
            'muscleGroup': 'Back',
            'equivalentSets': 2.0,
          },
        ],
      );

      expect(data['dataQualityOk'], isFalse);
      expect(data['undertrained'], isEmpty);
    });

    test('finds lower-emphasis muscles when quality is sufficient', () {
      final now = DateTime(2026, 3, 30);
      final data = MuscleAnalyticsUtils.buildSummary(
        now: now,
        daysBack: 30,
        weeksBack: 8,
        contributions: [
          {
            'day': DateTime(2026, 3, 1),
            'muscleGroup': 'Chest',
            'equivalentSets': 3.0,
          },
          {
            'day': DateTime(2026, 3, 8),
            'muscleGroup': 'Chest',
            'equivalentSets': 3.0,
          },
          {
            'day': DateTime(2026, 3, 15),
            'muscleGroup': 'Chest',
            'equivalentSets': 3.0,
          },
          {
            'day': DateTime(2026, 3, 22),
            'muscleGroup': 'Back',
            'equivalentSets': 2.0,
          },
          {
            'day': DateTime(2026, 3, 22),
            'muscleGroup': 'Legs',
            'equivalentSets': 0.8,
          },
          {
            'day': DateTime(2026, 3, 24),
            'muscleGroup': 'Legs',
            'equivalentSets': 0.8,
          },
        ],
      );

      expect(data['dataQualityOk'], isTrue);
      final undertrained =
          (data['undertrained'] as List<dynamic>).cast<String>();
      expect(undertrained, contains('Legs'));
    });
  });
}
