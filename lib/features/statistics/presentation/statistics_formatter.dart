import 'package:flutter/material.dart';
import '../../../generated/app_localizations.dart';
import '../domain/recovery_domain_service.dart';
import '../../../util/body_nutrition_analytics_utils.dart';

/// Marker interface for statistics presentation formatters.
abstract class StatisticsFormatter {}

class StatisticsPresentationFormatter implements StatisticsFormatter {
  static bool isOtherCategoryLabel(String? label) {
    if (label == null) return false;
    final normalized = label.trim().toLowerCase();
    return normalized == 'other' || normalized == 'others';
  }

  static String formatWeight(num weight) {
    final value = weight.toDouble();
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  static String compactNumber(num value) {
    final n = value.toDouble();
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toStringAsFixed(n % 1 == 0 ? 0 : 1);
  }

  static String recoveryOverallLabel(AppLocalizations l10n, String? state) {
    return switch (state) {
      RecoveryDomainService.overallMostlyRecovered =>
        l10n.recoveryOverallMostlyRecovered,
      RecoveryDomainService.overallMixedRecovery => l10n.recoveryOverallMixed,
      RecoveryDomainService.overallSeveralRecovering =>
        l10n.recoveryOverallSeveralRecovering,
      _ => l10n.recoveryOverallInsufficientData,
    };
  }

  static Color recoveryOverallColor(BuildContext context, String? state) {
    return switch (state) {
      RecoveryDomainService.overallSeveralRecovering => Colors.orange,
      RecoveryDomainService.overallMixedRecovery => Colors.blue,
      RecoveryDomainService.overallMostlyRecovered => Colors.green,
      _ => Theme.of(context).colorScheme.outline,
    };
  }

  static String recoveryStateLabel(AppLocalizations l10n, String state) {
    return switch (state) {
      RecoveryDomainService.stateRecovering => l10n.recoveryStateRecovering,
      RecoveryDomainService.stateReady => l10n.recoveryStateReady,
      RecoveryDomainService.stateFresh => l10n.recoveryStateFresh,
      _ => l10n.recoveryStateUnknown,
    };
  }

  static Color recoveryStateColor(BuildContext context, String state) {
    return switch (state) {
      RecoveryDomainService.stateRecovering => Colors.orange,
      RecoveryDomainService.stateReady => Colors.blue,
      RecoveryDomainService.stateFresh => Colors.green,
      _ => Theme.of(context).colorScheme.outline,
    };
  }

  static String bodyNutritionInsightLabel(
    AppLocalizations l10n,
    BodyNutritionInsightType insightType,
  ) {
    return switch (insightType) {
      BodyNutritionInsightType.stableWeightCaloriesUp =>
        l10n.analyticsInsightStableWeightCaloriesUp,
      BodyNutritionInsightType.weightUpCaloriesUp =>
        l10n.analyticsInsightWeightUpCaloriesUp,
      BodyNutritionInsightType.caloriesDownWeightNotYetChanged =>
        l10n.analyticsInsightCaloriesDownWeightStable,
      BodyNutritionInsightType.weightDownCaloriesDown =>
        l10n.analyticsInsightWeightDownCaloriesDown,
      BodyNutritionInsightType.mixed => l10n.analyticsInsightMixedPattern,
      BodyNutritionInsightType.notEnoughData =>
        l10n.analyticsInsightNotEnoughData,
    };
  }

  static String bodyNutritionTrendDirectionLabel(
    AppLocalizations l10n,
    BodyNutritionTrendDirection direction,
  ) {
    return switch (direction) {
      BodyNutritionTrendDirection.rising => l10n.analyticsTrendRising,
      BodyNutritionTrendDirection.falling => l10n.analyticsTrendFalling,
      BodyNutritionTrendDirection.stable => l10n.analyticsTrendStable,
      BodyNutritionTrendDirection.unclear => l10n.analyticsTrendUnclear,
    };
  }

  static String bodyNutritionRelationshipLabel(
    AppLocalizations l10n,
    BodyNutritionRelationshipType relationship,
  ) {
    return switch (relationship) {
      BodyNutritionRelationshipType.alignedCutLike =>
        l10n.analyticsRelationshipAlignedCut,
      BodyNutritionRelationshipType.alignedBulkLike =>
        l10n.analyticsRelationshipAlignedBulk,
      BodyNutritionRelationshipType.stableMaintenanceLike =>
        l10n.analyticsRelationshipStableMaintenance,
      BodyNutritionRelationshipType.mixedOrUnclear =>
        l10n.analyticsRelationshipMixed,
      BodyNutritionRelationshipType.insufficientData =>
        l10n.analyticsRelationshipInsufficient,
    };
  }

  static String bodyNutritionConfidenceLabel(
    AppLocalizations l10n,
    BodyNutritionConfidence confidence,
  ) {
    return switch (confidence) {
      BodyNutritionConfidence.high => l10n.analyticsHighConfidenceLabel,
      BodyNutritionConfidence.moderate => l10n.analyticsModerateConfidenceLabel,
      BodyNutritionConfidence.low => l10n.analyticsLowConfidenceLabel,
      BodyNutritionConfidence.insufficient =>
        l10n.analyticsInsufficientConfidenceLabel,
    };
  }

  static String muscleGuidanceLabel(
    AppLocalizations l10n,
    bool dataQualityOk,
    Iterable<String> undertrained,
  ) {
    if (!dataQualityOk) {
      return l10n.analyticsKeepTrackingUnlockInsights;
    }
    if (undertrained.isEmpty) {
      return l10n.analyticsGuidanceNoClearWeakPoint;
    }
    return l10n.analyticsGuidanceLowerEmphasis(undertrained.join(', '));
  }
}
