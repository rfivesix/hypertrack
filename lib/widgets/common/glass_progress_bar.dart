// lib/widgets/glass_progress_bar.dart
import 'package:flutter/material.dart';

import '../../util/design_constants.dart';

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

    // Crisp, minimal text shadow for edge definition, only if bar has progress
    final textShadows = value > 0
        ? [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 1),
              blurRadius: 2.0,
            ),
          ]
        : null;

    // Heuristic for readability: if the bar color contrast with text is low,
    // we add a subtle readability scrim behind the text area.
    // Only applied if there is actual progress color to contrast with.
    final luminance = color.computeLuminance();
    final bool isLowContrast = isDark ? (luminance > 0.5) : (luminance < 0.5);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            blurRadius: 7,
            offset: const Offset(0, 2),
            color: cs.shadow.withValues(alpha: isDark ? 0.2 : 0.06),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A2A2A)
                : cs.surface.withValues(alpha: 0.95),
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
              // Readability Scrim: Subtle dark fade from the left to ensure
              // text legibility against any progress color.
              if ((isLowContrast || isDark) && value > 0)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: isDark ? 0.2 : 0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6],
                      ),
                    ),
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          shadows: textShadows,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasTarget
                          ? '${value.toStringAsFixed(1)} / ${target.toStringAsFixed(0)} $unit'
                          : '${value.toStringAsFixed(1)} $unit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface,
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
    );
  }
}
