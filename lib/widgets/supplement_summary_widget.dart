import 'package:flutter/material.dart';
import '../models/tracked_supplement.dart';
import 'glass_progress_bar.dart';
import '../theme/color_constants.dart';
import '../util/design_constants.dart';

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
    final brightness = theme.brightness;
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

    final backgroundColor = brightness == Brightness.dark
        ? summaryCardDarkMode
        : summaryCardWhiteMode;

    return Container(
      height: 54,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? Colors.green.shade400 : Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              supplement.getLocalizedName(context),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            displayText,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
