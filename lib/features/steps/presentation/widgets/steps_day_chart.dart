import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/health/steps_sync_service.dart';
import '../../domain/steps_models.dart';
import 'horizontal_guide_painter.dart';
import 'steps_chart_utils.dart';
import 'steps_insight_pill.dart';

class StepsDayChart extends StatelessWidget {
  const StepsDayChart({
    super.key,
    required this.buckets,
    required this.dailyGoal,
    this.date,
  });

  final List<StepsBucket> buckets;
  final int dailyGoal;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    final numberFormat = NumberFormat.decimalPattern(localeCode);
    final total = buckets.fold<int>(0, (sum, b) => sum + b.steps);
    final activeHours = buckets.where((b) => b.steps > 0).length;
    final safeGoal =
        dailyGoal > 0 ? dailyGoal : StepsSyncService.defaultStepsGoal;

    StepsBucket? peakBucket;
    for (final bucket in buckets) {
      if (peakBucket == null || bucket.steps > peakBucket.steps) {
        peakBucket = bucket;
      }
    }

    int maxValue = 0;
    for (final bucket in buckets) {
      if (bucket.steps > maxValue) {
        maxValue = bucket.steps;
      }
    }
    if (maxValue <= 0) {
      maxValue = 2000;
    } else {
      maxValue = ((maxValue + 1999) ~/ 2000) * 2000;
    }
    const dayChartHeight = 160.0;
    const dayChartBottom = dayChartHeight - chartBottomInset;
    const dayDrawableHeight = dayChartBottom - chartTopInset;
    final dayGoalRatio = (safeGoal / maxValue).clamp(0.0, 1.0);
    final dayGoalLineY = dayChartBottom - (dayDrawableHeight * dayGoalRatio);
    final dayGoalLabelTop =
        (dayGoalLineY - 10).clamp(0.0, dayChartHeight - 16).toDouble();

    final peakText = peakBucket == null || peakBucket.steps <= 0
        ? '-'
        : '${DateFormat.Hm(localeCode).format(peakBucket.start)} • ${numberFormat.format(peakBucket.steps)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.stepsModuleHourlyTimeline,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (date != null)
          Text(
            DateFormat.MMMd(localeCode).format(date!),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StepsInsightPill(
              label: l10n.stepsModuleTotal,
              value: numberFormat.format(total),
            ),
            StepsInsightPill(
              label: l10n.stepsModuleActiveHours,
              value: activeHours.toString(),
            ),
            StepsInsightPill(
              label: l10n.stepsModulePeakHour,
              value: peakText,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: dayChartHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: HorizontalGuidePainter(
                    lineColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    goalColor: Theme.of(context).colorScheme.primary,
                    goalRatio: (safeGoal / maxValue).clamp(0.0, 1.0),
                    leftInset: chartLeftInset,
                    topInset: chartTopInset,
                    bottomInset: chartBottomInset,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: dayGoalLabelTop,
                child: Text(
                  compactAxisLabel(maxValue),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Positioned(
                left: 0,
                top: ((160 - chartBottomInset - chartTopInset) / 2) +
                    chartTopInset -
                    8,
                child: Text(
                  compactAxisLabel((maxValue / 2).round()),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: chartLeftInset,
                    top: chartTopInset,
                    right: 4,
                    bottom: chartBottomInset,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: buckets.map((bucket) {
                      final ratio = (bucket.steps / maxValue).clamp(
                        0.0,
                        1.0,
                      );
                      return Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final barHeight = constraints.maxHeight * ratio;
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: bucket.steps <= 0
                                  ? Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : Container(
                                      width: 6,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(
                                          4,
                                        ),
                                      ),
                                    ),
                            );
                          },
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ),
              ),
              Positioned(
                left: chartLeftInset,
                right: 4,
                bottom: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '00',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      '06',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      '12',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      '18',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      '24',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
