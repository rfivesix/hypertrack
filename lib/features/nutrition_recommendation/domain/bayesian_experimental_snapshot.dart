import 'bayesian_tdee_estimator.dart';
import 'recommendation_models.dart';

class BayesianExperimentalRecommendationSnapshot {
  static const int currentSnapshotVersion = 1;

  final NutritionRecommendation recommendation;
  final BayesianMaintenanceEstimate maintenanceEstimate;
  final String dueWeekKey;
  final String algorithmVersion;
  final int snapshotVersion;

  const BayesianExperimentalRecommendationSnapshot({
    required this.recommendation,
    required this.maintenanceEstimate,
    required this.dueWeekKey,
    required this.algorithmVersion,
    this.snapshotVersion = currentSnapshotVersion,
  });

  /// Single source of truth for snapshot generation time.
  DateTime get generatedAt => recommendation.generatedAt;

  bool get isCoherent {
    final recommendationDueWeekKey = recommendation.dueWeekKey;
    final estimateDueWeekKey = maintenanceEstimate.dueWeekKey;

    if (dueWeekKey.isEmpty) {
      return false;
    }
    if (recommendationDueWeekKey == null || recommendationDueWeekKey.isEmpty) {
      return false;
    }
    if (estimateDueWeekKey == null || estimateDueWeekKey.isEmpty) {
      return false;
    }
    if (recommendationDueWeekKey != dueWeekKey) {
      return false;
    }
    if (estimateDueWeekKey != dueWeekKey) {
      return false;
    }
    if (recommendation.algorithmVersion != algorithmVersion) {
      return false;
    }

    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'snapshotVersion': snapshotVersion,
      'dueWeekKey': dueWeekKey,
      'algorithmVersion': algorithmVersion,
      'recommendation': recommendation.toJson(),
      'maintenanceEstimate': maintenanceEstimate.toJson(),
    };
  }

  factory BayesianExperimentalRecommendationSnapshot.fromJson(
    Map<String, dynamic> json,
  ) {
    final recommendationRaw =
        (json['recommendation'] as Map?)?.cast<String, dynamic>();
    final maintenanceEstimateRaw =
        (json['maintenanceEstimate'] as Map?)?.cast<String, dynamic>();

    if (recommendationRaw == null || maintenanceEstimateRaw == null) {
      throw const FormatException(
        'Invalid Bayesian experimental snapshot payload.',
      );
    }

    final recommendation = NutritionRecommendation.fromJson(recommendationRaw);
    final maintenanceEstimate =
        BayesianMaintenanceEstimate.fromJson(maintenanceEstimateRaw);

    final explicitDueWeekKey = (json['dueWeekKey'] as String?)?.trim();
    final derivedDueWeekKey =
        recommendation.dueWeekKey?.trim() ?? maintenanceEstimate.dueWeekKey;
    final dueWeekKey = (explicitDueWeekKey?.isNotEmpty ?? false)
        ? explicitDueWeekKey!
        : (derivedDueWeekKey?.trim() ?? '');

    final explicitAlgorithmVersion =
        (json['algorithmVersion'] as String?)?.trim();
    final algorithmVersion = (explicitAlgorithmVersion?.isNotEmpty ?? false)
        ? explicitAlgorithmVersion!
        : recommendation.algorithmVersion;

    final snapshot = BayesianExperimentalRecommendationSnapshot(
      recommendation: recommendation,
      maintenanceEstimate: maintenanceEstimate,
      dueWeekKey: dueWeekKey,
      algorithmVersion: algorithmVersion,
      snapshotVersion:
          (json['snapshotVersion'] as int?) ?? currentSnapshotVersion,
    );

    if (!snapshot.isCoherent) {
      throw const FormatException(
        'Incoherent Bayesian experimental snapshot payload.',
      );
    }

    return snapshot;
  }
}
