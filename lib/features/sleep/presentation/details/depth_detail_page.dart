import 'package:flutter/material.dart';

import '../../data/sleep_day_repository.dart';
import '../../domain/sleep_enums.dart';
import 'sleep_detail_page_shell.dart';
import 'sleep_metric_formatters.dart';

class DepthDetailPage extends StatelessWidget {
  const DepthDetailPage({super.key, this.overview});

  final SleepDayOverviewData? overview;

  @override
  Widget build(BuildContext context) {
    final overview = this.overview;
    if (overview == null) {
      return const SleepDetailUnavailablePage(
        title: 'Depth',
        message: 'Depth data is unavailable.',
      );
    }

    final hasReliableStageData =
        overview.hasStageData &&
        overview.stageDataConfidence != SleepStageConfidence.low;

    if (!hasReliableStageData) {
      return const SleepDetailUnavailablePage(
        title: 'Depth',
        message: 'Stage confidence is too low for a reliable depth breakdown.',
      );
    }

    if (!overview.hasStageDurations) {
      return const SleepDetailUnavailablePage(
        title: 'Depth',
        message: 'Stage duration breakdown is unavailable for this night.',
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
    final rating = deepPct >= 20 ? 'Restorative' : 'Light-leaning';

    return SleepDetailPageShell(
      title: 'Depth',
      value: rating,
      statusLabel: 'Stage confidence: ${overview.stageDataConfidence.name}',
      subtitle: 'Stage distribution based on derived timeline segments.',
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
        _DepthRow(label: 'Deep', duration: deepDuration, percent: deepPct),
        _DepthRow(label: 'Light', duration: lightDuration, percent: lightPct),
        _DepthRow(label: 'REM', duration: remDuration, percent: remPct),
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
