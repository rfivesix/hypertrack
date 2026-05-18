import 'package:flutter/material.dart';
import '../../util/design_constants.dart';

/// A compact, left-aligned metadata row that joins items with the " • " separator.
///
/// Used in meal cards, fluid summaries, and food entry tiles to display
/// bulleted lists of values (e.g. "120 kcal • 30g P • 20g C • 15g F").
///
/// The widget automatically uses the theme's `bodyMedium` text style with a
/// subdued color (matching `bodySmall`'s color) to ensure consistency with the
/// diary screen's perfected design.
///
/// ```dart
/// AppMetadataRow(items: ['120 kcal', '30g P', '20g C', '15g F'])
/// ```
class AppMetadataRow extends StatelessWidget {
  /// Individual metadata values to join with the bullet separator.
  final List<String> items;

  /// Optional alignment override. Defaults to [Alignment.centerLeft].
  final AlignmentGeometry alignment;

  /// Optional text style override. When null, uses the theme default.
  final TextStyle? style;

  const AppMetadataRow({
    super.key,
    required this.items,
    this.alignment = Alignment.centerLeft,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final effectiveStyle = style ??
        theme.textTheme.bodyMedium?.copyWith(
          color: theme.textTheme.bodySmall?.color,
        );

    return Align(
      alignment: alignment,
      child: Text(
        items.join(DesignConstants.metadataSeparator),
        style: effectiveStyle,
      ),
    );
  }
}
