import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../data/sleep_day_repository.dart';
import '../../domain/aggregation/sleep_period_aggregations.dart';
import '../widgets/sleep_window_chart_card.dart';
import 'regularity_chart_math.dart';
import 'sleep_detail_page_shell.dart';
import 'sleep_metric_formatters.dart';

class RegularityDetailPage extends StatelessWidget {
  const RegularityDetailPage({super.key, this.overview});

  final SleepDayOverviewData? overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nights = overview?.regularityNights ?? const <SleepRegularityNight>[];
    if (nights.isEmpty) {
      return SleepDetailUnavailablePage(
        title: l10n.sleepMetricRegularityTitle,
        message: l10n.sleepRegularityUnavailable,
      );
    }

    final bedtimeAvg = circularAverageMinutes(
      nights.map((night) => night.bedtimeMinutes),
    );
    final wakeAvg = circularAverageMinutes(
      nights.map((night) => night.wakeMinutes),
    );

    return SleepDetailPageShell(
      title: l10n.sleepMetricRegularityTitle,
      value: l10n.sleepRegularityNightRange(nights.length),
      statusLabel: nights.length >= 7
          ? l10n.sleepRegularityStatusSufficientTrend
          : l10n.sleepRegularityStatusLimitedTrend,
      subtitle: l10n.sleepRegularitySubtitle,
      children: [
        _RegularityChart(nights: nights),
        const SizedBox(height: 12),
        _RegularitySummaryRow(
          label: l10n.sleepRegularityAverageBedtime,
          value: formatBedtimeMinutes(bedtimeAvg),
        ),
        _RegularitySummaryRow(
          label: l10n.sleepRegularityAverageWake,
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
    final l10n = AppLocalizations.of(context)!;
    final displayNights =
        nights.length <= 7 ? nights : nights.sublist(nights.length - 7);
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.Md(locale);
    return SleepWindowChartCard(
      title: l10n.sleepSleepWindowTitle,
      windows: displayNights
          .map(_sleepWindowFromRegularityNight)
          .toList(growable: false),
      dayLabelBuilder: (_, date) => dateFormat.format(date),
    );
  }

  SleepWindowSegment _sleepWindowFromRegularityNight(
      SleepRegularityNight night) {
    final window = regularityToSleepWindowMinutes(
      bedtimeMinutes: night.bedtimeMinutes,
      wakeMinutes: night.wakeMinutes,
    );
    return SleepWindowSegment(
      date: night.nightDate.toLocal(),
      startMinutes: window.startMinutes,
      endMinutes: window.endMinutes,
      hasData: true,
    );
  }
}

class _RegularitySummaryRow extends StatelessWidget {
  const _RegularitySummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }
}
