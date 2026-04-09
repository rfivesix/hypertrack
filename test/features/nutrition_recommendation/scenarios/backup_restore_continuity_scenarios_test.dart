import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';

import 'scenario_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive nutrition backup/restore continuity scenarios', () {
    test('mid-history backup/restore preserves adaptive continuity', () async {
      const totalWeeks = 12;
      const splitWeeks = 6;
      final firstDueWeek = DateTime(2026, 2, 2);
      final historyStart = firstDueWeek.subtract(const Duration(days: 35));
      final totalHistoryDays = 35 + (totalWeeks * 7);
      final preRestoreHistoryDays = 35 + (splitWeeks * 7);

      final controlHarness = await AdaptiveScenarioHarness.create();
      final controlWeeks = await (() async {
        try {
          await controlHarness.seedDailyHistory(
            startDay: historyStart,
            dayCount: totalHistoryDays,
            startWeightKg: 91,
            weeklyWeightChangeKg: -0.44,
            averageIntakeCalories: 2340,
          );
          await controlHarness.setGoalForDay(
            goal: BodyweightGoal.loseWeight,
            targetRateKgPerWeek: -0.5,
            day: firstDueWeek,
          );
          return await controlHarness.runDueWeekSeries(
            firstDueWeekStart: firstDueWeek,
            weekCount: totalWeeks,
          );
        } finally {
          await controlHarness.dispose();
        }
      })();

      final restoreHarness = await AdaptiveScenarioHarness.create();
      addTearDown(restoreHarness.dispose);

      await restoreHarness.seedDailyHistory(
        startDay: historyStart,
        dayCount: preRestoreHistoryDays,
        startWeightKg: 91,
        weeklyWeightChangeKg: -0.44,
        averageIntakeCalories: 2340,
      );
      await restoreHarness.setGoalForDay(
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -0.5,
        day: firstDueWeek,
      );

      final beforeRestoreWeeks = await restoreHarness.runDueWeekSeries(
        firstDueWeekStart: firstDueWeek,
        weekCount: splitWeeks,
      );

      final beforeSnapshot =
          await restoreHarness.repository.getLatestRecommendationSnapshot();
      final beforeState =
          await restoreHarness.repository.getLatestEstimatorState();
      final beforePhase =
          await restoreHarness.repository.getDietPhaseTrackingState();

      expect(beforeSnapshot, isNotNull);
      expect(beforeState, isNotNull);
      expect(beforePhase, isNotNull);

      final payload = await restoreHarness.createBackupPayload();
      final userPrefs =
          (payload['userPreferences'] as Map).cast<String, dynamic>();
      expect(userPrefs['adaptive_nutrition_recommendation.latest_snapshot'],
          isNotNull);
      expect(
          userPrefs['adaptive_nutrition_recommendation.latest_recursive_state'],
          isNotNull);
      expect(
          userPrefs[
              'adaptive_nutrition_recommendation.diet_phase_tracking_state'],
          isNotNull);

      final imported = await restoreHarness.restoreFromBackupPayload(payload);
      expect(imported, isTrue);
      await restoreHarness.restartAdaptiveLayer();

      final restoredSnapshot =
          await restoreHarness.repository.getLatestRecommendationSnapshot();
      final restoredState =
          await restoreHarness.repository.getLatestEstimatorState();
      final restoredPhase =
          await restoreHarness.repository.getDietPhaseTrackingState();

      expect(restoredSnapshot, isNotNull);
      expect(restoredState, isNotNull);
      expect(restoredPhase, isNotNull);
      expect(
        _stableJson(restoredSnapshot!.toJson()),
        _stableJson(beforeSnapshot!.toJson()),
      );
      expect(
        _stableJson(restoredState!.toJson()),
        _stableJson(beforeState!.toJson()),
      );
      expect(
        _stableJson(restoredPhase!.toJson()),
        _stableJson(beforePhase!.toJson()),
      );

      final continuationStart =
          historyStart.add(Duration(days: preRestoreHistoryDays));
      final continuationDays = totalHistoryDays - preRestoreHistoryDays;
      await restoreHarness.seedDailyHistory(
        startDay: continuationStart,
        dayCount: continuationDays,
        startWeightKg: 91 + ((-0.44 * preRestoreHistoryDays) / 7),
        weeklyWeightChangeKg: -0.44,
        averageIntakeCalories: 2340,
      );

      final continuationFirstDueWeek =
          firstDueWeek.add(const Duration(days: splitWeeks * 7));
      final afterRestoreWeeks = await restoreHarness.runDueWeekSeries(
        firstDueWeekStart: continuationFirstDueWeek,
        weekCount: totalWeeks - splitWeeks,
      );

      final combinedRestoreWeeks = <WeekScenarioOutput>[
        ...beforeRestoreWeeks,
        ...afterRestoreWeeks,
      ];

      expect(combinedRestoreWeeks.length, controlWeeks.length);
      expectDueWeekAnchorsStable(
        combinedRestoreWeeks,
        firstDueWeekStart: firstDueWeek,
      );

      for (var i = 0; i < controlWeeks.length; i++) {
        final restored = combinedRestoreWeeks[i];
        final control = controlWeeks[i];

        expect(restored.dueWeekKey, control.dueWeekKey);
        expect(
          _stableJson(restored.recommendation.toJson()),
          _stableJson(control.recommendation.toJson()),
          reason: 'Recommendation mismatch after restore at week index $i',
        );
        expect(
          _stableJson(restored.maintenanceEstimate.toJson()),
          _stableJson(control.maintenanceEstimate.toJson()),
          reason:
              'Maintenance estimate mismatch after restore at week index $i',
        );
        expect(
          _stableJson(restored.recursiveState.toJson()),
          _stableJson(control.recursiveState.toJson()),
          reason: 'Recursive state mismatch after restore at week index $i',
        );
        expect(
          _stableJson(restored.phaseState.toJson()),
          _stableJson(control.phaseState.toJson()),
          reason: 'Phase state mismatch after restore at week index $i',
        );
      }

      final firstWeekAfterRestore = afterRestoreWeeks.first;
      expect(
        firstWeekAfterRestore.maintenanceEstimate.priorSource,
        BayesianPriorSource.chainedPosterior,
      );
      expect(
        firstWeekAfterRestore.maintenanceEstimate.priorMeanUsedCalories,
        closeTo(
          beforeRestoreWeeks
              .last.maintenanceEstimate.posteriorMaintenanceCalories,
          0.001,
        ),
      );
    });
  });
}

String _stableJson(Object? value) {
  return jsonEncode(_roundDeep(value));
}

Object? _roundDeep(Object? value) {
  if (value is num) {
    return (value * 1e9).round() / 1e9;
  }
  if (value is Map) {
    final rounded = <String, Object?>{};
    for (final entry in value.entries) {
      rounded[entry.key.toString()] = _roundDeep(entry.value);
    }
    return rounded;
  }
  if (value is List) {
    return value.map(_roundDeep).toList(growable: false);
  }
  return value;
}
