import 'package:flutter/material.dart';

import '../../../../widgets/summary_card.dart';
import '../../data/sleep_day_repository.dart';
import 'sleep_detail_page_shell.dart';
import 'sleep_metric_formatters.dart';

class InterruptionsDetailPage extends StatelessWidget {
  const InterruptionsDetailPage({super.key, this.overview});

  final SleepDayOverviewData? overview;

  @override
  Widget build(BuildContext context) {
    final overview = this.overview;
    if (overview == null) {
      return const SleepDetailUnavailablePage(
        title: 'Interruptions',
        message: 'Interruptions data is unavailable.',
      );
    }
    if (overview.interruptionsCount == null ||
        overview.interruptionsWakeDuration == null) {
      return const SleepDetailUnavailablePage(
        title: 'Interruptions',
        message: 'Interruptions data is unavailable.',
      );
    }
    if (overview.interruptionsCount! < 0) {
      return const SleepDetailUnavailablePage(
        title: 'Interruptions',
        message: 'Interruptions data is unavailable.',
      );
    }
    return SleepDetailPageShell(
      title: 'Interruptions',
      value: '${overview.interruptionsCount}',
      statusLabel:
          overview.interruptionsCount! == 0 ? 'None detected' : 'Detected',
      subtitle: 'Qualifying wake interruptions overnight.',
      statusColor:
           overview.interruptionsCount! <= 1 ? Colors.green : Colors.orange,
      children: [
        SummaryCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total wake duration'),
                Text(formatDuration(overview.interruptionsWakeDuration!)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'This view includes only qualifying interruptions from derived analysis outputs.',
        ),
      ],
    );
  }
}
