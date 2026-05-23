import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../pulse/presentation/pulse_analysis_screen.dart';
import '../../../sleep/presentation/widgets/sleep_period_scope_layout.dart';
import '../diary_view_model.dart';

class PulseSummaryCard extends StatelessWidget {
  const PulseSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DiaryViewModel>();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (viewModel.isPulseWidgetLoading) {
      return SummaryCard(
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: 16.0,
          ),
          title: Text(
            l10n.pulseTitle,
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Text(
            l10n.load_dots,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final summary = viewModel.pulseSummary;
    if (summary == null || !summary.hasData) {
      return const SizedBox.shrink();
    }

    final rangeText = summary.hasCoreMetrics
        ? '${summary.minBpm!.round()}-${summary.maxBpm!.round()} ${l10n.sleepBpmUnit}'
        : '--';
    final restingText = summary.restingBpm != null
        ? '${summary.restingBpm!.round()} ${l10n.sleepBpmUnit}'
        : '--';

    return SummaryCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PulseAnalysisScreen(
                initialDate: viewModel.selectedDate,
                initialScope: SleepPeriodScope.day,
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 16.0,
        ),
        title: Text(
          l10n.pulseTitle,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          '${l10n.pulseRangeLabel}: $rangeText',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.pulseRestingLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  restingText,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}
