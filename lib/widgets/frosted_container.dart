//lib/widgets/frosted_container.dart
import 'dart:ui';
import 'package:flutter/material.dart';

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
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.radius = 20,
    this.blurSigma = 14,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: cs.onSurface.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 18,
                  offset: Offset(0, 6),
                  color: Colors.black26,
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
