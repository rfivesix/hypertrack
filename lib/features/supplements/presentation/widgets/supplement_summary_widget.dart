import 'package:flutter/material.dart';
import '../../domain/models/tracked_supplement.dart';
import '../../../../widgets/common/glass_progress_bar.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../../util/design_constants.dart';

/// A widget that displays a list of tracked supplements for the current day.
///
/// Groups supplements into those with daily goals (checkmarks) and those with
/// daily limits (progress bars).
class SupplementSummaryWidget extends StatelessWidget {
  /// The list of supplement tracking data.
  final List<TrackedSupplement> trackedSupplements;

  /// Callback when the widget is tapped, usually opens tracking management.
  final VoidCallback onTap;

  const SupplementSummaryWidget({
    super.key,
    required this.trackedSupplements,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final goalOnlySupplements = trackedSupplements
        .where(
          (ts) =>
              ts.supplement.dailyGoal != null &&
              ts.supplement.dailyLimit == null,
        )
        .toList();

    final progressSupplements = trackedSupplements
        .where((ts) => ts.supplement.dailyLimit != null)
        .toList();

    if (goalOnlySupplements.isEmpty && progressSupplements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ...goalOnlySupplements.map(
          (ts) => GestureDetector(
            onTap: onTap,
            child: _CheckmarkCard(trackedSupplement: ts),
          ),
        ),
        ...progressSupplements.map((ts) {
          final supplement = ts.supplement;
          return GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: GlassProgressBar(
                label: supplement.getLocalizedName(context),
                unit: supplement.unit,
                value: ts.totalDosedToday,
                target: supplement.dailyLimit!,
                color: Colors.amber.shade600,
                height: 54,
                borderRadius: DesignConstants.borderRadiusL,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _CheckmarkCard extends StatelessWidget {
  final TrackedSupplement trackedSupplement;
  const _CheckmarkCard({required this.trackedSupplement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supplement = trackedSupplement.supplement;
    final doseTaken = trackedSupplement.totalDosedToday;
    final isDone = doseTaken > 0;

    final String displayText;
    if (isDone) {
      displayText =
          '${doseTaken.toStringAsFixed(1).replaceAll('.0', '')} ${supplement.unit}';
    } else {
      displayText =
          '${supplement.dailyGoal?.toStringAsFixed(1).replaceAll('.0', '') ?? ''} ${supplement.unit}';
    }
    return SummaryCard(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.56),
              size: 20,
            ),
            const SizedBox(width: DesignConstants.spacingM),
            Expanded(
              child: Text(
                supplement.getLocalizedName(context),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              displayText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
