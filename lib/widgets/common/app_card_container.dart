import 'package:flutter/material.dart';
import '../../util/design_constants.dart';
import 'summary_card.dart';

/// A thin wrapper around [SummaryCard] that applies the app's standard card
/// layout tokens: padding, margin, and optional tap handling.
///
/// Use this when building content cards (meal entries, metric panels, etc.)
/// to guarantee visual consistency without repeating padding/radius boilerplate.
///
/// This widget delegates all visual rendering to [SummaryCard], which owns the
/// background color, border radius, shadow, and border logic for both light and
/// dark themes. [AppCardContainer] simply provides ergonomic defaults.
class AppCardContainer extends StatelessWidget {
  /// The main content to display inside the card.
  final Widget child;

  /// Internal padding for the [child]. Defaults to [DesignConstants.cardContentPadding].
  final EdgeInsetsGeometry? padding;

  /// Optional margin around the card. Defaults to [DesignConstants.cardMargin].
  final EdgeInsetsGeometry? margin;

  /// Optional tap handler.
  final VoidCallback? onTap;

  const AppCardContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
      padding: padding ?? DesignConstants.cardContentPadding,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6.0),
      onTap: onTap,
      child: child,
    );
  }
}
