import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/zone_model.dart';
import '../models/graph_data.dart';
import 'pulse_marker.dart';
import 'navigation_route_painter.dart';

class FloorPlanWidget extends StatefulWidget {
  final List<ZoneModel> zones;
  final Set<String> visitedIds;
  final String? activeZoneId;
  final List<MapNode>? navigationRoute;

  static const double svgWidth = 800.0;
  static const double svgHeight = 1000.0;

  const FloorPlanWidget({
    super.key,
    required this.zones,
    required this.visitedIds,
    this.activeZoneId,
    this.navigationRoute,
  });

  @override
  State<FloorPlanWidget> createState() => _FloorPlanWidgetState();
}

class _FloorPlanWidgetState extends State<FloorPlanWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim =
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  MapNode? get _activeNode {
    if (widget.activeZoneId == null) return null;
    return allNodes.where((n) => n.id == widget.activeZoneId).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final scaleX = w / FloorPlanWidget.svgWidth;
      final scaleY = h / FloorPlanWidget.svgHeight;

      double? pointerLeft;
      double? pointerTop;
      if (_activeNode != null) {
        pointerLeft = _activeNode!.x * scaleX - 20;
        pointerTop = _activeNode!.y * scaleY - 20;
      }

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // SVG Kroki
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/kroki.svg',
              fit: BoxFit.fill,
              placeholderBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
            ),
          ),

          // Navigasyon rotası
          if (widget.navigationRoute != null &&
              widget.navigationRoute!.length >= 2)
            Positioned.fill(
              child: CustomPaint(
                painter: NavigationRoutePainter(
                  routeNodes: widget.navigationRoute!,
                  svgWidth: FloorPlanWidget.svgWidth,
                  svgHeight: FloorPlanWidget.svgHeight,
                  animation: _glowAnim,
                ),
              ),
            ),

          // Kırmızı pulse marker (kullanıcı konumu)
          if (_activeNode != null && pointerLeft != null && pointerTop != null)
            Positioned(
              left: pointerLeft.clamp(0.0, w - 40),
              top: pointerTop.clamp(0.0, h - 40),
              child: const PulseMarker(),
            ),
        ],
      );
    });
  }
}
