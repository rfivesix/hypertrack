import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/database_helper.dart';
import '../models/chart_data_point.dart';
import 'package:intl/intl.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';
import 'package:flutter/services.dart';

/// A widget for visualizing body measurement data in a line chart.
///
/// Fetches and displays historical data for a specific [chartType] and [dateRange].
class MeasurementChartWidget extends StatefulWidget {
  /// The type of measurement (e.g., 'weight', 'fat_percent').
  final String chartType;

  /// The time period to display in the chart.
  final DateTimeRange dateRange;

  /// The unit of measurement for axis labeling.
  final String unit;

  const MeasurementChartWidget({
    super.key,
    required this.chartType,
    required this.dateRange,
    required this.unit,
  });

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
    _loadChartData();
  }

  @override
  void didUpdateWidget(covariant MeasurementChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chartType != widget.chartType ||
        oldWidget.dateRange != widget.dateRange) {
      _loadChartData();
    }
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoadingChart = true;
      _touchedIndex = null;
    });
    final data = await DatabaseHelper.instance.getChartDataForTypeAndRange(
      widget.chartType,
      widget.dateRange,
    );
    if (mounted) {
      setState(() {
        _dataPoints = data;
        _isLoadingChart = false;
      });
    }
  }

  void _setTouchedIndexWithHaptics(int? newIndex) {
    if (newIndex == _touchedIndex) return; // nur bei echter Änderung vibrieren
    _touchedIndex = newIndex;
    if (newIndex != null) {
      HapticFeedback.mediumImpact();
    }
    if (mounted) setState(() {});
  }

  void _handleTouchCallback(FlTouchEvent event, LineTouchResponse? response) {
    if (event is FlPanEndEvent || event is FlTapUpEvent) {
      // Finger losgelassen: Auswahl zurücksetzen (ohne Haptik)
      _touchedIndex = null;
      if (mounted) setState(() {});
      return;
    }

    final spots = response?.lineBarSpots;
    if (spots != null && spots.isNotEmpty) {
      // Index des aktuell getroffenen Punktes
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
        child: Center(child: Text(l10n.chart_no_data_for_period)),
      );
    }

    // Punkt zur Anzeige (entweder getouched oder letzter)
    final int lastIdx = _dataPoints.length - 1;
    final int shownIdx = (_touchedIndex != null &&
            _touchedIndex! >= 0 &&
            _touchedIndex! < _dataPoints.length)
        ? _touchedIndex!
        : lastIdx;

    // 2) Anzeigezeile oben (unverändert)
    final ChartDataPoint displayPoint = _dataPoints[shownIdx];
    final String displayValue =
        '${displayPoint.value.toStringAsFixed(1)} ${widget.unit}';
    final String displayDate = DateFormat.yMMMd().format(displayPoint.date);

    // 1) Basisdaten: auf Tagesgrenzen normalisieren und SPAN berechnen
    final DateTime firstDate = DateTime(
      _dataPoints.first.date.year,
      _dataPoints.first.date.month,
      _dataPoints.first.date.day,
    );
    final DateTime lastDate = DateTime(
      _dataPoints.last.date.year,
      _dataPoints.last.date.month,
      _dataPoints.last.date.day,
    );

    final int spanDays = lastDate.difference(firstDate).inDays;
    final double lastX = spanDays.toDouble();

    // ~6 Labels anpeilen (mind. 1)
    const int desiredLabels = 6;
    final int labelEvery = (spanDays / desiredLabels).ceil().clamp(1, 100000);

    // Kompaktes Datumsformat abhängig von der Spannweite
    String labelFor(DateTime d) {
      if (spanDays > 365 * 2) return DateFormat('yyyy').format(d);
      if (spanDays > 365) return DateFormat('MMM yyyy').format(d);
      if (spanDays > 31) return DateFormat('MMM d').format(d);
      return DateFormat.MMMd().format(d);
    }

    return SizedBox(
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LINKS bündig: Gewicht groß + Datum rechts daneben
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
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),

          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: lastX == 0 ? 1 : lastX, // bei nur einem Punkt min Breite
                clipData: const FlClipData
                    .none(), // vermeidet Clipping am rechten Rand
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    //tooltipBgColor: Colors.transparent,
                    getTooltipItems: (touchedSpots) =>
                        List<LineTooltipItem?>.filled(
                      touchedSpots.length,
                      null,
                      growable: false,
                    ),
                  ),
                  touchCallback: _handleTouchCallback,
                ),

                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: _dataPoints.first.value,
                      color: Colors.grey.withOpacity(0.5),
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
                      // WIR benutzen zusätzlich eine Guard im Builder, damit niemals zu viele Labels erscheinen:
                      interval: 1, // technisch 1, aber wir filtern im Builder
                      getTitlesWidget: (value, meta) {
                        final int v = value.round();

                        // Immer erstes und letztes Label zeigen …
                        final bool isEdge = (v == 0) || (v == spanDays);
                        // … und sonst nur jeden 'labelEvery'-ten Tag
                        final bool show = isEdge || (v % labelEvery == 0);

                        if (!show) return const SizedBox.shrink();

                        final date = firstDate.add(Duration(days: v));
                        return SideTitleWidget(
                          meta: meta,
                          space: 8,
                          child: Text(
                            labelFor(date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _dataPoints.map((p) {
                      final x = DateTime(
                        p.date.year,
                        p.date.month,
                        p.date.day,
                      ).difference(firstDate).inDays.toDouble();
                      return FlSpot(x, p.value);
                    }).toList(),
                    isCurved: false, // gerade Linien
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    // Dot nur beim getouchten Punkt:
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
                          ).colorScheme.primary.withOpacity(0.3),
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.0),
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
}
