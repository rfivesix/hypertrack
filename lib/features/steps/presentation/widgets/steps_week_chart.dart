import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/health/steps_sync_service.dart';
import '../../domain/steps_models.dart';
import 'horizontal_guide_painter.dart';
import 'steps_chart_utils.dart';
import 'steps_insight_pill.dart';

class StepsWeekChart extends StatelessWidget {
  const StepsWeekChart({
    super.key,
    required this.buckets,
    required this.dailyGoal,
    this.weekStart,
  });

  final List<StepsBucket> buckets;
  final int dailyGoal;
  final DateTime? weekStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    final numberFormat = NumberFormat.decimalPattern(localeCode);
    final safeGoal =
        dailyGoal > 0 ? dailyGoal : StepsSyncService.defaultStepsGoal;
    final total = buckets.fold<int>(0, (sum, b) => sum + b.steps);
    final avg = buckets.isEmpty ? 0 : (total / buckets.length).round();
    final goalDays = buckets.where((b) => b.steps >= safeGoal).length;

    int maxValue = safeGoal;
    for (final bucket in buckets) {
      if (bucket.steps > maxValue) {
        maxValue = bucket.steps;
      }
    }
    if (maxValue <= 0) {
      maxValue = 1;
    }
    const weekChartHeight = 172.0;
    const weekChartBottom = weekChartHeight - chartBottomInset;
    const weekDrawableHeight = weekChartBottom - weekChartTopInset;
    final weekGoalRatio = (safeGoal / maxValue).clamp(0.0, 1.0);
    final weekGoalLineY =
        weekChartBottom - (weekDrawableHeight * weekGoalRatio);
    final weekGoalLabelTop =
        (weekGoalLineY - 10).clamp(0.0, weekChartHeight - 16).toDouble();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          weekStart == null
              ? l10n.stepsModuleThisWeek
              : '${DateFormat.MMMd(localeCode).format(weekStart!)} – ${DateFormat.MMMd(localeCode).format(weekStart!.add(const Duration(days: 6)))}',
          style: Theme.of(context).textTheme.titleMedium,
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
              label: l10n.stepsModuleAvgPerDay,
              value: numberFormat.format(avg),
            ),
            StepsInsightPill(
              label: l10n.stepsModuleGoalHit,
              value: '$goalDays/${buckets.length}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: weekChartHeight,
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
                    topInset: weekChartTopInset,
                    bottomInset: chartBottomInset,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: weekGoalLabelTop,
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
                top: ((172 - chartBottomInset - weekChartTopInset) / 2) +
                    weekChartTopInset -
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
                    top: weekChartTopInset,
                    right: 4,
                    bottom: chartBottomInset,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(buckets.length, (index) {
                      final bucket = buckets[index];
                      final ratio = (bucket.steps / maxValue).clamp(0.0, 1.0);
                      final isGoalHit = bucket.steps >= safeGoal;

                      return Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final barHeight = constraints.maxHeight * ratio;
                            return Stack(
                              alignment: Alignment.bottomCenter,
                              clipBehavior: Clip.none,
                              children: [
                                if (bucket.steps <= 0)
                                  Container(
                                    width: 14,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 34,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                if (isGoalHit && bucket.steps > 0)
                                  Positioned(
                                    bottom: barHeight + 2,
                                    child: Container(
                                      width: 13,
                                      height: 13,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Positioned(
                left: chartLeftInset,
                right: 4,
                bottom: 0,
                child: Row(
                  children: List.generate(buckets.length, (index) {
                    final bucket = buckets[index];
                    final day = DateTime(
                      bucket.start.year,
                      bucket.start.month,
                      bucket.start.day,
                    );
                    final isToday = day == today;
                    final label = DateFormat.E(
                      localeCode,
                    ).format(bucket.start).substring(0, 1).toUpperCase();
                    return Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight:
                                    isToday ? FontWeight.w700 : FontWeight.w500,
                                color: isToday
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
