import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../domain/sleep_domain.dart';
import '../../data/sleep_day_repository.dart';

class SleepScoreCard extends StatelessWidget {
  const SleepScoreCard({super.key, required this.overview});

  final SleepDayOverviewData overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final score = overview.analysis.score;
    final scoreText = score == null ? '--' : score.round().toString();
    final quality = overview.analysis.sleepQuality;
    final completeness = overview.analysis.scoreCompleteness;
    final regularityDays = overview.analysis.regularityValidDays ?? 0;
    final regularityUsed = overview.analysis.regularitySri != null;
    final regularityStable = overview.analysis.regularityStable == true;
    final subtitle = overview.analysis.score == null
        ? l10n.sleepScoreUnavailableForNight
        : _qualitySubtitle(
            l10n,
            quality,
            regularityUsed: regularityUsed,
            regularityStable: regularityStable,
            regularityDays: regularityDays,
          );
    final completenessText = completeness == null
        ? l10n.sleepScoreCompletenessLabel('--')
        : l10n.sleepScoreCompletenessLabel('${(completeness * 100).round()}%');
    return SummaryCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score == null
                        ? 0
                        : (score.clamp(0.0, 100.0) / 100.0).toDouble(),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    color: _qualityColor(quality),
                  ),
                  Text(scoreText),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.sleepScoreCardTitle),
                  Text(
                    _qualityLabel(l10n, quality),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(subtitle),
                  Text(completenessText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _qualityColor(SleepQualityBucket quality) {
    return switch (quality) {
      SleepQualityBucket.good => Colors.green,
      SleepQualityBucket.average => Colors.orange,
      SleepQualityBucket.poor => Colors.red,
      SleepQualityBucket.unavailable => Colors.grey,
    };
  }

  String _qualityLabel(AppLocalizations l10n, SleepQualityBucket quality) {
    return switch (quality) {
      SleepQualityBucket.good => l10n.sleepQualityGood,
      SleepQualityBucket.average => l10n.sleepQualityAverage,
      SleepQualityBucket.poor => l10n.sleepQualityPoor,
      SleepQualityBucket.unavailable => l10n.sleepQualityUnavailable,
    };
  }

  String _qualitySubtitle(
    AppLocalizations l10n,
    SleepQualityBucket quality, {
    required bool regularityUsed,
    required bool regularityStable,
    required int regularityDays,
  }) {
    final qualityText = switch (quality) {
      SleepQualityBucket.good => l10n.sleepQualitySubtitleGood,
      SleepQualityBucket.average => l10n.sleepQualitySubtitleAverage,
      SleepQualityBucket.poor => l10n.sleepQualitySubtitlePoor,
      SleepQualityBucket.unavailable => l10n.sleepQualitySubtitleUnavailable,
    };
    if (!regularityUsed) {
      return '$qualityText ${l10n.sleepQualityRegularityNotContributing}';
    }
    if (!regularityStable) {
      return '$qualityText ${l10n.sleepQualityRegularityPreliminary}';
    }
    return '$qualityText ${l10n.sleepQualityRegularityStable(regularityDays)}';
  }
}
