class StatisticsDataQualityAssessment {
  final bool hasSufficientData;
  final String reasonHook;

  const StatisticsDataQualityAssessment({
    required this.hasSufficientData,
    required this.reasonHook,
  });
}

class StatisticsDataQualityPolicy {
  const StatisticsDataQualityPolicy._();

  static const StatisticsDataQualityPolicy instance =
      StatisticsDataQualityPolicy._();

  StatisticsDataQualityAssessment bodyNutritionInsight({
    required int spanDays,
    required int totalDays,
    required int weightDays,
    required int loggedCalorieDays,
  }) {
    final sufficient = spanDays >= 14 &&
        totalDays >= 14 &&
        weightDays >= 5 &&
        loggedCalorieDays >= 7;
    return StatisticsDataQualityAssessment(
      hasSufficientData: sufficient,
      reasonHook: sufficient
          ? 'quality:body-nutrition:sufficient'
          : 'quality:body-nutrition:insufficient',
    );
  }

  StatisticsDataQualityAssessment muscleDistribution({
    required int dataPointDays,
    required int spanDays,
  }) {
    final sufficient = dataPointDays >= 3 && spanDays >= 14;
    return StatisticsDataQualityAssessment(
      hasSufficientData: sufficient,
      reasonHook: sufficient
          ? 'quality:muscle-distribution:sufficient'
          : 'quality:muscle-distribution:insufficient',
    );
  }
}
