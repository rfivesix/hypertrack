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
    final range = (max - min).abs() < 0.0001 ? 1.0 : (max - min);
    final low = ((lowerTarget - min) / range).clamp(0.0, 1.0);
    final high = ((upperTarget - min) / range).clamp(0.0, 1.0);
    final marker =
        value == null ? null : ((value! - min) / range).clamp(0.0, 1.0);

    return SizedBox(
      height: 34,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
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
                          color: Colors.green.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    if (marker != null)
                      Positioned(
                        left: marker * constraints.maxWidth - 1,
                        top: 8,
                        bottom: 8,
                        child: Container(
                          width: 2,
                          color: Theme.of(context).colorScheme.primary,
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
