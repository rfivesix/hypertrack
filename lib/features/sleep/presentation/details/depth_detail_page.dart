import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../data/sleep_day_repository.dart';
import '../../domain/sleep_enums.dart';
import 'sleep_detail_page_shell.dart';
import 'sleep_metric_formatters.dart';

class DepthDetailPage extends StatelessWidget {
  const DepthDetailPage({super.key, this.overview});

  final SleepDayOverviewData? overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overview = this.overview;
    if (overview == null) {
      return SleepDetailUnavailablePage(
        title: l10n.sleepMetricDepthTitle,
        message: l10n.sleepDepthUnavailable,
      );
    }

    final hasReliableStageData = overview.hasStageData &&
        overview.stageDataConfidence != SleepStageConfidence.low;

    if (!hasReliableStageData) {
      return SleepDetailUnavailablePage(
        title: l10n.sleepMetricDepthTitle,
        message: l10n.sleepDepthConfidenceTooLow,
      );
    }

    if (!overview.hasStageDurations) {
      return SleepDetailUnavailablePage(
        title: l10n.sleepMetricDepthTitle,
        message: l10n.sleepDepthBreakdownUnavailable,
      );
    }

    final deepDuration = overview.deepDuration ?? Duration.zero;
    final lightDuration = overview.lightDuration ?? Duration.zero;
    final remDuration = overview.remDuration ?? Duration.zero;
    final total = deepDuration + lightDuration + remDuration;
    final totalMinutes = total.inMinutes == 0 ? 1 : total.inMinutes;
    final deepPct = (deepDuration.inMinutes / totalMinutes) * 100;
    final lightPct = (lightDuration.inMinutes / totalMinutes) * 100;
    final remPct = (remDuration.inMinutes / totalMinutes) * 100;
    final rating = deepPct >= 20
        ? l10n.sleepDepthRatingRestorative
        : l10n.sleepDepthRatingLightLeaning;

    return SleepDetailPageShell(
      title: l10n.sleepMetricDepthTitle,
      value: rating,
      statusLabel: l10n.sleepDepthStageConfidenceLabel(
        overview.stageDataConfidence.name,
      ),
      subtitle: l10n.sleepDepthSubtitle,
      children: [
        SizedBox(
          height: 16,
          child: Row(
            children: [
              Expanded(
                flex: deepDuration.inMinutes.clamp(1, totalMinutes).toInt(),
                child: Container(color: Colors.indigo),
              ),
              Expanded(
                flex: lightDuration.inMinutes.clamp(1, totalMinutes).toInt(),
                child: Container(color: Colors.blue),
              ),
              Expanded(
                flex: remDuration.inMinutes.clamp(1, totalMinutes).toInt(),
                child: Container(color: Colors.purple),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DepthRow(
          label: l10n.sleepStageDeepLabel,
          duration: deepDuration,
          percent: deepPct,
        ),
        _DepthRow(
          label: l10n.sleepStageLightLabel,
          duration: lightDuration,
          percent: lightPct,
        ),
        _DepthRow(
          label: l10n.sleepStageRemLabel,
          duration: remDuration,
          percent: remPct,
        ),
      ],
    );
  }
}

class _DepthRow extends StatelessWidget {
  const _DepthRow({
    required this.label,
    required this.duration,
    required this.percent,
  });

  final String label;
  final Duration duration;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('${formatDuration(duration)} • ${percent.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }
}
