import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/health/workout_heart_rate_models.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../analytics/domain/models/chart_data_point.dart';
import '../../../profile/presentation/widgets/measurement_chart_widget.dart';

/// A self-contained section to display heart rate metrics and charts for a workout window.
class WorkoutHeartRateSection extends StatelessWidget {
  final WorkoutHeartRateSummary summary;
  final bool pulseTrackingEnabled;

  const WorkoutHeartRateSection({
    super.key,
    required this.summary,
    required this.pulseTrackingEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final timeFormatter = DateFormat.Hm(locale);
    final points = summary.chartSamples
        .map(
          (sample) => ChartDataPoint(
            date: sample.sampledAtUtc.toLocal(),
            value: sample.bpm,
          ),
        )
        .toList(growable: false);

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workoutHeartRateSectionTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (summary.hasSummaryMetrics)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildHeartRateMetricTile(
                    context: context,
                    label: l10n.workoutHeartRateAverageLabel,
                    value:
                        '${summary.averageBpm!.round()} ${l10n.sleepBpmUnit}',
                  ),
                  _buildHeartRateMetricTile(
                    context: context,
                    label: l10n.workoutHeartRateMaxLabel,
                    value: '${summary.maxBpm!.round()} ${l10n.sleepBpmUnit}',
                  ),
                  _buildHeartRateMetricTile(
                    context: context,
                    label: l10n.workoutHeartRateMinLabel,
                    value: '${summary.minBpm!.round()} ${l10n.sleepBpmUnit}',
                  ),
                ],
              )
            else
              Text(
                _heartRateNoDataMessage(l10n, summary.noDataReason),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 10),
            if (summary.canRenderChart)
              SizedBox(
                height: 220,
                child: MeasurementChartWidget.fromData(
                  dataPoints: points,
                  unit: l10n.sleepBpmUnit,
                  axisMode: MeasurementChartAxisMode.time,
                  valueFractionDigits: 0,
                  valueLabelBuilder: (value, unit) => '${value.round()} $unit',
                  selectedDateLabelBuilder: (value) =>
                      timeFormatter.format(value),
                  axisLabelBuilder: (value, _) => timeFormatter.format(value),
                ),
              )
            else if (summary.hasSummaryMetrics)
              Text(
                summary.quality == WorkoutHeartRateDataQuality.insufficient
                    ? l10n.workoutHeartRateLimitedChartHint
                    : _heartRateNoDataMessage(l10n, summary.noDataReason),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            const SizedBox(height: 8),
            Text(
              '${l10n.workoutHeartRateSampleCount(summary.sampleCount)} • ${_heartRateQualityLabel(l10n, summary.quality)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateMetricTile({
    required BuildContext context,
    required String label,
    required String value,
  }) {
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

  String _heartRateQualityLabel(
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

  String _heartRateNoDataMessage(
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
