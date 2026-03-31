import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../features/steps/domain/steps_models.dart';
import 'summary_card.dart';

class StatisticsStepsCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final String subtitle;
  final int currentSteps;
  final String currentStepsSubtitle;
  final List<StepsBucket> dailyTotals;
  final int dailyGoal;
  final bool showChevron;

  const StatisticsStepsCard({
    super.key,
    this.onTap,
    required this.title,
    required this.subtitle,
    required this.currentSteps,
    required this.currentStepsSubtitle,
    required this.dailyTotals,
    required this.dailyGoal,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final numberFormat = NumberFormat.decimalPattern();

    return SummaryCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (showChevron) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Body: 2 columns
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Left Column: Huge numbers
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        numberFormat.format(currentSteps),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        currentStepsSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right Column: Bar Chart
                Expanded(
                  flex: 3,
                  child: SizedBox(height: 84, child: _buildBarChart(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    if (dailyTotals.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final chartBuckets = _normalizedBucketsForDisplay();

    // Find max value to scale bars
    int maxValue = dailyGoal;
    for (final bucket in chartBuckets) {
      if (bucket.steps > maxValue) {
        maxValue = bucket.steps;
      }
    }
    if (maxValue == 0) maxValue = 1000; // fallback

    final isSevenDays = chartBuckets.length <= 7;
    final singlePoint = chartBuckets.length == 1;
    final showWeekDecorations = isSevenDays && !singlePoint;
    final topMargin = showWeekDecorations ? 12.0 : 0.0;
    final bottomMargin = showWeekDecorations ? 18.0 : 0.0;
    const axisInset = 34.0;
    final goalRatio = (dailyGoal / maxValue).clamp(0.0, 1.0);
    final averageSteps =
        chartBuckets.fold<int>(0, (sum, bucket) => sum + bucket.steps) ~/
        chartBuckets.length;
    final averageRatio = (averageSteps / maxValue).clamp(0.0, 1.0);
    final showAverageLine =
        showWeekDecorations && averageSteps > 0 && (averageSteps != dailyGoal);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Stack(
      children: [
        // Goal dashed line — drawn behind the bars
        Positioned.fill(
          child: CustomPaint(
            painter: _DashedLinePainter(
              color: primaryColor.withValues(alpha: 0.4),
              yRatio: goalRatio,
              topMargin: topMargin,
              bottomMargin: bottomMargin,
              leftInset: axisInset,
            ),
          ),
        ),
        if (showAverageLine)
          Positioned.fill(
            child: CustomPaint(
              painter: _DashedLinePainter(
                color: theme.colorScheme.outline.withValues(alpha: 0.35),
                yRatio: averageRatio,
                topMargin: topMargin,
                bottomMargin: bottomMargin,
                leftInset: axisInset,
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final goalY = _goalLineY(
                  totalHeight: constraints.maxHeight,
                  ratio: goalRatio,
                  topMargin: topMargin,
                  bottomMargin: bottomMargin,
                );
                final avgY = _goalLineY(
                  totalHeight: constraints.maxHeight,
                  ratio: averageRatio,
                  topMargin: topMargin,
                  bottomMargin: bottomMargin,
                );
                final goalTop = (goalY - 8).clamp(
                  0.0,
                  constraints.maxHeight - 16,
                );
                final avgTop = (avgY - 8).clamp(
                  0.0,
                  constraints.maxHeight - 16,
                );
                final showAverageLabel =
                    showAverageLine && (goalTop - avgTop).abs() > 12;
                return Stack(
                  children: [
                    Positioned(
                      top: goalTop,
                      left: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          child: Text(
                            _compactAxisLabel(
                              dailyGoal > 0 ? dailyGoal : maxValue,
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (showAverageLabel)
                      Positioned(
                        top: avgTop,
                        left: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            child: Text(
                              'Ø ${_compactAxisLabel(averageSteps)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        // Bars
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(left: axisInset),
            child: Row(
              mainAxisAlignment: isSevenDays
                  ? MainAxisAlignment.spaceEvenly
                  : MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(chartBuckets.length, (index) {
                final bucket = chartBuckets[index];
                final bucketDay = DateTime(
                  bucket.start.year,
                  bucket.start.month,
                  bucket.start.day,
                );
                final isToday = bucketDay == today;
                final double heightRatio = (bucket.steps / maxValue).clamp(
                  0.0,
                  1.0,
                );
                final bool metGoal = bucket.steps >= dailyGoal && dailyGoal > 0;
                final barColor = bucket.steps <= 0
                    ? theme.colorScheme.outlineVariant
                    : primaryColor;
                final barWidth = singlePoint
                    ? 12.0
                    : (isSevenDays ? 14.0 : 5.0);

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSevenDays ? 3.0 : 1.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Goal marker for week cards.
                        if (showWeekDecorations)
                          SizedBox(
                            height: 12,
                            child: metGoal
                                ? Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 9,
                                      color: Colors.white,
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                        // Bar body.
                        Expanded(
                          child: bucket.steps <= 0
                              ? Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: singlePoint
                                        ? 8
                                        : (isSevenDays ? 10 : 4),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.outlineVariant,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                )
                              : FractionallySizedBox(
                                  heightFactor: heightRatio,
                                  alignment: Alignment.bottomCenter,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: SizedBox(
                                      width: barWidth,
                                      height: double.infinity,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: barColor,
                                          borderRadius: BorderRadius.circular(
                                            isSevenDays ? 4 : 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        // Weekday label
                        if (showWeekDecorations) ...[
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.E()
                                .format(bucket.start)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: isToday
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  List<StepsBucket> _normalizedBucketsForDisplay() {
    if (dailyTotals.isEmpty) return dailyTotals;
    final isTodaySubtitle = _isTodayLabel(currentStepsSubtitle);
    final isSevenDays = dailyTotals.length <= 7;
    final canInjectToday =
        isTodaySubtitle && isSevenDays && dailyTotals.length > 1;
    if (!canInjectToday) return dailyTotals;
    final mutable = List<StepsBucket>.from(dailyTotals);
    final last = mutable.last;
    mutable[mutable.length - 1] = StepsBucket(
      start: last.start,
      steps: currentSteps,
    );
    return mutable;
  }

  bool _isTodayLabel(String text) {
    final lower = text.toLowerCase();
    return lower.contains('today') || lower.contains('heute');
  }

  double _goalLineY({
    required double totalHeight,
    required double ratio,
    required double topMargin,
    required double bottomMargin,
  }) {
    final drawingHeight = totalHeight - topMargin - bottomMargin;
    return totalHeight - bottomMargin - (drawingHeight * ratio);
  }

  String _compactAxisLabel(int value) {
    if (value >= 10000) {
      return '${(value / 1000).round()}k';
    }
    if (value >= 1000) {
      final truncated = (value / 1000).toStringAsFixed(1);
      return truncated.endsWith('.0')
          ? '${truncated.substring(0, truncated.length - 2)}k'
          : '${truncated}k';
    }
    return value.toString();
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double yRatio; // 0.0 is bottom, 1.0 is top
  final double topMargin;
  final double bottomMargin;
  final double leftInset;

  _DashedLinePainter({
    required this.color,
    required this.yRatio,
    required this.topMargin,
    required this.bottomMargin,
    required this.leftInset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final drawingHeight = size.height - topMargin - bottomMargin;
    final y = size.height - bottomMargin - (drawingHeight * yRatio);
    final width = size.width;

    var startX = leftInset;
    while (startX < width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + 4, y), paint);
      startX += 8; // dash + space
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.yRatio != yRatio ||
        oldDelegate.color != color ||
        oldDelegate.topMargin != topMargin ||
        oldDelegate.bottomMargin != bottomMargin ||
        oldDelegate.leftInset != leftInset;
  }
}
