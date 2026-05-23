import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../statistics_hub_view_model.dart';
import 'analytics_card_base.dart';

class ConsistencySectionCard extends StatelessWidget {
  final SectionLoadState<ConsistencySectionData> state;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  static const int _fixedConsistencyWeeks = 6;
  static const int _miniSignalPoints = 8;

  const ConsistencySectionCard({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sectionId = StatisticsHubSectionId.consistency;
    final title = l10n.workoutsPerWeekLabel;

    if (state.isLoading && !state.hasData) {
      return AnalyticsCardBase.buildSectionLoadingCard(
        context,
        l10n,
        sectionId,
        title,
      );
    }
    if (state.hasError && !state.hasData) {
      return AnalyticsCardBase.buildSectionErrorCard(
        context,
        l10n,
        onRetry,
        sectionId,
        title,
      );
    }

    final data = state.data;
    final workoutsPerWeek = data?.workoutsPerWeek ?? const [];
    final trainingStats = data?.trainingStats;

    final counts = workoutsPerWeek
        .map((w) => ((w['count'] as num?) ?? 0).toDouble())
        .toList(growable: false);
    final avgWorkouts = counts.isEmpty
        ? '-'
        : (counts.reduce((a, b) => a + b) / counts.length).toStringAsFixed(1);
    final weeklyTrend = counts.toList(growable: false);
    final streakText = trainingStats == null
        ? '${l10n.metricsCurrentStreak}: -'
        : '${l10n.metricsCurrentStreak}: ${trainingStats.streakWeeks} ${l10n.metricsActiveWeeks}';

    return AnalyticsCardBase.decorateSectionCard(
      context,
      state: state,
      child: SummaryCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnalyticsCardBase.buildHeaderWithChevron(
                context,
                label: title,
                chipText: _fixedWeeksChipLabel(l10n, _fixedConsistencyWeeks),
              ),
              const SizedBox(height: 4),
              Text(
                avgWorkouts == '-' ? '-' : _formatPerWeek(l10n, avgWorkouts),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                streakText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 8),
              AnalyticsCardBase.buildMicroCaption(
                context,
                '${l10n.analyticsRollingConsistency} • ${_fixedWeeksChipLabel(l10n, _fixedConsistencyWeeks)}',
              ),
              const SizedBox(height: 4),
              AnalyticsCardBase.buildMiniBars(
                context,
                values:
                    weeklyTrend.take(_miniSignalPoints).toList(growable: false),
                color: Theme.of(context).colorScheme.primary,
                semanticsLabel: l10n.sectionConsistency,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPerWeek(AppLocalizations l10n, String valueText) {
    return '$valueText / ${l10n.analyticsPerWeekAbbrev}';
  }

  String _fixedWeeksChipLabel(AppLocalizations l10n, int weeks) {
    return '$weeks ${l10n.weeksLabel}';
  }
}
