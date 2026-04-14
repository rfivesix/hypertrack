// lib/widgets/shadow_container.dart

import 'package:flutter/material.dart';

/// A container utility that adds a soft shadow and corner clipping to its [child].
class ShadowContainer extends StatelessWidget {
  /// The content to display inside the container.
  final Widget child;

  /// The corner radius for the container and its content.
  final BorderRadiusGeometry borderRadius;

  /// Optional list of [boxShadow] objects; defaults to a soft standard shadow.
  final List<BoxShadow>? boxShadow;

  /// Optional external margin around the container.
  final EdgeInsetsGeometry? margin; // Optionaler externer Margin

  const ShadowContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16.0)),
    this.boxShadow,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow ??
            [
              // Standard-Schatten, wenn keiner angegeben ist
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        // ClipRRect, um den Inhalt innerhalb der Ecken zu halten
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}
