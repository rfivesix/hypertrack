import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/chart_data_point.dart';
import '../util/design_constants.dart';

enum MeasurementChartAxisMode { day, time }

/// A widget for visualizing body measurement data in a line chart.
///
/// Fetches and displays historical data for a specific [chartType] and [dateRange].
class MeasurementChartWidget extends StatefulWidget {
  const MeasurementChartWidget({
    super.key,
    required this.chartType,
    required this.dateRange,
    required this.unit,
    this.emptyStateLabel,
    this.referenceLineValue,
    this.valueFractionDigits = 1,
    this.valueLabelBuilder,
    this.selectedDateLabelBuilder,
    this.axisLabelBuilder,
  })  : dataPoints = null,
        axisMode = MeasurementChartAxisMode.day;

  const MeasurementChartWidget.fromData({
    super.key,
    required this.dataPoints,
    required this.unit,
    this.axisMode = MeasurementChartAxisMode.time,
    this.emptyStateLabel,
    this.referenceLineValue,
    this.valueFractionDigits = 1,
    this.valueLabelBuilder,
    this.selectedDateLabelBuilder,
    this.axisLabelBuilder,
  })  : chartType = null,
        dateRange = null;

  /// The type of measurement (e.g., 'weight', 'fat_percent').
  final String? chartType;

  /// The time period to display in the chart.
  final DateTimeRange? dateRange;

  /// Optional direct datapoints to render without querying the measurement DB.
  final List<ChartDataPoint>? dataPoints;

  /// Horizontal axis mode for label and x-value projection.
  final MeasurementChartAxisMode axisMode;

  /// The unit of measurement for axis labeling.
  final String unit;

  /// Optional empty state label override.
  final String? emptyStateLabel;

  /// Optional horizontal reference line value.
  final double? referenceLineValue;

  /// Digits used by default value formatting.
  final int valueFractionDigits;

  /// Optional display value builder for the selected point.
  final String Function(double value, String unit)? valueLabelBuilder;

  /// Optional selected point date label formatter.
  final String Function(DateTime value)? selectedDateLabelBuilder;

  /// Optional bottom axis label formatter.
  final String Function(DateTime value, int spanUnits)? axisLabelBuilder;

  bool get usesExternalData => dataPoints != null;

  @override
  State<MeasurementChartWidget> createState() => _MeasurementChartWidgetState();
}

