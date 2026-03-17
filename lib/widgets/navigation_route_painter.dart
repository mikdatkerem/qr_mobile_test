import 'package:flutter/material.dart';
import '../models/graph_data.dart';

class NavigationRoutePainter extends CustomPainter {
  final List<MapNode> routeNodes;
  final double svgWidth;
  final double svgHeight;
  final Animation<double> animation;

  NavigationRoutePainter({
    required this.routeNodes,
    required this.svgWidth,
    required this.svgHeight,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (routeNodes.length < 2) return;

    final scaleX = size.width / svgWidth;
    final scaleY = size.height / svgHeight;

    final points =
        routeNodes.map((n) => Offset(n.x * scaleX, n.y * scaleY)).toList();

    // Gölge çizgisi
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Ana çizgi
    final linePaint = Paint()
      ..color = Colors.blue.shade600
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.4 * animation.value)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, linePaint);
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(NavigationRoutePainter old) =>
      old.routeNodes != routeNodes;
}
