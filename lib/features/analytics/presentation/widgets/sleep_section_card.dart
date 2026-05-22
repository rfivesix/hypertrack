import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../sleep/data/sleep_hub_summary_repository.dart';
import '../statistics_hub_view_model.dart';
import 'analytics_card_base.dart';

class SleepSectionCard extends StatelessWidget {
  final SectionLoadState<SleepHubSummary> state;
  final String rangeLabel;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  const SleepSectionCard({
    super.key,
    required this.state,
    required this.rangeLabel,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sectionId = StatisticsHubSectionId.sleep;
    final title = l10n.sleepHubScoreLabel;

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
    final score = summary?.averageScore;
    final scoreText = score == null ? '--' : score.round().toString();
    final scoreValue =
        score == null ? 0.0 : (score.clamp(0.0, 100.0) / 100.0).toDouble();
    final durationText = _formatSleepDuration(l10n, summary?.averageDuration);
    final bedtimeText = _formatBedtime(summary?.averageBedtimeMinutes);
    final interruptionsCount = summary?.averageInterruptions?.round();
    final interruptionsValue =
        interruptionsCount == null ? '--' : interruptionsCount.toString();
    final interruptionsSubtitle =
        (interruptionsCount == null || summary?.averageWakeDuration == null)
            ? l10n.sleepHubAverageLabel
            : l10n.sleepHubInterruptionsSummary(
                interruptionsCount,
                _formatSleepDuration(l10n, summary!.averageWakeDuration),
              );

    return AnalyticsCardBase.decorateSectionCard(
      context,
      state: state,
      child: SummaryCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  AnalyticsCardBase.buildRangeChip(context, rangeLabel),
                  const SizedBox(width: 8),
                  AnalyticsCardBase.buildDrillDownHint(context),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildSleepScoreRing(
                    context,
                    scoreValue: scoreValue,
                    scoreText: scoreText,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sleepHubScoreLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.sleepMeanScoreLabel(scoreText),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSleepMetricRow(
                context,
                color: Theme.of(context).colorScheme.primary,
                label: l10n.durationLabel,
                value: durationText,
                subtitle: l10n.sleepHubAverageLabel,
              ),
              const Divider(height: 20),
              _buildSleepMetricRow(
                context,
                color: Theme.of(context).colorScheme.tertiary,
                label: l10n.sleepHubBedtimeLabel,
                value: bedtimeText,
                subtitle: l10n.sleepHubAverageLabel,
              ),
              const Divider(height: 20),
              _buildSleepMetricRow(
                context,
                color: Theme.of(context).colorScheme.error,
                label: l10n.sleepHubInterruptionsLabel,
                value: interruptionsValue,
                subtitle: interruptionsSubtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSleepScoreRing(
    BuildContext context, {
    required double scoreValue,
    required String scoreText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 72,
      width: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 72,
            width: 72,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          SizedBox(
            height: 72,
            width: 72,
            child: CircularProgressIndicator(
              value: scoreValue,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              backgroundColor: Colors.transparent,
            ),
          ),
          Text(
            scoreText,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepMetricRow(
    BuildContext context, {
    required Color color,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          height: 10,
          width: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
            ],
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatSleepDuration(AppLocalizations l10n, Duration? value) {
    if (value == null) return '--';
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _formatBedtime(int? minutes) {
    if (minutes == null) return '--';
    final normalized = minutes % 1440;
    final dateTime = DateTime(2020, 1, 1, normalized ~/ 60, normalized % 60);
    return DateFormat.Hm().format(dateTime);
  }
}
