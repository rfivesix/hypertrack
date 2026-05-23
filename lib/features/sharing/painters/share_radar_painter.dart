part of '../share_card_renderer.dart';

class _ShareRadarPainter extends CustomPainter {
  const _ShareRadarPainter({
    required this.muscles,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.textColor,
  });

  final List<MuscleVolumeSummary> muscles;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (muscles.length < 3 || maxValue <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.34;
    final angleStep = (math.pi * 2) / muscles.length;
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var ring = 1; ring <= 4; ring += 1) {
      final path = Path();
      final ringRadius = radius * ring / 4;
      for (var i = 0; i < muscles.length; i += 1) {
        final point = _point(center, ringRadius, i, angleStep);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (var i = 0; i < muscles.length; i += 1) {
      canvas.drawLine(center, _point(center, radius, i, angleStep), gridPaint);
    }

    final valuePath = Path();
    for (var i = 0; i < muscles.length; i += 1) {
      final ratio = (muscles[i].volume / maxValue).clamp(0.0, 1.0);
      final point = _point(center, radius * ratio, i, angleStep);
      if (i == 0) {
        valuePath.moveTo(point.dx, point.dy);
      } else {
        valuePath.lineTo(point.dx, point.dy);
      }
    }
    valuePath.close();

    canvas.drawPath(
      valuePath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      valuePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < muscles.length; i += 1) {
      final labelPoint = _point(center, radius + 46, i, angleStep);
      final textPainter = TextPainter(
        text: TextSpan(
          text: muscles[i].name,
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.none,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: 125);
      textPainter.paint(
        canvas,
        Offset(
          labelPoint.dx - textPainter.width / 2,
          labelPoint.dy - textPainter.height / 2,
        ),
      );
    }
  }

  Offset _point(Offset center, double radius, int index, double angleStep) {
    final angle = -math.pi / 2 + index * angleStep;
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }

  @override
  bool shouldRepaint(covariant _ShareRadarPainter oldDelegate) {
    return oldDelegate.muscles != muscles ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}
