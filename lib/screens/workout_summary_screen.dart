// lib/screens/workout_summary_screen.dart

import 'package:flutter/material.dart';
import '../data/workout_database_helper.dart';
import '../features/sharing/share_service.dart';
import '../generated/app_localizations.dart';
import '../models/set_log.dart';
import '../models/workout_log.dart';
import '../services/health/workout_heart_rate_models.dart';
import '../services/health/workout_heart_rate_service.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import '../widgets/workout_summary_bar.dart';

/// A screen providing a summary of a recently finished workout session.
///
/// Typically shown after [LiveWorkoutScreen] ends, it highlights key metrics
/// like total volume, duration, and exercise-specific results.
class WorkoutSummaryScreen extends StatefulWidget {
  /// The unique identifier of the summarized workout log.
  final int logId;

  const WorkoutSummaryScreen({super.key, required this.logId});

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  bool _isLoading = true;
  WorkoutLog? _log;
  final WorkoutHeartRateService _heartRateService =
      const WorkoutHeartRateService();
  WorkoutHeartRateSummary? _heartRateSummary;
  static const ShareService _shareService = ShareService();

  // Store one formatted string per exercise,
  // because cardio and strength use different units.
  Map<String, String> _summaryPerExercise = {};

  /// Stores new records achieved in this session per exercise.
  Map<String, List<String>> _newRecordsPerExercise = {};

  @override
  void initState() {
    super.initState();
    _loadWorkoutDetails();
  }

