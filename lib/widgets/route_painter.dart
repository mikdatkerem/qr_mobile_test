import 'package:flutter/material.dart';

class RoutePainter extends CustomPainter {
  /// Ziyaret edilen zone'ların merkez noktaları (SVG koordinatında)
  final List<Offset> visitedCenters;

  /// SVG orijinal boyutları
  final double svgWidth;
  final double svgHeight;

  RoutePainter({
    required this.visitedCenters,
    required this.svgWidth,
    required this.svgHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (visitedCenters.length < 2) return;

    final scaleX = size.width / svgWidth;
    final scaleY = size.height / svgHeight;

    // Noktalı çizgi için dash efekti
    final dashPaint = Paint()
      ..color = Colors.blue.withOpacity(0.55)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < visitedCenters.length - 1; i++) {
      final from = Offset(
        visitedCenters[i].dx * scaleX,
        visitedCenters[i].dy * scaleY,
      );
      final to = Offset(
        visitedCenters[i + 1].dx * scaleX,
        visitedCenters[i + 1].dy * scaleY,
      );
      _drawDashedLine(canvas, from, to, dashPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 5.0;

    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final distance = (to - from).distance;
    if (distance == 0) return;

    final ux = dx / distance;
    final uy = dy / distance;

    double traveled = 0;
    bool drawing = true;

    while (traveled < distance) {
      final segLen = drawing ? dashLength : gapLength;
      final end = (traveled + segLen).clamp(0, distance).toDouble();

      if (drawing) {
        canvas.drawLine(
          Offset(from.dx + ux * traveled, from.dy + uy * traveled),
          Offset(from.dx + ux * end, from.dy + uy * end),
          paint,
        );
      }

      traveled += segLen;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(RoutePainter oldDelegate) =>
      oldDelegate.visitedCenters != visitedCenters;
}
