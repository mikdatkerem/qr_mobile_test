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

  // Rota hedef park id'si — o kutu mavi gösterilir
  String? get targetParkId {
    if (navigationRoute == null || navigationRoute!.isEmpty) return null;
    final last = navigationRoute!.last;
    return last.isPark ? last.id : null;
  }

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
          // ── SVG zemin ─────────────────────────────────────────────────
          Positioned.fill(
            child: SvgPicture.network(
              AppConfig.mapSvgUrl,
              fit: BoxFit.fill,
              placeholderBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
              headers: {'x-app-secret': AppConfig.appSecret},
            ),
          ),

          // ── Navigasyon rotası ─────────────────────────────────────────
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

          // ── Sabit etiketler ────────────────────────────────────────────
          _LabelBox(
              label: 'Hastane Girişi',
              x: 400.0,
              y: 40.0,
              scaleX: scaleX,
              scaleY: scaleY),
          _LabelBox(
              label: 'Giriş',
              x: 625.0,
              y: 990.0,
              scaleX: scaleX,
              scaleY: scaleY),
          _LabelBox(
              label: 'Çıkış',
              x: 250.0,
              y: 990.0,
              scaleX: scaleX,
              scaleY: scaleY),

          // ── Park kutuları — her kutu kendi widget'ı, sadece o rebuild ─
          ...parkNodes.map((node) {
            const boxW = 28.0;
            const boxH = 18.0;
            return Positioned(
              left: node.x * scaleX - boxW / 2,
              top: node.y * scaleY - boxH / 2,
              child: _ParkCell(
                key: ValueKey(node.id),
                node: node,
                isOccupied: widget.occupancyMap[node.id],
                isTarget: widget.targetParkId == node.id,
              ),
            );
          }),

          // ── Kullanıcı konumu ──────────────────────────────────────────
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

// ─── Park kutusu — kendi state'i var, sadece isOccupied değişince rebuild ───

class _ParkCell extends StatelessWidget {
  final MapNode node;
  final bool? isOccupied;
  final bool isTarget;

  const _ParkCell({
    super.key,
    required this.node,
    required this.isOccupied,
    this.isTarget = false,
  });

  Color get _color {
    if (isTarget) return Colors.blue.shade600;
    if (isOccupied == null) return Colors.grey.shade400;
    return isOccupied! ? Colors.red.shade500 : Colors.green.shade500;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: 28,
      height: 18,
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 3)],
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
    );
  }
}

// ─── Sabit etiket kutusu ──────────────────────────────────────────────────────

class _LabelBox extends StatelessWidget {
  final String label;
  final double x, y, scaleX, scaleY;

  const _LabelBox({
    required this.label,
    required this.x,
    required this.y,
    required this.scaleX,
    required this.scaleY,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x * scaleX - 28,
      top: y * scaleY - 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.amber.shade600,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
