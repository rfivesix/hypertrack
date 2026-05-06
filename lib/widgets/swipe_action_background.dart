import 'package:flutter/material.dart';

/// A background widget used for [Dismissible] swipe actions.
///
/// Provides a consistent look with rounded corners and an icon aligned to the swipe direction.
class SwipeActionBackground extends StatelessWidget {
  /// The background color (e.g., [Colors.red] for delete).
  final Color color;

  /// The icon representing the action.
  final IconData icon;

  /// Anchors the icon to a side (e.g., [Alignment.centerLeft]).
  final Alignment alignment;

  const SwipeActionBackground({
    super.key,
    required this.color,
    required this.icon,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 6.0,
      ), // Same margin as SummaryCard
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          20,
        ), // Same radius as SummaryCard
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
