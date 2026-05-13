// lib/widgets/glass_progress_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';

import '../util/design_constants.dart';

/// A progress bar widget with a glass background and a solid fill color.
///
/// Displays a [label], [unit], current [value], and optional [target].
class GlassProgressBar extends StatelessWidget {
  /// The descriptive label for the progress (e.g., 'Calories').
  final String label;

  /// The unit of measurement (e.g., 'kcal').
  final String unit;

  /// The current value to display.
  final double value;

  /// The goal or target value; used to calculate progress percentage.
  final double target;

  /// The color of the progress fill.
  final Color color;

  /// The fixed height of the progress bar.
  final double height;

  /// The corner radius for the bar.
  final double borderRadius;

  const GlassProgressBar({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.target,
    required this.color,
    this.height = 54.0,
    this.borderRadius = DesignConstants.borderRadiusL,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final hasTarget = target > 0;
    final rawProgress = hasTarget ? (value / target) : 0.0;
    final progress = rawProgress.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(borderRadius);
    final backgroundColor = Color.alphaBlend(
      cs.surfaceTint.withValues(alpha: isDark ? 0.08 : 0.04),
      cs.surface.withValues(alpha: isDark ? 0.62 : 0.72),
    );

    // Subtle universal text shadow for readability on both bg and progress color
    final textShadows = [
      Shadow(
        color: Colors.black.withValues(alpha: 0.2),
        offset: const Offset(0, 1),
        blurRadius: 2.0,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 4),
            color: cs.shadow.withValues(alpha: 0.12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: radius,
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: cs.onSurface.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    heightFactor: 1.0,
                    child: ColoredBox(color: color),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: textShadows,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasTarget
                            ? '${value.toStringAsFixed(1)} / ${target.toStringAsFixed(0)} $unit'
                            : '${value.toStringAsFixed(1)} $unit',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.9),
                          fontSize: 13,
                          shadows: textShadows,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
