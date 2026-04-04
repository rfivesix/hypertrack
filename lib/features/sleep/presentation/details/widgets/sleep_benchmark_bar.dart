import 'package:flutter/material.dart';

class SleepBenchmarkBar extends StatelessWidget {
  const SleepBenchmarkBar({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.lowerTarget,
    required this.upperTarget,
  });

  final double min;
  final double max;
  final double? value;
  final double lowerTarget;
  final double upperTarget;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final range = (max - min).abs() < 0.0001 ? 1.0 : (max - min);
    final low = ((lowerTarget - min) / range).clamp(0.0, 1.0);
    final high = ((upperTarget - min) / range).clamp(0.0, 1.0);
    final marker =
        value == null ? null : ((value! - min) / range).clamp(0.0, 1.0);
    final trackRadius = BorderRadius.circular(999);
    final trackColor = isDark
        ? const Color(0xFF4A4F57)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final targetBandColor = isDark
        ? const Color(0xFF23D18B).withValues(alpha: 0.78)
        : const Color(0xFF2E9E57).withValues(alpha: 0.42);
    final markerColor = isDark
        ? const Color(0xFF8EC7FF)
        : Theme.of(context).colorScheme.primary;
    final markerWidth = isDark ? 3.0 : 2.0;

    return SizedBox(
      height: 34,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          ClipRRect(
            borderRadius: trackRadius,
            child: Container(height: 10, color: trackColor),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned(
                      left: low * constraints.maxWidth,
                      right: (1 - high) * constraints.maxWidth,
                      top: 12,
                      bottom: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: targetBandColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    if (marker != null)
                      Positioned(
                        left: marker * constraints.maxWidth - (markerWidth / 2),
                        top: 8,
                        bottom: 8,
                        child: Container(
                          width: markerWidth,
                          color: markerColor,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
