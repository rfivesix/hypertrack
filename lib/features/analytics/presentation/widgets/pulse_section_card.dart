import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../pulse/domain/pulse_models.dart';
import '../statistics_hub_view_model.dart';
import 'analytics_card_base.dart';

class PulseSectionCard extends StatelessWidget {
  final SectionLoadState<PulseAnalysisSummary> state;
  final String fallbackRangeLabel;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  const PulseSectionCard({
    super.key,
    required this.state,
    required this.fallbackRangeLabel,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sectionId = StatisticsHubSectionId.pulse;
    final title = l10n.pulseTitle;

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

    final summary = state.data;
    final chipLabel =
        summary == null ? fallbackRangeLabel : _pulseRangeLabel(context, summary);
    final hasMetrics = summary?.hasCoreMetrics ?? false;
    final rangeValue = !hasMetrics
        ? '--'
        : '${summary!.minBpm!.round()}-${summary.maxBpm!.round()} ${l10n.sleepBpmUnit}';
    final averageValue = summary?.averageBpm == null
        ? '--'
        : '${summary!.averageBpm!.round()} ${l10n.sleepBpmUnit}';
    final restingValue = summary?.restingBpm == null
        ? '--'
        : '${summary!.restingBpm!.round()} ${l10n.sleepBpmUnit}';
    final stateText = summary == null
        ? l10n.load_dots
        : summary.hasData
            ? '${l10n.pulseSampleCount(summary.sampleCount)} - ${_pulseQualityLabel(l10n, summary.quality)}'
            : _pulseNoDataMessage(l10n, summary.noDataReason);

    return AnalyticsCardBase.decorateSectionCard(
      context,
      state: state,
      child: SummaryCard(
        key: const Key('statistics_pulse_card'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnalyticsCardBase.buildHeaderWithChevron(
                context,
                label: title,
                chipText: chipLabel,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPulseMetricTile(
                      context, l10n.pulseRangeLabel, rangeValue),
                  _buildPulseMetricTile(
                      context, l10n.pulseAverageLabel, averageValue),
                  _buildPulseMetricTile(
                      context, l10n.pulseRestingLabel, restingValue),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                stateText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _pulseRangeLabel(BuildContext context, PulseAnalysisSummary summary) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final start = summary.window.startUtc.toLocal();
    final endExclusive = summary.window.endUtc.toLocal();
    final end = DateTime(
      endExclusive.year,
      endExclusive.month,
      endExclusive.day,
    ).subtract(const Duration(days: 1));
    final startDay = DateTime(start.year, start.month, start.day);
    final spansYear = startDay.year != end.year;
    final formatter =
        spansYear ? DateFormat.yMMMd(localeCode) : DateFormat.MMMd(localeCode);
    return '${formatter.format(startDay)} - ${formatter.format(end)}';
  }

  Widget _buildPulseMetricTile(
      BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  String _pulseQualityLabel(AppLocalizations l10n, PulseDataQuality quality) {
    return switch (quality) {
      PulseDataQuality.ready => l10n.pulseQualityReady,
      PulseDataQuality.limited => l10n.pulseQualityLimited,
      PulseDataQuality.insufficient => l10n.pulseQualityInsufficient,
      PulseDataQuality.noData => l10n.pulseQualityNoData,
    };
  }

  String _pulseNoDataMessage(AppLocalizations l10n, PulseNoDataReason reason) {
    return switch (reason) {
      PulseNoDataReason.disabled => l10n.pulseNoDataDisabled,
      PulseNoDataReason.permissionDenied => l10n.pulseNoDataPermissionDenied,
      PulseNoDataReason.platformUnavailable => l10n.pulseNoDataUnavailable,
      PulseNoDataReason.queryFailed => l10n.pulseNoDataQueryFailed,
      _ => l10n.pulseNoDataDefault,
    };
  }
}
