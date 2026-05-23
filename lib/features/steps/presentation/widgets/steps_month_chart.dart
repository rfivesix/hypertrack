import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/health/steps_sync_service.dart';
import '../../domain/steps_models.dart';
import 'steps_insight_pill.dart';

class StepsMonthChart extends StatelessWidget {
  const StepsMonthChart({
    super.key,
    required this.buckets,
    required this.dailyGoal,
    this.monthStart,
  });

  final List<StepsBucket> buckets;
  final int dailyGoal;
  final DateTime? monthStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    final numberFormat = NumberFormat.decimalPattern(localeCode);
    final safeGoal =
        dailyGoal > 0 ? dailyGoal : StepsSyncService.defaultStepsGoal;

    final resolvedMonthStart = monthStart ??
        (buckets.isNotEmpty
            ? DateTime(buckets.first.start.year, buckets.first.start.month, 1)
            : DateTime(DateTime.now().year, DateTime.now().month, 1));
    final nextMonth = DateTime(
      resolvedMonthStart.year,
      resolvedMonthStart.month + 1,
      1,
    );
    final daysInMonth = nextMonth.difference(resolvedMonthStart).inDays;
    final leadingEmpty = resolvedMonthStart.weekday - DateTime.monday;

    final byDay = <int, int>{
      for (final bucket in buckets) bucket.start.day: bucket.steps,
    };
    final total = buckets.fold<int>(0, (sum, b) => sum + b.steps);
    final avg = daysInMonth == 0 ? 0 : (total / daysInMonth).round();
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mondayReference = DateTime(2024, 1, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat.yMMMM(localeCode).format(resolvedMonthStart),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StepsInsightPill(
              label: l10n.stepsModuleAvgPerDay,
              value: numberFormat.format(avg),
            ),
            StepsInsightPill(
              label: l10n.stepsModuleGoalDays,
              value: '$goalDays/${buckets.length}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(7, (index) {
            final dayLabel = DateFormat.E(localeCode)
                .format(mondayReference.add(Duration(days: index)))
                .substring(0, 1)
                .toUpperCase();
            return Expanded(
              child: Center(
                child: Text(
                  dayLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          itemCount: leadingEmpty + daysInMonth,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            if (index < leadingEmpty) {
              return const SizedBox.shrink();
            }
            final day = index - leadingEmpty + 1;
            final steps = byDay[day] ?? 0;
            final ratio = (steps / maxValue).clamp(0.0, 1.0);
            final isToday = today.year == resolvedMonthStart.year &&
                today.month == resolvedMonthStart.month &&
                today.day == day;
            final background = Color.lerp(
              Theme.of(context).colorScheme.surfaceContainerHighest,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
              ratio,
            )!;

            return Container(
              decoration: BoxDecoration(
                color: steps == 0
                    ? Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.6)
                    : background,
                borderRadius: BorderRadius.circular(6),
                border: isToday
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: steps == 0
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
