import 'package:flutter/material.dart';

import '../../data/sleep_day_repository.dart';
import 'regularity_chart_math.dart';
import 'sleep_data_unavailable_card.dart';
import 'sleep_detail_page_shell.dart';
import 'sleep_metric_formatters.dart';

class RegularityDetailPage extends StatelessWidget {
  const RegularityDetailPage({super.key, this.overview});

  final SleepDayOverviewData? overview;

  @override
  Widget build(BuildContext context) {
    final nights = overview?.regularityNights ?? const <SleepRegularityNight>[];
    if (nights.isEmpty) {
      return const Scaffold(
        appBar: AppBar(title: Text('Regularity')),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: SleepDataUnavailableCard(message: 'Regularity data is unavailable.'),
        ),
      );
    }

    final bedtimeAvg = circularAverageMinutes(
      nights.map((night) => night.bedtimeMinutes),
    );
    final wakeAvg = circularAverageMinutes(
      nights.map((night) => night.wakeMinutes),
    );

    return SleepDetailPageShell(
      title: 'Regularity',
      value: '${nights.length}-night range',
      statusLabel: nights.length >= 7 ? 'Sufficient trend data' : 'Limited trend data',
      subtitle: 'Bedtime and wake windows for recent nights.',
      children: [
        _RegularityChart(nights: nights),
        const SizedBox(height: 12),
        _RegularitySummaryRow(
          label: 'Average bedtime',
          value: formatBedtimeMinutes(bedtimeAvg),
        ),
        _RegularitySummaryRow(
          label: 'Average wake',
          value: formatBedtimeMinutes(wakeAvg),
        ),
      ],
    );
  }
}

class _RegularityChart extends StatelessWidget {
  const _RegularityChart({required this.nights});

  final List<SleepRegularityNight> nights;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        children: [
          for (final night in nights)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bed = ((night.bedtimeMinutes % 1440) + 1440) % 1440;
                  final wake = unwrapWakeMinutes(
                    bedtimeMinutes: night.bedtimeMinutes,
                    wakeMinutes: night.wakeMinutes,
                  );
                  final startX = (bed / 1440) * constraints.maxWidth;
                  final endX = ((wake - bed) / 1440) * constraints.maxWidth + startX;
                  return Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 8,
                        child: Container(height: 2, color: Theme.of(context).dividerColor),
                      ),
                      Positioned(
                        left: startX,
                        width: (endX - startX)
                            .clamp(2.0, constraints.maxWidth)
                            .toDouble(),
                        top: 5,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RegularitySummaryRow extends StatelessWidget {
  const _RegularitySummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value),
        ],
      ),
    );
  }
}