class _MeasurementChartWidgetState extends State<MeasurementChartWidget> {
  List<ChartDataPoint> _dataPoints = [];
  bool _isLoadingChart = true;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    if (widget.usesExternalData) {
      _applyExternalData(notify: false);
    } else {
      _loadChartData();
    }
  }

  @override
  void didUpdateWidget(covariant MeasurementChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.usesExternalData) {
      if (oldWidget.dataPoints != widget.dataPoints ||
          oldWidget.axisMode != widget.axisMode ||
          oldWidget.valueFractionDigits != widget.valueFractionDigits ||
          oldWidget.referenceLineValue != widget.referenceLineValue) {
        _applyExternalData();
      }
      return;
    }
    if (oldWidget.chartType != widget.chartType ||
        oldWidget.dateRange != widget.dateRange ||
        oldWidget.axisMode != widget.axisMode) {
      _loadChartData();
    }
  }

  void _applyExternalData({bool notify = true}) {
    final sorted = List<ChartDataPoint>.from(widget.dataPoints ?? const [])
      ..sort((a, b) => a.date.compareTo(b.date));
    if (!notify) {
      _dataPoints = sorted;
      _isLoadingChart = false;
      _touchedIndex = null;
      return;
    }
    if (!mounted) return;
    setState(() {
      _dataPoints = sorted;
      _isLoadingChart = false;
      _touchedIndex = null;
    });
  }

  Future<void> _loadChartData() async {
    final chartType = widget.chartType;
    final dateRange = widget.dateRange;
    if (chartType == null || dateRange == null) {
      if (!mounted) return;
      setState(() {
        _dataPoints = const <ChartDataPoint>[];
        _isLoadingChart = false;
        _touchedIndex = null;
      });
      return;
    }

    setState(() {
      _isLoadingChart = true;
      _touchedIndex = null;
    });
    final data = await DatabaseHelper.instance.getChartDataForTypeAndRange(
      chartType,
      dateRange,
    );
    if (mounted) {
      final sorted = List<ChartDataPoint>.from(data)
        ..sort((a, b) => a.date.compareTo(b.date));
      setState(() {
        _dataPoints = sorted;
        _isLoadingChart = false;
      });
    }
  }

  void _setTouchedIndexWithHaptics(int? newIndex) {
    if (newIndex == _touchedIndex) return;
    _touchedIndex = newIndex;
    if (newIndex != null) {
      HapticFeedback.mediumImpact();
    }
    if (mounted) setState(() {});
  }

  void _handleTouchCallback(FlTouchEvent event, LineTouchResponse? response) {
    if (event is FlPanEndEvent || event is FlTapUpEvent) {
      _touchedIndex = null;
      if (mounted) setState(() {});
      return;
    }

    final spots = response?.lineBarSpots;
    if (spots != null && spots.isNotEmpty) {
      final idx = spots.first.spotIndex;
      _setTouchedIndexWithHaptics(idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoadingChart) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_dataPoints.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Text(widget.emptyStateLabel ?? l10n.chart_no_data_for_period),
        ),
      );
    }

    final int lastIdx = _dataPoints.length - 1;
    final int shownIdx = (_touchedIndex != null &&
            _touchedIndex! >= 0 &&
            _touchedIndex! < _dataPoints.length)
        ? _touchedIndex!
        : lastIdx;

    final ChartDataPoint displayPoint = _dataPoints[shownIdx];
    final String displayValue = widget.valueLabelBuilder?.call(
          displayPoint.value,
          widget.unit,
        ) ??
        '${displayPoint.value.toStringAsFixed(widget.valueFractionDigits)} ${widget.unit}';
    final String displayDate = widget.selectedDateLabelBuilder?.call(
          displayPoint.date,
        ) ??
        _defaultSelectedDateLabel(context, displayPoint.date);

    final DateTime firstDate = widget.axisMode == MeasurementChartAxisMode.day
        ? _atStartOfDay(_dataPoints.first.date)
        : _dataPoints.first.date;
    final DateTime lastDate = widget.axisMode == MeasurementChartAxisMode.day
        ? _atStartOfDay(_dataPoints.last.date)
        : _dataPoints.last.date;

    final int spanUnits = widget.axisMode == MeasurementChartAxisMode.day
        ? lastDate.difference(firstDate).inDays
        : lastDate.difference(firstDate).inMinutes;
    final double lastX = spanUnits.toDouble();
    final int labelEvery = _labelInterval(spanUnits, widget.axisMode);

    double xForPoint(ChartDataPoint point) {
      if (widget.axisMode == MeasurementChartAxisMode.day) {
        return _atStartOfDay(point.date)
            .difference(firstDate)
            .inDays
            .toDouble();
      }
      return point.date.difference(firstDate).inMinutes.toDouble();
    }

    DateTime dateAtAxisValue(int value) {
      if (widget.axisMode == MeasurementChartAxisMode.day) {
        return firstDate.add(Duration(days: value));
      }
      return firstDate.add(Duration(minutes: value));
    }

    String axisLabelFor(DateTime value) {
      return widget.axisLabelBuilder?.call(value, spanUnits) ??
          _defaultAxisLabel(value, spanUnits);
    }

    final double? referenceLineValue = widget.referenceLineValue ??
        (widget.usesExternalData ? null : _dataPoints.first.value);

    return SizedBox(
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                displayValue,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                displayDate,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: lastX == 0 ? 1 : lastX,
                clipData: const FlClipData.none(),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) =>
                        List<LineTooltipItem?>.filled(
                      touchedSpots.length,
                      null,
                      growable: false,
                    ),
                  ),
                  touchCallback: _handleTouchCallback,
                ),
                extraLinesData: referenceLineValue == null
                    ? const ExtraLinesData()
                    : ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: referenceLineValue,
                            color: Colors.grey.withValues(alpha: 0.5),
                            strokeWidth: 1,
                            dashArray: [3, 4],
                          ),
                        ],
                      ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final int v = value.round();
                        if (v < 0 || v > spanUnits) {
                          return const SizedBox.shrink();
                        }

                        final bool isEdge = (v == 0) || (v == spanUnits);
                        final bool show = isEdge || (v % labelEvery == 0);

                        if (!show) return const SizedBox.shrink();

                        final date = dateAtAxisValue(v);
                        return SideTitleWidget(
                          meta: meta,
                          space: 8,
                          child: Text(
                            axisLabelFor(date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _dataPoints
                        .map((point) => FlSpot(xForPoint(point), point.value))
                        .toList(),
                    isCurved: false,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, bar) {
                        if (_touchedIndex == null) return false;
                        final idx = bar.spots.indexOf(spot);
                        return idx == _touchedIndex;
                      },
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 6,
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: Theme.of(
                          context,
                        ).scaffoldBackgroundColor,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _atStartOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  int _labelInterval(int spanUnits, MeasurementChartAxisMode mode) {
    if (spanUnits <= 1) return 1;
    if (mode == MeasurementChartAxisMode.day) {
      const desiredLabels = 6;
      return (spanUnits / desiredLabels).ceil().clamp(1, 100000);
    }
    final raw = (spanUnits / 6).ceil();
    const candidates = <int>[5, 10, 15, 20, 30, 45, 60, 90, 120];
    for (final candidate in candidates) {
      if (raw <= candidate) return candidate;
    }
    return ((raw / 60).ceil() * 60).clamp(1, 100000);
  }

  String _defaultSelectedDateLabel(BuildContext context, DateTime value) {
    if (widget.axisMode == MeasurementChartAxisMode.day) {
      return DateFormat.yMMMd().format(value);
    }
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.Hm(locale).format(value);
  }

  String _defaultAxisLabel(DateTime value, int spanUnits) {
    if (widget.axisMode == MeasurementChartAxisMode.time) {
      return DateFormat.Hm().format(value);
    }
    if (spanUnits > 365 * 2) return DateFormat('yyyy').format(value);
    if (spanUnits > 365) return DateFormat('MMM yyyy').format(value);
    if (spanUnits > 31) return DateFormat('MMM d').format(value);
    return DateFormat.MMMd().format(value);
  }
}
