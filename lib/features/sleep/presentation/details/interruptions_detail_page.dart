import 'package:flutter/material.dart';

import '../../data/sleep_day_repository.dart';
import 'sleep_data_unavailable_card.dart';
import 'sleep_detail_page_shell.dart';
import 'sleep_metric_formatters.dart';

class InterruptionsDetailPage extends StatelessWidget {
  const InterruptionsDetailPage({super.key, this.overview});

  final SleepDayOverviewData? overview;

  @override
  Widget build(BuildContext context) {
    final overview = this.overview;
    if (overview == null) {
      return const Scaffold(
        appBar: AppBar(title: Text('Interruptions')),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: SleepDataUnavailableCard(message: 'Interruptions data is unavailable.'),
        ),
      );
    }
    return SleepDetailPageShell(
      title: 'Interruptions',
      value: '${overview.interruptionsCount}',
      statusLabel: overview.interruptionsCount == 0 ? 'None detected' : 'Detected',
      subtitle: 'Qualifying wake interruptions overnight.',
      statusColor: overview.interruptionsCount <= 1 ? Colors.green : Colors.orange,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total wake duration'),
              Text(formatDuration(overview.interruptionsWakeDuration)),
            ],
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
