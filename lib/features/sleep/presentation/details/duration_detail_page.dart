import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../data/sleep_day_repository.dart';
import 'sleep_data_unavailable_card.dart';
import 'sleep_detail_page_shell.dart';
import 'sleep_metric_formatters.dart';
import 'widgets/sleep_benchmark_bar.dart';

class DurationDetailPage extends StatelessWidget {
  const DurationDetailPage({super.key, this.overview});

  final SleepDayOverviewData? overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overview = this.overview;
    if (overview == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sleepMetricDurationTitle)),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: SleepDataUnavailableCard(
            message: l10n.sleepDurationUnavailable,
          ),
        ),
      );
    }
    final duration = overview.totalSleepDuration;
    if (duration <= Duration.zero) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sleepMetricDurationTitle)),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: SleepDataUnavailableCard(
            message: l10n.sleepDurationUnavailable,
          ),
        ),
      );
    }
    final status = duration.inHours >= 7
        ? l10n.sleepDurationStatusWithinTarget
        : l10n.sleepDurationStatusBelowTarget;
    return SleepDetailPageShell(
      title: l10n.sleepMetricDurationTitle,
      value: formatDuration(duration),
      statusLabel: status,
      subtitle: l10n.sleepDurationSubtitle,
      statusColor: duration.inHours >= 7 ? Colors.green : Colors.orange,
      children: [
        SleepBenchmarkBar(
          min: 0,
          max: 12 * 60,
          value: duration.inMinutes.toDouble(),
          lowerTarget: 7 * 60,
          upperTarget: 9 * 60,
        ),
        const SizedBox(height: 12),
        Text(l10n.sleepDurationBenchmarkHint),
      ],
    );
  }
}
