import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../statistics/domain/recovery_payload_models.dart';
import '../../../statistics/presentation/statistics_formatter.dart';
import '../statistics_hub_view_model.dart';
import 'analytics_card_base.dart';

class RecoverySectionCard extends StatelessWidget {
  final SectionLoadState<RecoveryAnalyticsPayload> state;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  const RecoverySectionCard({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sectionId = StatisticsHubSectionId.recovery;
    final title = l10n.metricsMuscleReadiness;

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
    final recovering = data?.totals.recovering ?? 0;
    final ready = data?.totals.ready ?? 0;
    final fresh = data?.totals.fresh ?? 0;
    final hasData = data?.hasData ?? false;
    final overallState = data?.overallState ?? '';

    final recoveryHeadline =
        StatisticsPresentationFormatter.recoveryOverallLabel(
      l10n,
      overallState,
    );

    final recoveryStatusSummary = hasData
        ? l10n.recoveryHubCountsSummary(recovering, ready, fresh)
        : l10n.recoveryHubNoDataSummary;

    final iconColor = StatisticsPresentationFormatter.recoveryOverallColor(
      context,
      overallState,
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
                chipText: hasData ? l10n.currentlyTracking : null,
              ),
              Text(
                recoveryHeadline,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                recoveryStatusSummary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              if (hasData) ...[
                const SizedBox(height: 8),
                _buildRecoveryDistributionBar(
                  context,
                  recovering: recovering,
                  ready: ready,
                  fresh: fresh,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecoveryDistributionBar(
    BuildContext context, {
    required int recovering,
    required int ready,
    required int fresh,
  }) {
    final total = recovering + ready + fresh;
    if (total <= 0) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final segments = <MapEntry<int, Color>>[
      MapEntry(recovering, colorScheme.error),
      MapEntry(ready, colorScheme.primary),
      MapEntry(fresh, colorScheme.tertiary),
    ].where((segment) => segment.key > 0).toList(growable: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            for (final segment in segments)
              Expanded(
                flex: segment.key,
                child: ColoredBox(color: segment.value),
              ),
            if (segments.isEmpty)
              Expanded(child: ColoredBox(color: colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}
