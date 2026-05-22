import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../domain/sleep_domain.dart';
import '../../data/sleep_day_repository.dart';
import '../sleep_navigation.dart';

class SleepMetricTileGrid extends StatelessWidget {
  const SleepMetricTileGrid({super.key, required this.overview});

  final SleepDayOverviewData overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final regularitySubtitle = overview.regularityNights.isEmpty
        ? l10n.sleepMetricUnavailable
        : l10n.sleepRegularityNightView(
            overview.regularityNights.length.clamp(0, 7),
          );
    return GridView.count(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      children: [
        _MetricTile(
          title: l10n.sleepMetricDurationTitle,
          subtitle:
              '${overview.totalSleepDuration.inHours}h ${overview.totalSleepDuration.inMinutes.remainder(60)}m',
          onTap: () =>
              SleepNavigation.openDurationDetail(context, overview: overview),
        ),
        _MetricTile(
          title: l10n.sleepMetricHeartRateTitle,
          subtitle: overview.sleepHrAvg == null
              ? l10n.sleepMetricUnavailable
              : '${overview.sleepHrAvg!.round()} ${l10n.sleepBpmUnit}',
          onTap: () =>
              SleepNavigation.openHeartRateDetail(context, overview: overview),
        ),
        _MetricTile(
          title: l10n.sleepMetricRegularityTitle,
          subtitle: regularitySubtitle,
          onTap: () =>
              SleepNavigation.openRegularityDetail(context, overview: overview),
        ),
        _MetricTile(
          title: l10n.sleepMetricDepthTitle,
          subtitle: overview.stageDataConfidence == SleepStageConfidence.low
              ? l10n.sleepMetricDepthLowConfidence
              : (overview.hasStageData
                  ? l10n.sleepMetricDepthStagesAvailable
                  : l10n.sleepMetricUnavailable),
          onTap: () =>
              SleepNavigation.openDepthDetail(context, overview: overview),
        ),
        _MetricTile(
          title: l10n.sleepMetricInterruptionsTitle,
          subtitle: overview.interruptionsCount == null
              ? l10n.sleepMetricUnavailable
              : '${overview.interruptionsCount}',
          onTap: () => SleepNavigation.openInterruptionsDetail(
            context,
            overview: overview,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
