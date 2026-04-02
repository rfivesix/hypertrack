import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../models/chart_data_point.dart';
import '../../../../widgets/measurement_chart_widget.dart';
import '../../../../widgets/summary_card.dart';
import '../../data/sleep_day_repository.dart';
import 'sleep_data_unavailable_card.dart';
import 'sleep_detail_page_shell.dart';
import 'widgets/sleep_benchmark_bar.dart';

class HeartRateDetailPage extends StatelessWidget {
  const HeartRateDetailPage({super.key, this.overview});

  final SleepDayOverviewData? overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overview = this.overview;
    if (overview == null) {
      return SleepDetailUnavailablePage(
        title: l10n.sleepMetricHeartRateTitle,
        message: l10n.sleepHeartRateUnavailable,
      );
    }

    final avg = overview.sleepHrAvg;
    final hasAverage = avg != null;
    final chartPoints = overview.heartRateSamples
        .where((sample) => sample.bpm.isFinite)
        .map(
          (sample) => ChartDataPoint(
            date: sample.sampledAtUtc.toLocal(),
            value: sample.bpm,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.date.compareTo(b.date));
    final hasSamples = chartPoints.isNotEmpty;
    final established = overview.hasHeartRateBaseline;
    final baseline = overview.baselineSleepHr;
    final delta = overview.deltaSleepHr;

    final statusLabel = !hasSamples
        ? l10n.sleepHeartRateStatusNoSampleSeries
        : !established
            ? l10n.sleepHeartRateStatusBaselineNotEstablished
            : (delta == null
                ? l10n.sleepHeartRateStatusComparisonUnavailable
                : (delta <= 0
                    ? l10n.sleepHeartRateStatusBelowBaseline
                    : l10n.sleepHeartRateStatusAboveBaseline));

    final baselineText = !hasSamples
        ? l10n.sleepHeartRateNoSamplesText
        : !established
            ? l10n.sleepHeartRateBaselineNotEstablishedText
            : (delta == null
                ? l10n.sleepHeartRateComparisonUnavailableText
                : l10n.sleepHeartRateDeltaText(
                    delta.isNegative
                        ? l10n.sleepHeartRateDirectionBelow
                        : l10n.sleepHeartRateDirectionAbove,
                    delta.abs().toStringAsFixed(1),
                    l10n.sleepBpmUnit,
                  ));

    final locale = Localizations.localeOf(context).toString();
    final timeFormatter = DateFormat.Hm(locale);

    return SleepDetailPageShell(
      title: l10n.sleepMetricHeartRateTitle,
      value: hasAverage ? '${avg.round()} ${l10n.sleepBpmUnit}' : '--',
      statusLabel: statusLabel,
      subtitle: established
          ? l10n.sleepHeartRateComparedBaselineSubtitle
          : l10n.sleepHeartRateNoBaselineSubtitle,
      statusColor: !hasSamples
          ? Colors.grey
          : established
              ? (delta != null && delta <= 0 ? Colors.green : Colors.orange)
              : Colors.grey,
      children: [
        if (hasAverage) ...[
          SleepBenchmarkBar(
            min: 35,
            max: 90,
            value: avg,
            lowerTarget:
                established && baseline != null ? baseline - 3 : avg - 2,
            upperTarget:
                established && baseline != null ? baseline + 3 : avg + 2,
          ),
          const SizedBox(height: 12),
        ],
        if (hasSamples)
          SummaryCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MeasurementChartWidget.fromData(
                dataPoints: chartPoints,
                unit: l10n.sleepBpmUnit,
                axisMode: MeasurementChartAxisMode.time,
                valueFractionDigits: 0,
                referenceLineValue: established ? baseline : null,
                valueLabelBuilder: (value, unit) => '${value.round()} $unit',
                selectedDateLabelBuilder: (value) =>
                    timeFormatter.format(value),
                axisLabelBuilder: (value, _) => timeFormatter.format(value),
              ),
            ),
          )
        else
          SleepDataUnavailableCard(
            message: l10n.sleepHeartRateSamplesUnavailable,
          ),
        const SizedBox(height: 12),
        Text(baselineText),
        if (established && baseline != null && hasSamples) ...[
          const SizedBox(height: 8),
          Text(
            l10n.sleepHeartRateDashedLineHint(
              baseline.toStringAsFixed(1),
              l10n.sleepBpmUnit,
            ),
          ),
        ],
      ],
    );
  }
}
