//lib/widgets/frosted_container.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../util/design_constants.dart';

/// A container widget that applies a frosted glass (blur) effect to its background.
///
/// Typical use case is for overlays or premium-feeling card backgrounds.
class FrostedContainer extends StatelessWidget {
  /// The [child] widget to display inside the container.
  final Widget child;

  /// External [margin] around the container.
  final EdgeInsetsGeometry margin;

  /// Internal [padding] for the [child].
  final EdgeInsetsGeometry padding;

  /// The corner [radius] of the container.
  final double radius;

  /// The [blurSigma] controlling the intensity of the frost effect.
  final double blurSigma;

  const FrostedContainer({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(
      horizontal: DesignConstants.screenPaddingHorizontal,
      vertical: DesignConstants.screenPaddingVertical,
    ),
    this.padding = const EdgeInsets.symmetric(
      horizontal: DesignConstants.spacingL,
      vertical: DesignConstants.spacingM,
    ),
    this.radius = DesignConstants.borderRadiusL,
    this.blurSigma = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final glassColor = Color.alphaBlend(
      cs.surfaceTint
          .withValues(alpha: theme.brightness == Brightness.dark ? 0.08 : 0.04),
      cs.surface
          .withValues(alpha: theme.brightness == Brightness.dark ? 0.62 : 0.72),
    );
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: cs.onSurface.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  offset: Offset(0, 6),
                  color: cs.shadow.withValues(alpha: 0.16),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
