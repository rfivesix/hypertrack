import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../statistics/presentation/statistics_formatter.dart';
import '../statistics_hub_view_model.dart';
import 'analytics_card_base.dart';

class MuscleVolumeSectionCard extends StatelessWidget {
  final SectionLoadState<VolumeMusclesSectionData> state;
  final String rangeLabel;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  const MuscleVolumeSectionCard({
    super.key,
    required this.state,
    required this.rangeLabel,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sectionId = StatisticsHubSectionId.volumeMuscles;
    final title = l10n.analyticsMuscleTopFrequency;

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
    final muscleAnalytics = data?.muscleAnalytics ?? const {};

    final muscles =
        (muscleAnalytics['muscles'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .where(
              (m) => !StatisticsPresentationFormatter.isOtherCategoryLabel(
                m['muscleGroup'] as String?,
              ),
            )
            .toList(growable: false);
    final topMuscle = muscles.isNotEmpty ? muscles.first : null;
    final topMuscleShare =
        (topMuscle?['distributionShare'] as num?)?.toDouble() ?? 0.0;
    final topMuscleFrequency = topMuscle == null
        ? l10n.exerciseAnalyticsNoData
        : _formatPerWeek(
            l10n,
            (topMuscle['frequencyPerWeek'] as num).toDouble().toStringAsFixed(
                  1,
                ),
          );

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
                trailingIcon: true,
                chipText: topMuscle == null
                    ? null
                    : '${(topMuscleShare * 100).toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 4),
              Text(
                _formatMuscleLabel(l10n, topMuscle?['muscleGroup'] as String?),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                topMuscleFrequency,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              if (topMuscleShare > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: topMuscleShare.clamp(0.0, 1.0),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              AnalyticsCardBase.buildMicroCaption(context, rangeLabel),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPerWeek(AppLocalizations l10n, String valueText) {
    return '$valueText / ${l10n.analyticsPerWeekAbbrev}';
  }

  String _formatMuscleLabel(AppLocalizations l10n, String? label) {
    if (label == null || label.trim().isEmpty) {
      return _noClearFocusLabel(l10n);
    }
    final normalized = label.trim();
    if (StatisticsPresentationFormatter.isOtherCategoryLabel(normalized)) {
      return _noClearFocusLabel(l10n);
    }
    return normalized;
  }

  String _noClearFocusLabel(AppLocalizations l10n) {
    final source = l10n.analyticsGuidanceNoClearWeakPoint;
    final stripped = source.replaceFirst(RegExp(r'^[^:]+:\s*'), '');
    return stripped.trim().isEmpty ? source : stripped.trim();
  }
}
