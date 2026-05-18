import 'dart:math' as math;

import 'package:flutter/material.dart';

class MuscleRadarDatum {
  final String label;
  final double value;

  const MuscleRadarDatum({required this.label, required this.value});
}

class MuscleRadarChart extends StatelessWidget {
  final List<MuscleRadarDatum> data;
  final double maxValue;
  final String centerLabel;

  const MuscleRadarChart({
    super.key,
    required this.data,
    required this.maxValue,
    required this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (data.length < 3 || maxValue <= 0) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 360.0);
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RadarPainter(
              data: data,
              maxValue: maxValue,
              lineColor: colorScheme.primary,
              fillColor: colorScheme.primary.withValues(alpha: 0.22),
              gridColor: colorScheme.outline.withValues(alpha: 0.28),
              textColor: colorScheme.onSurface.withValues(alpha: 0.78),
              centerLabel: centerLabel,
            ),
          ),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<MuscleRadarDatum> data;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color textColor;
  final String centerLabel;

  const _RadarPainter({
    required this.data,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.textColor,
    required this.centerLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.32;
    final angleStep = (2 * math.pi) / data.length;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var ring = 1; ring <= 4; ring++) {
      final ringRadius = radius * (ring / 4);
      final ringPath = Path();
      for (var i = 0; i < data.length; i++) {
        final angle = -math.pi / 2 + (i * angleStep);
        final point = Offset(
          center.dx + (ringRadius * math.cos(angle)),
          center.dy + (ringRadius * math.sin(angle)),
        );
        if (i == 0) {
          ringPath.moveTo(point.dx, point.dy);
        } else {
          ringPath.lineTo(point.dx, point.dy);
        }
      }
      ringPath.close();
      canvas.drawPath(ringPath, gridPaint);
    }

    for (var i = 0; i < data.length; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final endpoint = Offset(
        center.dx + (radius * math.cos(angle)),
        center.dy + (radius * math.sin(angle)),
      );
      canvas.drawLine(center, endpoint, gridPaint);
    }

    final valuePath = Path();
    for (var i = 0; i < data.length; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final valueRatio = (data[i].value / maxValue).clamp(0.0, 1.0);
      final point = Offset(
        center.dx + (radius * valueRatio * math.cos(angle)),
        center.dy + (radius * valueRatio * math.sin(angle)),
      );
      if (i == 0) {
        valuePath.moveTo(point.dx, point.dy);
      } else {
        valuePath.lineTo(point.dx, point.dy);
      }
    }
    valuePath.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(valuePath, fillPaint);
    canvas.drawPath(valuePath, linePaint);

    final labelStyle = TextStyle(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    for (var i = 0; i < data.length; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final labelPoint = Offset(
        center.dx + ((radius + 14) * math.cos(angle)),
        center.dy + ((radius + 14) * math.sin(angle)),
      );

      final textPainter = TextPainter(
        text: TextSpan(text: data[i].label, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: 78);

      final dx = labelPoint.dx - (textPainter.width / 2);
      final dy = labelPoint.dy - (textPainter.height / 2);
      textPainter.paint(canvas, Offset(dx, dy));
    }

    final centerPainter = TextPainter(
      text: TextSpan(
        text: centerLabel,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
    )..layout(maxWidth: 100);
    centerPainter.paint(
      canvas,
      Offset(
        center.dx - centerPainter.width / 2,
        center.dy - centerPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.centerLabel != centerLabel;
  }
}
