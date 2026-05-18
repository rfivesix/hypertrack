import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../generated/app_localizations.dart';
import '../../../analytics/presentation/widgets/analytics_chart_defaults.dart';
import '../../domain/analytics_state.dart';
import '../../domain/body_nutrition_analytics_models.dart';
import '../../../../services/unit_service.dart';

class BodyNutritionNormalizedTrendChart extends StatefulWidget {
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
  State<BodyNutritionNormalizedTrendChart> createState() =>
      _BodyNutritionNormalizedTrendChartState();
}

class _BodyNutritionNormalizedTrendChartState
    extends State<BodyNutritionNormalizedTrendChart> {
  int? _lastVibratedIndex;

  @override
  Widget build(BuildContext context) {
    final range = widget.range;
    final weightSeries = widget.weightSeries;
    final calorieSeries = widget.calorieSeries;
    final compact = widget.compact;

    final l10n = AppLocalizations.of(context)!;
    if (weightSeries.isEmpty || calorieSeries.isEmpty || range == null) {
      return AnalyticsChartDefaults.stateView(
        context: context,
        l10n: l10n,
        status: AnalyticsStatus.insufficient,
        insufficientLabel: l10n.analyticsInsightNotEnoughData,
      );
    }

    final firstDay = DateTime.utc(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final spanDays = math.max(
      1,
      DateTime.utc(range.end.year, range.end.month, range.end.day)
              .difference(firstDay)
              .inDays +
          1,
    );
    final maxXInt = math.max(0, spanDays - 1);
    final maxX = math.max(1, maxXInt).toDouble();

    final unitService = Provider.of<UnitService>(context);

    // Convert weight series (stored in metric kg) into display units according
    // to the user's preference so scales, ticks and tooltips show the right
    // values (kg or lbs).
    final displayWeightSeries = weightSeries
        .map((p) => DailyValuePoint(
              day: p.day,
              value: unitService.convertDisplayValue(
                p.value,
                UnitDimension.weight,
              ),
            ))
        .toList(growable: false);

    final weightScale = _SeriesScale.fromSeries(
      displayWeightSeries,
      unit: unitService.suffixFor(UnitDimension.weight),
      fractionDigits: 1,
    );
    final calorieScale = _SeriesScale.fromSeries(
      calorieSeries,
      unit: 'kcal',
      fractionDigits: 0,
    );

    final weightPoints = _buildPoints(
      series: displayWeightSeries,
      firstDay: firstDay,
      maxX: maxX,
      scale: weightScale,
    );
    final caloriePoints = _buildPoints(
      series: calorieSeries,
      firstDay: firstDay,
      maxX: maxX,
      scale: calorieScale,
    );
    // Debug: when used as compact (hub), print range and last raw-series dates
    assert(() {
      if (compact) {
        try {
          final lastWeight =
              weightSeries.isNotEmpty ? weightSeries.last.day : null;
          final lastCal =
              calorieSeries.isNotEmpty ? calorieSeries.last.day : null;
          debugPrint(
              '[chart-debug] compact range=${range.start}..${range.end} spanDays=$spanDays');
          debugPrint(
              '[chart-debug] weightSeries count=${weightSeries.length} last=$lastWeight');
          debugPrint(
              '[chart-debug] calorieSeries count=${calorieSeries.length} last=$lastCal');
        } catch (e, st) {
          debugPrint('[chart-debug] error reading series: $e\n$st');
        }
      }
      return true;
    }());
    if (weightPoints.isEmpty || caloriePoints.isEmpty) {
      return AnalyticsChartDefaults.stateView(
        context: context,
        l10n: l10n,
        status: AnalyticsStatus.insufficient,
        insufficientLabel: l10n.analyticsInsightNotEnoughData,
      );
    }

    final series = [
      _ChartSeries(
        label: l10n.analyticsWeightTrendLabel,
        color: Theme.of(context).colorScheme.primary,
        scale: weightScale,
        points: weightPoints,
        dotShape: _SeriesDotShape.circle,
      ),
      _ChartSeries(
        label: l10n.analyticsCaloriesTrendLabel,
        color: const Color(0xFFF97316),
        scale: calorieScale,
        points: caloriePoints,
        dotShape: _SeriesDotShape.square,
      ),
    ];

    final xLabelPositions = _xLabelPositions(spanDays);

    final chartData = LineChartData(
      clipData: const FlClipData.none(),
      minX: 0,
      maxX: maxX,
      minY: -0.06,
      maxY: 1.06,
      gridData: compact
          ? AnalyticsChartDefaults.noGrid
          : FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 0.5,
            ),
      borderData: AnalyticsChartDefaults.noBorder,
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        touchSpotThreshold: 18,
        touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
          if (event is FlPanEndEvent || event is FlTapUpEvent) {
            _lastVibratedIndex = null;
            return;
          }
          final spots = response?.lineBarSpots;
          if (spots != null && spots.isNotEmpty) {
            final idx = spots.first.spotIndex;
            if (idx != _lastVibratedIndex) {
              _lastVibratedIndex = idx;
              HapticFeedback.lightImpact();
            }
          }
        },
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipBorderRadius: BorderRadius.circular(16),
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          tooltipMargin: 12,
          maxContentWidth: 200,
          getTooltipColor: (_) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return isDark
                ? const Color(0xFF2A2A2A)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.95);
          },
          tooltipBorder: BorderSide(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              final seriesIndex = touchedSpot.barIndex;
              if (seriesIndex < 0 || seriesIndex >= series.length) {
                return null;
              }
              final selectedSeries = series[seriesIndex];
              final pointIndex = touchedSpot.spotIndex;
              if (pointIndex < 0 ||
                  pointIndex >= selectedSeries.points.length) {
                return null;
              }

              final point = selectedSeries.points[pointIndex];
              final date = DateFormat.MMMd().format(point.day);
              final valueText = selectedSeries.scale.formatRaw(point.rawValue);
              final baseStyle = Theme.of(context).textTheme.bodySmall!;

              return LineTooltipItem(
                '$date\n',
                baseStyle.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                children: [
                  TextSpan(
                    text: '${selectedSeries.label}: $valueText',
                    style: baseStyle.copyWith(
                      color: selectedSeries.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            }).toList(growable: false);
          },
        ),
      ),
      titlesData: compact
          ? AnalyticsChartDefaults.hiddenTitles
          : FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52, // increased reserved size
                  interval: 0.5,
                  getTitlesWidget: (value, meta) {
                    if (!_isPrimaryTick(value)) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
                      child: _axisTitle(
                        context,
                        value,
                        weightScale,
                      ),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 56, // increased reserved size
                  interval: 0.5,
                  getTitlesWidget: (value, meta) {
                    if (!_isPrimaryTick(value)) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
                      child: _axisTitle(
                        context,
                        value,
                        calorieScale,
                        alignRight: true,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42, // increased reserved size
                  getTitlesWidget: (value, meta) {
                    final rounded = value.round();
                    if (!xLabelPositions.contains(rounded)) {
                      return const SizedBox.shrink();
                    }
                    final day = firstDay.add(Duration(days: rounded));
                    final isStartLabel = rounded == 0;
                    final isEndLabel = rounded == spanDays - 1;
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
                      child: SizedBox(
                        width: 60,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: isStartLabel
                              ? Alignment.centerLeft
                              : isEndLabel
                                  ? Alignment.centerRight
                                  : Alignment.center,
                          child: AnalyticsChartDefaults.tickLabel(
                            context,
                            DateFormat('dd.MM').format(
                                day), // Changed to a concise format to avoid overlap
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
      lineBarsData: series
          .map(
            (seriesConfig) => AnalyticsChartDefaults.straightLine(
              spots: seriesConfig.points
                  .map((point) => point.spot)
                  .toList(growable: false),
              barWidth: compact ? 2.6 : 3.2,
              isStrokeCapRound: true,
              color: seriesConfig.color,
              belowBarData: seriesConfig.label == l10n.analyticsWeightTrendLabel
                  ? BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          seriesConfig.color.withValues(alpha: 0.22),
                          seriesConfig.color.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    )
                  : BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          seriesConfig.color.withValues(alpha: 0.08),
                          seriesConfig.color.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, bar) {
                  if (seriesConfig.points.length <= 2) {
                    return true;
                  }
                  final index = bar.spots.indexOf(spot);
                  return index == 0 || index == bar.spots.length - 1;
                },
                getDotPainter: (spot, percent, bar, index) {
                  final strokeColor = Theme.of(context).scaffoldBackgroundColor;
                  return switch (seriesConfig.dotShape) {
                    _SeriesDotShape.circle => FlDotCirclePainter(
                        radius: compact ? 3.0 : 4.5,
                        color: seriesConfig.color,
                        strokeWidth: 2,
                        strokeColor: strokeColor,
                      ),
                    _SeriesDotShape.square => FlDotSquarePainter(
                        size: compact ? 6.0 : 8.0,
                        color: seriesConfig.color,
                        strokeWidth: 2,
                        strokeColor: strokeColor,
                      ),
                  };
                },
              ),
            ),
          )
          .toList(growable: false),
    );

    return LineChart(chartData);
  }

  List<_ChartPoint> _buildPoints({
    required List<DailyValuePoint> series,
    required DateTime firstDay,
    required double maxX,
    required _SeriesScale scale,
  }) {
    final deduplicatedByX = <int, _ChartPoint>{};
    final maxXInt = maxX.round();
    for (final point in series) {
      final xIndex = _xOf(point.day, firstDay).round();
      final y = point.value;
      if (!y.isFinite || xIndex < 0 || xIndex > maxXInt) continue;
      deduplicatedByX[xIndex] = _ChartPoint(
        day: point.day,
        rawValue: y,
        spot: FlSpot(xIndex.toDouble(), scale.toPlotValue(y)),
      );
    }
    final orderedPoints = deduplicatedByX.values.toList(growable: true)
      ..sort((a, b) => a.spot.x.compareTo(b.spot.x));
    if (orderedPoints.isEmpty) {
      return const [];
    }
    final firstPoint = orderedPoints.first;
    final lastPoint = orderedPoints.last;
    if (firstPoint.spot.x > 0) {
      orderedPoints.insert(
        0,
        _ChartPoint(
          day: firstPoint.day,
          rawValue: firstPoint.rawValue,
          spot: FlSpot(0, firstPoint.spot.y),
        ),
      );
    }
    if (lastPoint.spot.x < maxXInt) {
      orderedPoints.add(
        _ChartPoint(
          day: lastPoint.day,
          rawValue: lastPoint.rawValue,
          spot: FlSpot(maxXInt.toDouble(), lastPoint.spot.y),
        ),
      );
    }

    return orderedPoints;
  }

  double _xOf(DateTime day, DateTime firstDay) {
    final d1 = DateTime.utc(day.year, day.month, day.day);
    final d2 = DateTime.utc(firstDay.year, firstDay.month, firstDay.day);
    return d1.difference(d2).inDays.toDouble();
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

  bool _isPrimaryTick(double value) {
    return (value - 0).abs() < 0.0001 ||
        (value - 0.5).abs() < 0.0001 ||
        (value - 1).abs() < 0.0001;
  }

  Widget _axisTitle(
    BuildContext context,
    double normalizedValue,
    _SeriesScale scale, {
    bool alignRight = false,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        scale.formatTick(normalizedValue),
        maxLines: 1,
        softWrap: false,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _ChartPoint {
  const _ChartPoint({
    required this.day,
    required this.rawValue,
    required this.spot,
  });

  final DateTime day;
  final double rawValue;
  final FlSpot spot;
}

class _ChartSeries {
  const _ChartSeries({
    required this.label,
    required this.color,
    required this.scale,
    required this.points,
    required this.dotShape,
  });

  final String label;
  final Color color;
  final _SeriesScale scale;
  final List<_ChartPoint> points;
  final _SeriesDotShape dotShape;
}

enum _SeriesDotShape { circle, square }

class _SeriesScale {
  const _SeriesScale({
    required this.min,
    required this.max,
    required this.unit,
    required this.fractionDigits,
  });

  factory _SeriesScale.fromSeries(
    List<DailyValuePoint> series, {
    required String unit,
    required int fractionDigits,
  }) {
    final finiteValues = series
        .map((point) => point.value)
        .where((value) => value.isFinite)
        .toList(growable: false);
    if (finiteValues.isEmpty) {
      return _SeriesScale(
        min: 0,
        max: 1,
        unit: unit,
        fractionDigits: fractionDigits,
      );
    }

    final min = finiteValues.reduce(math.min);
    final max = finiteValues.reduce(math.max);
    return _SeriesScale(
      min: min,
      max: max,
      unit: unit,
      fractionDigits: fractionDigits,
    );
  }

  final double min;
  final double max;
  final String unit;
  final int fractionDigits;

  double toPlotValue(double rawValue) {
    final span = max - min;
    if (!span.isFinite || span.abs() < 0.0001) {
      return 0.5;
    }
    return ((rawValue - min) / span).clamp(0.0, 1.0);
  }

  double fromPlotValue(double normalizedValue) {
    final span = max - min;
    if (!span.isFinite || span.abs() < 0.0001) {
      return max;
    }
    return min + (span * normalizedValue);
  }

  String formatTick(double normalizedValue) {
    return '${_formatNumber(fromPlotValue(normalizedValue), fractionDigits)} $unit';
  }

  String formatRaw(double rawValue) {
    return '${_formatNumber(rawValue, fractionDigits)} $unit';
  }
}

String _formatNumber(double value, int fractionDigits) {
  final normalized = value.abs() < 0.0001 ? 0.0 : value;
  if (fractionDigits <= 0) {
    return NumberFormat.decimalPattern().format(normalized.round());
  }

  final fixed = normalized.toStringAsFixed(fractionDigits);
  final parts = fixed.split('.');
  final whole = NumberFormat.decimalPattern().format(int.parse(parts[0]));
  return parts.length == 1 ? whole : '$whole.${parts[1]}';
}
