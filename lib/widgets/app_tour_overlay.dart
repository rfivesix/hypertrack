import 'package:flutter/material.dart';

/// Full-screen spotlight overlay used by the in-app walkthrough.
class AppTourOverlay extends StatelessWidget {
  final Rect? targetRect;
  final String title;
  final String description;
  final String progressLabel;
  final String nextLabel;
  final String skipLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const AppTourOverlay({
    super.key,
    required this.targetRect,
    required this.title,
    required this.description,
    required this.progressLabel,
    required this.nextLabel,
    required this.skipLabel,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spotlightRect = targetRect?.inflate(8);

    return Material(
      key: const Key('app_tour_overlay'),
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(targetRect: spotlightRect),
            ),
          ),
          if (spotlightRect != null)
            Positioned.fromRect(
              rect: spotlightRect,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const horizontalPadding = 16.0;
                const spotlightGap = 20.0;
                const topSpacing = 16.0;
                const panelMaxWidth = 540.0;
                const panelHeightEstimate = 210.0;
                const bottomNavClearance = 118.0;

                final mediaQuery = MediaQuery.of(context);
                final safeTop = mediaQuery.padding.top + topSpacing;
                final safeBottom =
                    mediaQuery.padding.bottom + bottomNavClearance;
                final availableWidth =
                    (constraints.maxWidth - horizontalPadding * 2)
                        .clamp(0.0, panelMaxWidth);

                final defaultTop =
                    constraints.maxHeight - safeBottom - panelHeightEstimate;
                double panelTop = defaultTop;
                if (spotlightRect != null) {
                  final isLowerScreenTarget =
                      spotlightRect.center.dy > constraints.maxHeight * 0.55;
                  panelTop = isLowerScreenTarget
                      ? spotlightRect.top - panelHeightEstimate - spotlightGap
                      : spotlightRect.bottom + spotlightGap;
                }

                final minTop = safeTop;
                final maxTop =
                    (constraints.maxHeight - safeBottom - panelHeightEstimate)
                        .clamp(minTop, constraints.maxHeight.toDouble());
                final clampedTop = panelTop.clamp(minTop, maxTop);

                return Stack(
                  children: [
                    Positioned(
                      top: clampedTop,
                      left: (constraints.maxWidth - availableWidth) / 2,
                      width: availableWidth,
                      child: Card(
                        elevation: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                progressLabel,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                description,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: onSkip,
                                    child: Text(skipLabel),
                                  ),
                                  const Spacer(),
                                  FilledButton(
                                    key: const Key('app_tour_next_button'),
                                    onPressed: onNext,
                                    child: Text(nextLabel),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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

class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;

  const _SpotlightPainter({required this.targetRect});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()..addRect(Offset.zero & size);
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.74);

    if (targetRect == null) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }

    final holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(targetRect!, const Radius.circular(18)),
      );
    final clipped =
        Path.combine(PathOperation.difference, overlayPath, holePath);
    canvas.drawPath(clipped, paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}
