// lib/screens/workout_summary_screen.dart

import 'package:flutter/material.dart';
import '../data/workout_database_helper.dart';
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

  // Wir speichern jetzt einen formatierten String pro Übung,
  // da Cardio und Kraft unterschiedliche Einheiten haben.
  Map<String, String> _summaryPerExercise = {};

  @override
  void initState() {
    super.initState();
    _loadWorkoutDetails();
  }

  Future<void> _loadWorkoutDetails() async {
    final db = WorkoutDatabaseHelper.instance;
    final data = await db.getWorkoutLogById(widget.logId);

    if (data != null) {
      final heartRateFuture = _heartRateService.loadForWorkoutWindow(
        startTime: data.startTime,
        endTime: data.endTime,
      );
      final Map<String, String> summaryMap = {};

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
          for (var s in sets) {
            final w = s.weightKg ?? 0.0;
            final r = s.reps ?? 0;
            totalVol += w * r;
          }
          summaryMap[name] = "${totalVol.toStringAsFixed(0)} kg";
        }
      }

      final heartRate = await heartRateFuture;

      if (mounted) {
        setState(() {
          _log = data;
          _summaryPerExercise = summaryMap;
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

    // Gesamtvolumen nur für Kraft berechnen? Oder einfach weglassen wenn Mischmasch?
    // Wir lassen die globale "Volume" Anzeige im Header einfach als Summe aller Kraft-Volumen.
    double globalVolume = 0;
    if (_log != null) {
      for (var set in _log!.sets) {
        // Nur Gewicht * Reps addieren (Cardio hat hier meist 0 oder null)
        globalVolume += (set.weightKg ?? 0) * (set.reps ?? 0);
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBar(title: l10n.workoutSummaryTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _log == null
              ? Center(child: Text(l10n.workoutNotFound))
              : Padding(
                  padding: DesignConstants.cardPadding,
                  child: Column(
                    children: [
                      // Gesamt-Statistiken
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

                      // Liste der Übungen
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
                                  // Hier wird nun entweder "X kg" oder "X km | Y min" angezeigt
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
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            l10n.doneButtonLabel,
                            style: const TextStyle(fontSize: 18),
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
