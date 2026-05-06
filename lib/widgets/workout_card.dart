// lib/widgets/workout_card.dart
import 'package:flutter/material.dart';

/// A transparent container for workout items with rounded corners.
///
/// Used to group workout elements while maintaining layout consistency.
class WorkoutCard extends StatelessWidget {
  /// Internal padding for the [child].
  final EdgeInsetsGeometry padding;

  /// External margin for the card.
  final EdgeInsetsGeometry margin;

  /// The content within the card.
  final Widget child;

  const WorkoutCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key, // Pass key to the container
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.transparent, // Komplett transparent
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        // Ensures child corners stay rounded.
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }
}
