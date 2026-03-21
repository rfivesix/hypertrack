import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../features/statistics/domain/analytics_state.dart';
import '../generated/app_localizations.dart';

class AnalyticsChartDefaults {
  static const FlGridData compactGrid =
      FlGridData(show: true, drawVerticalLine: false);
  static const FlGridData noGrid = FlGridData(show: false);
  static const FlBorderData noBorder = FlBorderData(show: false);

  static const FlTitlesData hiddenTitles = FlTitlesData(
    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );

  static FlTitlesData standardTitles({
    required AxisTitles leftTitles,
    required AxisTitles bottomTitles,
  }) {
    return FlTitlesData(
      leftTitles: leftTitles,
      bottomTitles: bottomTitles,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  static LineChartBarData straightLine({
    required List<FlSpot> spots,
    required Color color,
    double barWidth = 2.5,
    bool showDots = false,
    BarAreaData? belowBarData,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      barWidth: barWidth,
      color: color,
      dotData: FlDotData(show: showDots),
      belowBarData: belowBarData ?? BarAreaData(show: false),
    );
  }

  static Widget axisTitleLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  static Widget tickLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall,
    );
  }

  static Widget stateView({
    required BuildContext context,
    required AppLocalizations l10n,
    required AnalyticsStatus status,
    String? emptyLabel,
    String? insufficientLabel,
    String? errorLabel,
    TextAlign textAlign = TextAlign.center,
    double? height,
  }) {
    final text = switch (status) {
      AnalyticsStatus.loading => null,
      AnalyticsStatus.empty => emptyLabel ?? l10n.chart_no_data_for_period,
      AnalyticsStatus.insufficient =>
        insufficientLabel ?? l10n.analyticsInsightNotEnoughData,
      AnalyticsStatus.error => errorLabel ?? l10n.error,
      AnalyticsStatus.ready => null,
    };

    if (status == AnalyticsStatus.loading) {
      final loading = const Center(child: CircularProgressIndicator());
      return height == null ? loading : SizedBox(height: height, child: loading);
    }

    if (text == null) return const SizedBox.shrink();

    final label = Center(
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      ),
    );

    if (height == null) return label;
    return SizedBox(height: height, child: label);
  }
}
