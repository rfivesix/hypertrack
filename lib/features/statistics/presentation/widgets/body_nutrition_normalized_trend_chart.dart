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

    final weightSpots = _buildSpots(
      series: weightSeries,
      firstDay: firstDay,
      maxX: maxX,
    );
    final calorieSpots = _buildSpots(
      series: calorieSeries,
      firstDay: firstDay,
      maxX: maxX,
    );
    if (weightSpots.isEmpty || calorieSpots.isEmpty) {
      return AnalyticsChartDefaults.stateView(
        context: context,
        l10n: l10n,
        status: AnalyticsStatus.insufficient,
        insufficientLabel: l10n.analyticsInsightNotEnoughData,
      );
    }

    final allYValues = [
      ...weightSpots.map((spot) => spot.y),
      ...calorieSpots.map((spot) => spot.y),
    ];
    final finiteYValues = allYValues.where((value) => value.isFinite);
    final maxAbs =
        finiteYValues.map((value) => value.abs()).fold<double>(0.0, math.max);
    final rawLimit = maxAbs * 1.15;
    final yLimit =
        (rawLimit.isFinite && rawLimit > 0) ? math.max(0.6, rawLimit) : 0.6;
    final xLabelPositions = _xLabelPositions(spanDays);

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
                    final rounded = value.round();
                    if (!xLabelPositions.contains(rounded)) {
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

  List<FlSpot> _buildSpots({
    required List<DailyValuePoint> series,
    required DateTime firstDay,
    required double maxX,
  }) {
    final deduplicatedByX = <double, double>{};
    for (final point in series) {
      final x = _xOf(point.day, firstDay);
      final y = point.value;
      if (!x.isFinite ||
          !y.isFinite ||
          x < 0 ||
          x > maxX ||
          y.isNaN ||
          y.isInfinite) {
        continue;
      }
      deduplicatedByX[x] = y;
    }
    final entries = deduplicatedByX.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((entry) => FlSpot(entry.key, entry.value))
        .toList(growable: false);
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
