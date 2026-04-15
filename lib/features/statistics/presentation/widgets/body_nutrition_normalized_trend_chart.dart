import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/analytics_chart_defaults.dart';
import '../../domain/analytics_state.dart';
import '../../domain/body_nutrition_analytics_models.dart';

class BodyNutritionNormalizedTrendChart extends StatelessWidget {
  const BodyNutritionNormalizedTrendChart({
    super.key,
    required this.range,
    required this.weightSeries,
    required this.calorieSeries,
    this.compact = false,
  });

  final DateTimeRange? range;
  final List<DailyValuePoint> weightSeries;
  final List<DailyValuePoint> calorieSeries;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (weightSeries.isEmpty || calorieSeries.isEmpty || range == null) {
      return AnalyticsChartDefaults.stateView(
        context: context,
        l10n: l10n,
        status: AnalyticsStatus.insufficient,
        insufficientLabel: l10n.analyticsInsightNotEnoughData,
      );
    }

    final firstDay = DateTime(
      range!.start.year,
      range!.start.month,
      range!.start.day,
    );
    final spanDays = math.max(
      1,
      DateTime(range!.end.year, range!.end.month, range!.end.day)
              .difference(firstDay)
              .inDays +
          1,
    );
    final maxX = math.max(1, spanDays - 1).toDouble();

    final weightSpots = weightSeries
        .map((point) => FlSpot(_xOf(point.day, firstDay), point.value))
        .toList(growable: false);
    final calorieSpots = calorieSeries
        .map((point) => FlSpot(_xOf(point.day, firstDay), point.value))
        .toList(growable: false);

    final allYValues = [
      ...weightSeries.map((point) => point.value),
      ...calorieSeries.map((point) => point.value),
    ];
    final maxAbs =
        allYValues.map((value) => value.abs()).fold<double>(0.0, math.max);
    final yLimit = math.max(0.6, maxAbs * 1.15);

    final chartData = LineChartData(
      minX: 0,
      maxX: maxX,
      minY: -yLimit,
      maxY: yLimit,
      gridData: compact
          ? AnalyticsChartDefaults.noGrid
          : const FlGridData(show: true, drawVerticalLine: false),
      borderData: AnalyticsChartDefaults.noBorder,
      lineTouchData: const LineTouchData(enabled: false),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: 0,
            color: Theme.of(context).colorScheme.outlineVariant,
            strokeWidth: 1,
            dashArray: const [5, 4],
          ),
        ],
      ),
      titlesData: compact
          ? AnalyticsChartDefaults.hiddenTitles
          : AnalyticsChartDefaults.standardTitles(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if ((value - 0).abs() < 0.0001) {
                      return AnalyticsChartDefaults.tickLabel(context, '0%');
                    }
                    if ((value + yLimit).abs() < 0.4) {
                      return AnalyticsChartDefaults.tickLabel(
                        context,
                        '-${yLimit.round()}%',
                      );
                    }
                    if ((value - yLimit).abs() < 0.4) {
                      return AnalyticsChartDefaults.tickLabel(
                        context,
                        '+${yLimit.round()}%',
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (value, meta) {
                    final positions = _xLabelPositions(spanDays);
                    final rounded = value.round();
                    if (!positions.contains(rounded)) {
                      return const SizedBox.shrink();
                    }
                    final day = firstDay.add(Duration(days: rounded));
                    return AnalyticsChartDefaults.tickLabel(
                      context,
                      DateFormat('MMMd').format(day),
                    );
                  },
                ),
              ),
            ),
      lineBarsData: [
        AnalyticsChartDefaults.straightLine(
          spots: weightSpots,
          barWidth: compact ? 2.0 : 2.5,
          color: Theme.of(context).colorScheme.primary,
        ),
        AnalyticsChartDefaults.straightLine(
          spots: calorieSpots,
          barWidth: compact ? 2.0 : 2.5,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );

    return LineChart(chartData);
  }

  double _xOf(DateTime day, DateTime firstDay) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return normalizedDay.difference(firstDay).inDays.toDouble();
  }

  Set<int> _xLabelPositions(int spanDays) {
    if (spanDays <= 1) return {0};
    final interval = (spanDays / 4).ceil().clamp(1, 10000);
    final positions = <int>{0, spanDays - 1};
    for (var i = interval; i < spanDays - 1; i += interval) {
      positions.add(i);
    }
    return positions;
  }
}
