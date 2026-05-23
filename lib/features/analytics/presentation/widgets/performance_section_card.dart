import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../statistics_hub_view_model.dart';
import 'analytics_card_base.dart';

class PerformanceSectionCard extends StatelessWidget {
  final SectionLoadState<PerformanceRecordsSectionData> state;
  final String chipText;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  const PerformanceSectionCard({
    super.key,
    required this.state,
    required this.chipText,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sectionId = StatisticsHubSectionId.performanceRecords;
    final title = l10n.exerciseAnalyticsTitle;

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
    final notableImprovements = data?.notableImprovements ?? const [];

    final topImprovement = notableImprovements.isNotEmpty
        ? notableImprovements.first
        : null;
    final momentumValue = topImprovement == null
        ? '-'
        : '+${((topImprovement['improvementPct'] as num).toDouble()).toStringAsFixed(1)}%';
    final topExerciseName = topImprovement == null
        ? l10n.metricsMostImproved
        : (topImprovement['exerciseName'] as String? ??
            l10n.metricsMostImproved);
    final performanceSummaryText = notableImprovements.isEmpty
        ? l10n.exerciseAnalyticsNoData
        : '${l10n.analyticsRecentRecords}: ${notableImprovements.length}';
    final compactSignals = notableImprovements
        .map((row) => ((row['improvementPct'] as num?) ?? 0).toDouble())
        .toList(growable: false);
    final momentumColor = topImprovement == null
        ? Theme.of(context).colorScheme.outline
        : Theme.of(context).colorScheme.primary;

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
                chipText: chipText,
              ),
              const SizedBox(height: 4),
              Text(
                topExerciseName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                momentumValue,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: momentumColor,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                performanceSummaryText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 8),
              AnalyticsCardBase.buildMicroCaption(context, l10n.analyticsRecentRecords),
              const SizedBox(height: 4),
              AnalyticsCardBase.buildMiniBars(
                context,
                values: compactSignals,
                color: Theme.of(context).colorScheme.primary,
                semanticsLabel: title,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
