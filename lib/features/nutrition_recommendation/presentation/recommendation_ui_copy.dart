import '../../../generated/app_localizations.dart';
import '../domain/confidence_models.dart';
import '../domain/recommendation_models.dart';

class RecommendationUiCopy {
  const RecommendationUiCopy._();

  static String confidenceLabel(
    AppLocalizations l10n,
    RecommendationConfidence confidence,
  ) {
    switch (confidence) {
      case RecommendationConfidence.notEnoughData:
        return l10n.adaptiveConfidenceNotEnoughData;
      case RecommendationConfidence.low:
        return l10n.adaptiveConfidenceLow;
      case RecommendationConfidence.medium:
        return l10n.adaptiveConfidenceMedium;
      case RecommendationConfidence.high:
        return l10n.adaptiveConfidenceHigh;
    }
  }

  static String dataBasisMessage(
    AppLocalizations l10n,
    NutritionRecommendation recommendation,
  ) {
    final flags = recommendation.inputSummary.qualityFlags;
    final sparseWeight = flags.contains('sparse_weight_logs');
    final sparseIntake = flags.contains('sparse_intake_logs');

    if (isPriorOnly(recommendation)) {
      return l10n.adaptiveRecommendationDataBasisHintPriorOnly;
    }
    if (sparseWeight && sparseIntake) {
      return l10n.adaptiveRecommendationDataBasisHintSparseWeightAndIntake;
    }
    if (sparseWeight) {
      return l10n.adaptiveRecommendationDataBasisHintSparseWeight;
    }
    if (sparseIntake) {
      return l10n.adaptiveRecommendationDataBasisHintSparseIntake;
    }
    return l10n.adaptiveRecommendationDataBasisHintDefault;
  }

  static String? warningMessage(
    AppLocalizations l10n,
    NutritionRecommendation recommendation,
  ) {
    final reasons = recommendation.warningState.warningReasons;
    if (reasons.contains('calorie_floor_applied')) {
      return l10n.adaptiveRecommendationWarningCalorieFloor;
    }
    if (reasons.contains('unresolved_food_calories')) {
      return l10n.adaptiveRecommendationWarningUnresolvedFood;
    }
    if (reasons.any((reason) => reason.startsWith('large_adjustment_'))) {
      return l10n.adaptiveRecommendationWarningLargeAdjustment;
    }
    if (reasons.contains('macro_distribution_constrained')) {
      return l10n.adaptiveRecommendationWarningMacroConstrained;
    }
    if (recommendation.warningState.warningLevel !=
        RecommendationWarningLevel.none) {
      return l10n.adaptiveRecommendationWarningConservative;
    }
    return null;
  }

  static bool isPriorOnly(NutritionRecommendation recommendation) {
    return recommendation.confidence ==
            RecommendationConfidence.notEnoughData ||
        recommendation.inputSummary.qualityFlags.contains(
          'onboarding_prior_only',
        );
  }
}
