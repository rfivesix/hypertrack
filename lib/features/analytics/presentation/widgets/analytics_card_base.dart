import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
import '../statistics_hub_view_model.dart';

class AnalyticsCardBase {
  static const double chipBackgroundOpacity = 0.14;
  static const double miniBarOpacity = 0.75;

  static Widget buildSectionLoadingCard(
    BuildContext context,
    AppLocalizations l10n,
    StatisticsHubSectionId sectionId,
    String title,
  ) {
    return SummaryCard(
      key: Key('statistics_section_loading_${sectionId.name}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              l10n.load_dots,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildSectionErrorCard(
    BuildContext context,
    AppLocalizations l10n,
    VoidCallback onRetry,
    StatisticsHubSectionId sectionId,
    String title,
  ) {
    return SummaryCard(
      key: Key('statistics_section_error_${sectionId.name}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCardHeading(context, label: title),
            const SizedBox(height: 8),
            Text(
              l10n.error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.sleepStatusTechnicalError,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(MaterialLocalizations.of(context)
                  .refreshIndicatorSemanticLabel),
            ),
          ],
        ),
      ),
    );
  }

  static Widget decorateSectionCard<T>(
    BuildContext context, {
    required SectionLoadState<T> state,
    required Widget child,
  }) {
    if (!state.hasData || (!state.isLoading && !state.hasError)) {
      return child;
    }
    return Stack(
      children: [
        child,
        Positioned(
          top: 10,
          right: 10,
          child: state.isLoading
              ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
        ),
      ],
    );
  }

  static Widget buildCardHeading(
    BuildContext context, {
    required String label,
    String? chipText,
  }) {
    final chipColor = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (chipText != null && chipText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingS,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: chipBackgroundOpacity),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              chipText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }

  static Widget buildHeaderWithChevron(
    BuildContext context, {
    required String label,
    String? chipText,
    bool trailingIcon = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: buildCardHeading(context, label: label, chipText: chipText),
        ),
        if (trailingIcon) ...[
          const SizedBox(width: 8),
          buildDrillDownHint(context),
        ],
      ],
    );
  }

  static Widget buildDrillDownHint(BuildContext context) {
    return Icon(
      Icons.chevron_right,
      size: 18,
      color: Theme.of(context).colorScheme.outline,
    );
  }

  static Widget buildMicroCaption(BuildContext context, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
    );
  }

  static Widget buildRangeChip(BuildContext context, String label) {
    final chipColor = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingS,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: chipBackgroundOpacity),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  static Widget buildMiniBars(
    BuildContext context, {
    required List<double> values,
    required Color color,
    required String semanticsLabel,
  }) {
    final clean = values.where((v) => v.isFinite).toList(growable: false);
    if (clean.isEmpty) return const SizedBox.shrink();
    final max = clean.fold<double>(0, (a, b) => a > b ? a : b);
    final normalized = max <= 0
        ? clean.map((_) => 0.2).toList(growable: false)
        : clean.map((v) => (v / max).clamp(0.08, 1.0)).toList(growable: false);

    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: 20,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final ratio in normalized)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FractionallySizedBox(
                    heightFactor: ratio,
                    alignment: Alignment.bottomCenter,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: miniBarOpacity),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
