import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/statistics/domain/statistics_data_quality_policy.dart';

void main() {
  group('StatisticsDataQualityPolicy.bodyNutritionInsight', () {
    test('is sufficient exactly at minimum thresholds', () {
      final result = StatisticsDataQualityPolicy.instance.bodyNutritionInsight(
        spanDays: 14,
        totalDays: 14,
        weightDays: 5,
        loggedCalorieDays: 7,
      );

      expect(result.hasSufficientData, isTrue);
      expect(result.reasonHook, 'quality:body-nutrition:sufficient');
    });

    test('is insufficient when any threshold is missed', () {
      final cases = [
        StatisticsDataQualityPolicy.instance.bodyNutritionInsight(
          spanDays: 13,
          totalDays: 14,
          weightDays: 5,
          loggedCalorieDays: 7,
        ),
        StatisticsDataQualityPolicy.instance.bodyNutritionInsight(
          spanDays: 14,
          totalDays: 13,
          weightDays: 5,
          loggedCalorieDays: 7,
        ),
        StatisticsDataQualityPolicy.instance.bodyNutritionInsight(
          spanDays: 14,
          totalDays: 14,
          weightDays: 4,
          loggedCalorieDays: 7,
        ),
        StatisticsDataQualityPolicy.instance.bodyNutritionInsight(
          spanDays: 14,
          totalDays: 14,
          weightDays: 5,
          loggedCalorieDays: 6,
        ),
      ];

      for (final result in cases) {
        expect(result.hasSufficientData, isFalse);
        expect(result.reasonHook, 'quality:body-nutrition:insufficient');
      }
    });
  });

  group('StatisticsDataQualityPolicy.muscleDistribution', () {
    test('is sufficient at threshold and insufficient just below', () {
      final sufficient =
          StatisticsDataQualityPolicy.instance.muscleDistribution(
        dataPointDays: 3,
        spanDays: 14,
      );
      final lowDataPoints =
          StatisticsDataQualityPolicy.instance.muscleDistribution(
        dataPointDays: 2,
        spanDays: 14,
      );
      final lowSpan = StatisticsDataQualityPolicy.instance.muscleDistribution(
        dataPointDays: 3,
        spanDays: 13,
      );

      expect(sufficient.hasSufficientData, isTrue);
      expect(sufficient.reasonHook, 'quality:muscle-distribution:sufficient');

      expect(lowDataPoints.hasSufficientData, isFalse);
      expect(
          lowDataPoints.reasonHook, 'quality:muscle-distribution:insufficient');

      expect(lowSpan.hasSufficientData, isFalse);
      expect(lowSpan.reasonHook, 'quality:muscle-distribution:insufficient');
    });
  });
}
