import 'package:flutter/material.dart';
import '../../util/design_constants.dart';

/// A standardized section header enforcing the perfected diary screen style:
/// muted, uppercase, bold text with 1.0 letter spacing.
///
/// This replaces the duplicated `_buildSectionTitle` methods scattered across
/// 20+ screen files, ensuring consistent visual hierarchy app-wide.
///
/// By default, the text is automatically uppercased. Set [autoUpperCase] to
/// `false` if the label string is already uppercased (e.g. from a localization
/// key ending in `CL` / `CAPSLOCK`).
class AppSectionHeader extends StatelessWidget {
  /// The section title text.
  final String title;

  /// Whether to automatically uppercase the title. Defaults to `true`.
  final bool autoUpperCase;

  /// Optional padding override. Defaults to [DesignConstants.sectionHeaderPadding].
  final EdgeInsetsGeometry? padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.autoUpperCase = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = autoUpperCase ? title.toUpperCase() : title;

    return Padding(
      padding: padding ?? DesignConstants.sectionHeaderPadding,
      child: Text(
        displayText,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: DesignConstants.sectionHeaderFontWeight,
          letterSpacing: DesignConstants.sectionHeaderLetterSpacing,
        ),
      ),
    );
  }
}
