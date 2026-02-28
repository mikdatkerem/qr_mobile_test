import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/zone_model.dart';
import 'pulse_marker.dart';
import 'zone_overlay.dart';
import 'route_painter.dart';

class FloorPlanWidget extends StatelessWidget {
  final List<ZoneModel> zones;
  final Set<String> visitedIds;
  final String? activeZoneId;

  // SVG orijinal viewBox boyutları — kendi SVG'ne göre güncelle
  static const double svgWidth = 800.0;
  static const double svgHeight = 600.0;

  const FloorPlanWidget({
    super.key,
    required this.zones,
    required this.visitedIds,
    this.activeZoneId,
  });

  ZoneModel? get _activeZone => activeZoneId == null
      ? null
      : zones.where((z) => z.id == activeZoneId).firstOrNull;

  List<ZoneModel> get _visitedZonesInOrder =>
      zones.where((z) => visitedIds.contains(z.id)).toList();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final scaleX = w / svgWidth;
      final scaleY = h / svgHeight;

      double? pointerLeft;
      double? pointerTop;
      if (_activeZone != null) {
        pointerLeft = _activeZone!.centerX * scaleX - 20;
        pointerTop = _activeZone!.centerY * scaleY - 20;
      }

      final routePoints = _visitedZonesInOrder
          .map((z) => Offset(z.centerX, z.centerY))
          .toList();

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // 1. SVG Kroki
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/kroki.svg',
              fit: BoxFit.fill,
              placeholderBuilder: (_) => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),

          // 2. Rota çizgisi (ziyaret edilen noktalar arası)
          if (routePoints.length >= 2)
            Positioned.fill(
              child: CustomPaint(
                painter: RoutePainter(
                  visitedCenters: routePoints,
                  svgWidth: svgWidth,
                  svgHeight: svgHeight,
                ),
              ),
            ),

          // 3. Zone kutuları (sadece ziyaret edilenler görünür)
          Positioned.fill(
            child: ZoneOverlay(
              zones: zones,
              visitedIds: visitedIds,
              activeId: activeZoneId,
              svgWidth: svgWidth,
              svgHeight: svgHeight,
            ),
          ),

          // 4. Anlık konum pointer'ı
          if (_activeZone != null && pointerLeft != null && pointerTop != null)
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
