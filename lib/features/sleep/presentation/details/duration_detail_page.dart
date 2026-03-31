import 'package:flutter/material.dart';

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
    final overview = this.overview;
    if (overview == null) {
      return const Scaffold(
        appBar: AppBar(title: Text('Duration')),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: SleepDataUnavailableCard(message: 'Duration data is unavailable.'),
        ),
      );
    }
    final duration = overview.totalSleepDuration;
    final status = duration.inHours >= 7 ? 'Within target' : 'Below target';
    return SleepDetailPageShell(
      title: 'Duration',
      value: formatDuration(duration),
      statusLabel: status,
      subtitle: 'Your total sleep duration for this night.',
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
        const Text(
          'Adults often do best with roughly 7–9 hours. This benchmark helps you see where your night sits in that range.',
        ),
      ],
    );
  }
}