  Future<void> _loadWorkoutDetails() async {
    final db = WorkoutDatabaseHelper.instance;
    final data = await db.getWorkoutLogById(widget.logId);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    if (data != null) {
      final heartRateFuture = _heartRateService.loadForWorkoutWindow(
        startTime: data.startTime,
        endTime: data.endTime,
      );
      final Map<String, String> summaryMap = {};
      final Map<String, List<String>> newRecordsMap = {};

      final groupedSets = <String, List<SetLog>>{};
      for (var set in data.sets) {
        groupedSets.putIfAbsent(set.exerciseName, () => []).add(set);
      }

      for (var entry in groupedSets.entries) {
        final name = entry.key;
        final sets = entry.value;

        final exercise = await db.resolveExerciseForSetLog(sets.first);
        final isCardio = exercise?.categoryName.toLowerCase() == 'cardio';

        if (isCardio) {
          double totalDist = 0;
          int totalSeconds = 0;
          for (var s in sets) {
            final dist = s.distanceKm ?? 0.0;
            final dur = s.durationSeconds ?? 0;

            totalDist += dist;
            totalSeconds += dur;
          }
          final int minutes = (totalSeconds / 60).round();
          summaryMap[name] =
              "${totalDist.toStringAsFixed(1)} km | $minutes min";
        } else {
          double totalVol = 0;
          double sessionMaxWeight = 0;
          double sessionMaxVolume = 0;
          double sessionMaxEst1rm = 0;

          for (var s in sets) {
            final w = s.weightKg ?? 0.0;
            final r = s.reps ?? 0;
            totalVol += w * r;

            if (s.isCompleted == true && s.setType != 'warmup') {
              if (w > sessionMaxWeight) sessionMaxWeight = w;
              final vol = w * r;
              if (vol > sessionMaxVolume) sessionMaxVolume = vol;
              if (r > 0 && r <= 10) {
                final e1rm = w * (36 / (37 - r));
                if (e1rm > sessionMaxEst1rm) sessionMaxEst1rm = e1rm;
              }
            }
          }
          summaryMap[name] = "${totalVol.toStringAsFixed(0)} kg";

          // Calculate PRs for strength exercises
          final historicalBests = await db.getExerciseBests(
            name,
            excludeWorkoutLogId: widget.logId,
          );

          List<String> records = [];
          if (sessionMaxWeight > (historicalBests['maxWeight'] ?? 0)) {
            final double old = historicalBests['maxWeight'] ?? 0;
            final String diff =
                old > 0 ? " (+${(sessionMaxWeight - old).toStringAsFixed(1)})" : "";
            records.add(
              "${l10n.exerciseMetricMaxWeight} (${sessionMaxWeight.toStringAsFixed(1).replaceAll('.0', '')} kg$diff)",
            );
          }
          if (sessionMaxVolume > (historicalBests['maxVolume'] ?? 0)) {
            final double old = historicalBests['maxVolume'] ?? 0;
            final String diff =
                old > 0 ? " (+${(sessionMaxVolume - old).toStringAsFixed(0)})" : "";
            records.add(
              "${l10n.exerciseMetricVolume} (${sessionMaxVolume.toStringAsFixed(0)} kg$diff)",
            );
          }
          if (sessionMaxEst1rm > (historicalBests['maxEst1rm'] ?? 0)) {
            final double old = historicalBests['maxEst1rm'] ?? 0;
            final String diff =
                old > 0 ? " (+${(sessionMaxEst1rm - old).toStringAsFixed(1)})" : "";
            records.add(
              "${l10n.exerciseMetricEst1RM} (${sessionMaxEst1rm.toStringAsFixed(1).replaceAll('.0', '')} kg$diff)",
            );
          }

          if (records.isNotEmpty) {
            newRecordsMap[name] = records;
          }
        }
      }

      final heartRate = await heartRateFuture;

      if (mounted) {
        setState(() {
          _log = data;
          _summaryPerExercise = summaryMap;
          _newRecordsPerExercise = newRecordsMap;
          _heartRateSummary = heartRate;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate total volume only for strength, or omit it for mixed workouts?
    // Keep the global "Volume" header as the sum of all strength volume.
    double globalVolume = 0;
    if (_log != null) {
      for (var set in _log!.sets) {
        // Add only weight * reps (cardio usually has 0 or null here).
        globalVolume += (set.weightKg ?? 0) * (set.reps ?? 0);
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBar(
        title: l10n.workoutSummaryTitle,
        actions: [
          if (!_isLoading && _log != null)
            IconButton(
              tooltip: l10n.share,
              icon: const Icon(Icons.ios_share),
              onPressed: () => _shareService.showWorkoutShareSheet(
                context: context,
                workout: _log!,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _log == null
              ? Center(child: Text(l10n.workoutNotFound))
              : Padding(
                  padding: DesignConstants.cardPadding,
                  child: Column(
                    children: [
                      // Overall statistics
                      WorkoutSummaryBar(
                        duration: _log!.endTime?.difference(_log!.startTime),
                        volume: globalVolume,
                        sets: _log!.sets.length,
                        progress: null,
                      ),
                      const SizedBox(height: DesignConstants.spacingXL),
                      if (_heartRateSummary != null) ...[
                        _buildHeartRateCard(l10n, _heartRateSummary!),
                        const SizedBox(height: DesignConstants.spacingL),
                      ],

                      // Exercise list
                      Expanded(
                        child: ListView(
                          children: [
                            if (_log!.routineName != null &&
                                _log!.routineName!.isNotEmpty) ...[
                              Text(
                                _log!.routineName!,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: DesignConstants.spacingS),
                            ],
                            if (_log!.notes != null &&
                                _log!.notes!.isNotEmpty) ...[
                              Text(
                                _log!.notes!,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: DesignConstants.spacingL),
                            ],

                            // NEW RECORDS SECTION
                            if (_newRecordsPerExercise.isNotEmpty) ...[
                              Text(
                                l10n.workoutSummaryNewRecordsTitle,
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: DesignConstants.spacingS),
                              ..._newRecordsPerExercise.entries.map((entry) {
                                return SummaryCard(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.emoji_events,
                                      color: Colors.amber,
                                    ),
                                    title: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(entry.value.join(", ")),
                                  ),
                                );
                              }),
                              const SizedBox(height: DesignConstants.spacingL),
                            ],

                            Text(
                              l10n.workoutSummaryExerciseOverview,
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: DesignConstants.spacingS),
                            ..._summaryPerExercise.entries.map((entry) {
                              return SummaryCard(
                                child: ListTile(
                                  title: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // This now shows either "X kg" or "X km | Y min".
                                  trailing: Text(
                                    entry.value,
                                    style: textTheme.bodyLarge,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: DesignConstants.spacingXL),

                      // Fertig-Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            l10n.doneButtonLabel,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeartRateCard(
    AppLocalizations l10n,
    WorkoutHeartRateSummary summary,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final hasMetrics = summary.hasSummaryMetrics;
    final qualityLabel = _qualityLabel(l10n, summary.quality);

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workoutHeartRateSectionTitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (hasMetrics)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: l10n.workoutHeartRateAverageLabel,
                      value:
                          '${summary.averageBpm!.round()} ${l10n.sleepBpmUnit}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: l10n.workoutHeartRateMaxLabel,
                      value: '${summary.maxBpm!.round()} ${l10n.sleepBpmUnit}',
                    ),
                  ),
                ],
              )
            else
              Text(
                _noDataMessage(l10n, summary.noDataReason),
                style: textTheme.bodyMedium,
              ),
            const SizedBox(height: 8),
            Text(
              '${l10n.workoutHeartRateSampleCount(summary.sampleCount)} • $qualityLabel',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  String _qualityLabel(
    AppLocalizations l10n,
    WorkoutHeartRateDataQuality quality,
  ) {
    return switch (quality) {
      WorkoutHeartRateDataQuality.ready => l10n.workoutHeartRateQualityReady,
      WorkoutHeartRateDataQuality.limited =>
        l10n.workoutHeartRateQualityLimited,
      WorkoutHeartRateDataQuality.insufficient =>
        l10n.workoutHeartRateQualityInsufficient,
      WorkoutHeartRateDataQuality.noData => l10n.workoutHeartRateQualityNoData,
    };
  }

  String _noDataMessage(
    AppLocalizations l10n,
    WorkoutHeartRateNoDataReason reason,
  ) {
    return switch (reason) {
      WorkoutHeartRateNoDataReason.permissionDenied =>
        l10n.workoutHeartRateNoDataPermission,
      WorkoutHeartRateNoDataReason.platformUnavailable =>
        l10n.workoutHeartRateNoDataUnavailable,
      WorkoutHeartRateNoDataReason.workoutNotFinished =>
        l10n.workoutHeartRateNoDataWorkoutNotFinished,
      WorkoutHeartRateNoDataReason.invalidWorkoutWindow =>
        l10n.workoutHeartRateNoDataInvalidWindow,
      WorkoutHeartRateNoDataReason.queryFailed =>
        l10n.workoutHeartRateNoDataQueryFailed,
      _ => l10n.workoutHeartRateNoDataGeneral,
    };
  }
}
