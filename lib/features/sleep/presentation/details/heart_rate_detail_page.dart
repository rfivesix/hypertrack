import 'package:flutter/material.dart';

import '../../data/sleep_day_repository.dart';
import 'sleep_data_unavailable_card.dart';
import 'sleep_detail_page_shell.dart';
import 'widgets/sleep_benchmark_bar.dart';

class HeartRateDetailPage extends StatelessWidget {
  const HeartRateDetailPage({super.key, this.overview});

  final SleepDayOverviewData? overview;

  @override
  Widget build(BuildContext context) {
    final overview = this.overview;
    if (overview == null || overview.sleepHrAvg == null) {
      return const Scaffold(
        appBar: AppBar(title: Text('Heart rate')),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: SleepDataUnavailableCard(message: 'Sleep heart-rate data is unavailable.'),
        ),
      );
    }

    final avg = overview.sleepHrAvg!;
    final baseline = overview.baselineSleepHr;
    final established = overview.isHrBaselineEstablished && baseline != null;
    final delta = overview.deltaSleepHr;

    final statusLabel = established
        ? (delta == null
            ? 'Baseline comparison unavailable'
            : (delta <= 0 ? 'Below baseline' : 'Above baseline'))
        : 'Baseline not established';

    return SleepDetailPageShell(
      title: 'Heart rate',
      value: '${avg.round()} bpm',
      statusLabel: statusLabel,
      subtitle: established
          ? 'Compared with your recent sleep baseline.'
          : 'We need more nights to establish a stable baseline.',
      statusColor: established
          ? (delta != null && delta <= 0 ? Colors.green : Colors.orange)
          : Colors.grey,
      children: [
        SleepBenchmarkBar(
          min: 35,
          max: 90,
          value: avg,
          lowerTarget: established ? baseline! - 3 : avg - 2,
          upperTarget: established ? baseline! + 3 : avg + 2,
        ),
        const SizedBox(height: 12),
        Text(
          established
              ? (delta == null
                  ? 'Baseline comparison is currently unavailable for this night.'
                  : 'Your sleep HR is ${delta.isNegative ? 'below' : 'above'} baseline by ${delta.abs().toStringAsFixed(1)} bpm.')
              : 'Baseline not established yet. This is neutral and expected early on.',
        ),
      ],
    );
  }
}
