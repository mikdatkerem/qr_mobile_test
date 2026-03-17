import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../main.dart';
import '../models/zone_model.dart';
import '../models/graph_data.dart';
import 'pulse_marker.dart';
import 'navigation_route_painter.dart';

class FloorPlanWidget extends StatefulWidget {
  final List<ZoneModel> zones;
  final Set<String> visitedIds;
  final String? activeZoneId;
  final List<MapNode>? navigationRoute;
  final Map<String, bool> occupancyMap;

  static const double svgWidth = 800.0;
  static const double svgHeight = 1000.0;

  const FloorPlanWidget({
    super.key,
    required this.zones,
    required this.visitedIds,
    this.activeZoneId,
    this.navigationRoute,
    this.occupancyMap = const {},
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

  Color _parkColor(String nodeId) {
    final occupied = widget.occupancyMap[nodeId];
    if (occupied == null) return Colors.grey.shade400;
    return occupied ? Colors.red.shade500 : Colors.green.shade500;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final scaleX = w / FloorPlanWidget.svgWidth;
      final scaleY = h / FloorPlanWidget.svgHeight;

      final activeNode = _activeNode;
      final parkNodes = allNodes.where((n) => n.isPark).toList();

      double? pointerLeft, pointerTop;
      if (activeNode != null) {
        pointerLeft = activeNode.x * scaleX - 20;
        pointerTop = activeNode.y * scaleY - 20;
      }

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── SVG zemin ──────────────────────────────────────────────────
          Positioned.fill(
            child: SvgPicture.network(
              AppConfig.mapSvgUrl,
              fit: BoxFit.fill,
              placeholderBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
              headers: {'x-app-secret': AppConfig.appSecret},
            ),
          ),

          // ── Navigasyon rotası ──────────────────────────────────────────
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

          // ── Hastane Girişi etiketi ────────────────────────────────────
          Positioned(
            left: 418.0 * scaleX - 44,
            top: 40.0 * scaleY - 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0C714),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Hastane Girişi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // ── Park kutuları — sadece doluluk rengi ───────────────────────
          ...parkNodes.map((node) {
            const boxW = 28.0;
            const boxH = 18.0;
            final left = node.x * scaleX - boxW / 2;
            final top = node.y * scaleY - boxH / 2;
            final color = _parkColor(node.id);

            return Positioned(
              left: left,
              top: top,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: boxW,
                height: boxH,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: color.withOpacity(0.4),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 3,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    node.id.replaceAll(RegExp(r'[^0-9]'), ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            );
          }),

          // ── Kullanıcı konumu ───────────────────────────────────────────
          if (activeNode != null && pointerLeft != null && pointerTop != null)
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
