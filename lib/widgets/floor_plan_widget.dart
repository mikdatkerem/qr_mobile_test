import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/zone_model.dart';
import '../models/graph_data.dart';
import '../services/parking_service.dart';
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

  late final ParkingService _parkingService;
  Map<String, bool> _occupancyMap = {};
  bool _signalRConnected = false;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim =
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);

    _parkingService = ParkingService(
      onOccupancyChanged: _onOccupancyChanged,
    );

    _init();
  }

  Future<void> _init() async {
    // 1) REST ile ilk durumu yükle
    try {
      final map = await _parkingService.getOccupancyMap();
      if (mounted) setState(() => _occupancyMap = map);
    } catch (_) {}

    // 2) SignalR bağlantısını başlat
    try {
      await _parkingService.startListening();
      if (mounted) setState(() => _signalRConnected = true);
    } catch (_) {}
  }

  /// SignalR'dan gelen anlık güncelleme
  void _onOccupancyChanged(String spotId, bool isOccupied) {
    if (!mounted) return;
    setState(() => _occupancyMap[spotId] = isOccupied);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _parkingService.dispose();
    super.dispose();
  }

  MapNode? get _activeNode {
    if (widget.activeZoneId == null) return null;
    return allNodes.where((n) => n.id == widget.activeZoneId).firstOrNull;
  }

  Set<String> get _routeParkIds {
    if (widget.navigationRoute == null) return {};
    return widget.navigationRoute!
        .where((n) => n.isPark)
        .map((n) => n.id)
        .toSet();
  }

  Color _parkColor(String nodeId) {
    if (_routeParkIds.contains(nodeId)) return Colors.blue.shade600;
    final occupied = _occupancyMap[nodeId];
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

      double? pointerLeft;
      double? pointerTop;
      if (_activeNode != null) {
        pointerLeft = _activeNode!.x * scaleX - 20;
        pointerTop = _activeNode!.y * scaleY - 20;
      }

      final parkNodes = allNodes.where((n) => n.isPark).toList();

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── SVG Kroki ────────────────────────────────────────────────────
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/kroki.svg',
              fit: BoxFit.fill,
              placeholderBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
            ),
          ),

          // ── Park kutuları ─────────────────────────────────────────────────
          ...parkNodes.map((node) {
            const boxW = 28.0;
            const boxH = 18.0;
            final left = node.x * scaleX - boxW / 2;
            final top = node.y * scaleY - boxH / 2;
            final color = _parkColor(node.id);
            final isTarget = _routeParkIds.contains(node.id);

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
                    color: isTarget ? Colors.white : color.withOpacity(0.4),
                    width: isTarget ? 1.5 : 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: isTarget ? 8 : 3,
                      spreadRadius: isTarget ? 1 : 0,
                    ),
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

          // ── Navigasyon rotası ─────────────────────────────────────────────
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

          // ── Kullanıcı konumu ──────────────────────────────────────────────
          if (_activeNode != null && pointerLeft != null && pointerTop != null)
            Positioned(
              left: pointerLeft.clamp(0.0, w - 40),
              top: pointerTop.clamp(0.0, h - 40),
              child: const PulseMarker(),
            ),

          // ── SignalR bağlantı göstergesi ───────────────────────────────────
          Positioned(
            right: 8,
            top: 8,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _signalRConnected
                    ? Colors.green.shade400
                    : Colors.orange.shade400,
                boxShadow: [
                  BoxShadow(
                    color: (_signalRConnected ? Colors.green : Colors.orange)
                        .withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}
