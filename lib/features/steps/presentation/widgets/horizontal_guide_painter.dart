import 'package:flutter/material.dart';

class HorizontalGuidePainter extends CustomPainter {
  HorizontalGuidePainter({
    required this.lineColor,
    required this.goalColor,
    required this.goalRatio,
    required this.leftInset,
    required this.topInset,
    required this.bottomInset,
  });

  final Color lineColor;
  final Color goalColor;
  final double goalRatio;
  final double leftInset;
  final double topInset;
  final double bottomInset;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final goalPaint = Paint()
      ..color = goalColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;

    final chartTop = topInset;
    final chartBottom = size.height - bottomInset;
    final chartHeight = chartBottom - chartTop;
    final chartStart = leftInset;
    final chartEnd = size.width;

    for (final ratio in const [0.0, 0.5, 1.0]) {
      final y = chartBottom - chartHeight * ratio;
      canvas.drawLine(Offset(chartStart, y), Offset(chartEnd, y), guidePaint);
    }

    final yGoal = chartBottom - chartHeight * goalRatio.clamp(0.0, 1.0);
    var startX = chartStart;
    while (startX < chartEnd) {
      canvas.drawLine(
        Offset(startX, yGoal),
        Offset(startX + 6, yGoal),
        goalPaint,
      );
      startX += 10;
    }
  }

  @override
  bool shouldRepaint(covariant HorizontalGuidePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.goalColor != goalColor ||
        oldDelegate.goalRatio != goalRatio ||
        oldDelegate.leftInset != leftInset ||
        oldDelegate.topInset != topInset ||
        oldDelegate.bottomInset != bottomInset;
  }
}
