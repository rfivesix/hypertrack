import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/summary_card.dart';
import '../../data/sleep_day_repository.dart';
import 'sleep_detail_page_shell.dart';
import 'sleep_metric_formatters.dart';

class InterruptionsDetailPage extends StatelessWidget {
  const InterruptionsDetailPage({super.key, this.overview});

  final SleepDayOverviewData? overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overview = this.overview;
    if (overview == null) {
      return SleepDetailUnavailablePage(
        title: l10n.sleepMetricInterruptionsTitle,
        message: l10n.sleepInterruptionsUnavailable,
      );
    }
    if (overview.interruptionsCount == null ||
        overview.interruptionsWakeDuration == null) {
      return SleepDetailUnavailablePage(
        title: l10n.sleepMetricInterruptionsTitle,
        message: l10n.sleepInterruptionsUnavailable,
      );
    }
    if (overview.interruptionsCount! < 0) {
      return SleepDetailUnavailablePage(
        title: l10n.sleepMetricInterruptionsTitle,
        message: l10n.sleepInterruptionsUnavailable,
      );
    }
    return SleepDetailPageShell(
      title: l10n.sleepMetricInterruptionsTitle,
      value: '${overview.interruptionsCount}',
      statusLabel: overview.interruptionsCount! == 0
          ? l10n.sleepInterruptionsStatusNoneDetected
          : l10n.sleepInterruptionsStatusDetected,
      subtitle: l10n.sleepInterruptionsSubtitle,
      statusColor:
          overview.interruptionsCount! <= 1 ? Colors.green : Colors.orange,
      children: [
        SummaryCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.sleepInterruptionsTotalWakeDuration),
                Text(formatDuration(overview.interruptionsWakeDuration!)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(l10n.sleepInterruptionsFootnote),
      ],
    );
  }
}
