// lib/widgets/glass_progress_bar.dart
import 'package:flutter/material.dart';
import '../theme/color_constants.dart';

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
    this.height = 60.0,
    this.borderRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final colorScheme = theme.colorScheme;

    final hasTarget = target > 0;
    final rawProgress = hasTarget ? (value / target) : 0.0;
    final progress = rawProgress.clamp(0.0, 1.0);

    final backgroundColor = brightness == Brightness.dark
        ? summary_card_dark_mode
        : summary_card_white_mode;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(color: color),
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
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasTarget
                        ? '${value.toStringAsFixed(1)} / ${target.toStringAsFixed(0)} $unit'
                        : '${value.toStringAsFixed(1)} $unit',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
