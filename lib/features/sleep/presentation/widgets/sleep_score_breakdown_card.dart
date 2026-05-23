import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';

import '../../../../widgets/common/app_section_header.dart';
import '../../../../widgets/common/glass_progress_bar.dart';
import '../../domain/scoring/sleep_scoring_engine.dart';

class SleepScoreBreakdownCard extends StatelessWidget {
  const SleepScoreBreakdownCard({
    super.key,
    required this.scoringResult,
  });

  final SleepScoringResult scoringResult;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: l10n.sleepDetailAnalysisHeader,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        if (scoringResult.dynamicMultiplier != null &&
            scoringResult.dynamicMultiplier! < 1.0) ...[
          _buildCapBanner(context, l10n),
          const SizedBox(height: 16),
        ],
        GlassProgressBar(
          label: l10n.sleepMetricDurationLabel,
          value: scoringResult.durationScore ?? 0.0,
          target: 100.0,
          unit: '',
          color: const Color(0xFF10B981), // Emerald/Green accent
        ),
        const SizedBox(height: 12),
        GlassProgressBar(
          label: l10n.sleepMetricContinuityLabel,
          value: scoringResult.continuityScore ?? 0.0,
          target: 100.0,
          unit: '',
          color: Colors.blue, // Blue accent
        ),
        const SizedBox(height: 12),
        GlassProgressBar(
          label: l10n.sleepMetricDepthLabel,
          value: scoringResult.architectureScore ?? 0.0,
          target: 100.0,
          unit: '',
          color: Colors.indigo, // Indigo accent
        ),
        const SizedBox(height: 12),
        GlassProgressBar(
          label: l10n.sleepMetricTimingLabel,
          value: scoringResult.timingScore ?? 0.0,
          target: 100.0,
          unit: '',
          color: Colors.amber, // Amber/Yellow accent
        ),
        const SizedBox(height: 12),
        GlassProgressBar(
          label: l10n.sleepMetricRegularityLabel,
          value: scoringResult.regularityScore ?? 0.0,
          target: 100.0,
          unit: '',
          color: Colors.purple, // Purple accent
        ),
      ],
    );
  }

  Widget _buildCapBanner(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String bannerText;
    switch (scoringResult.multiplierBottleneck) {
      case 'tst':
        bannerText = l10n.sleepBannerTstBottleneck;
        break;
      case 'rem':
        bannerText = l10n.sleepBannerRemBottleneck;
        break;
      case 'n3':
        bannerText = l10n.sleepBannerN3Bottleneck;
        break;
      case 'timing':
        bannerText = l10n.sleepBannerTimingBottleneck;
        break;
      default:
        bannerText = l10n.sleepBannerDefaultPenalty;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              bannerText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
