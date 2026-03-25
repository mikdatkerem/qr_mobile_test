import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/api_client.dart';
import '../main.dart';
import '../models/graph_data.dart';
import 'navigation_route_painter.dart';
import 'pulse_marker.dart';

class FloorPlanWidget extends StatefulWidget {
  const FloorPlanWidget({
    super.key,
    required this.visitedIds,
    required this.occupancyMap,
    this.activeZoneId,
    this.navigationRoute,
    this.nodes,
  });

  final Set<String> visitedIds;
  final String? activeZoneId;
  final List<MapNode>? navigationRoute;
  final Map<String, bool> occupancyMap;
  final List<MapNode>? nodes;

  String? get targetParkId {
    if (navigationRoute == null || navigationRoute!.isEmpty) {
      return null;
    }
    final lastNode = navigationRoute!.last;
    return lastNode.isPark ? lastNode.id : null;
  }

  @override
  State<FloorPlanWidget> createState() => _FloorPlanWidgetState();
}

class _FloorPlanWidgetState extends State<FloorPlanWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  MapNode? get _activeNode {
    final activeZoneId = widget.activeZoneId;
    if (activeZoneId == null) {
      return null;
    }
    final sourceNodes = widget.nodes ?? allNodes;
    return sourceNodes.where((node) => node.id == activeZoneId).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final scaleX = width / currentMapWidth;
        final scaleY = height / currentMapHeight;
        final activeNode = _activeNode;
        final sourceNodes = widget.nodes ?? allNodes;
        final parkNodes = sourceNodes.where((node) => node.isPark).toList();

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: _MapAssetSurface(url: _resolveMapAssetUrl()),
            ),
            if (widget.navigationRoute != null &&
                widget.navigationRoute!.length >= 2)
              Positioned.fill(
                child: CustomPaint(
                  painter: NavigationRoutePainter(
                    routeNodes: widget.navigationRoute!,
                    svgWidth: currentMapWidth.toDouble(),
                    svgHeight: currentMapHeight.toDouble(),
                    animation: _glowAnimation,
                  ),
                ),
              ),
            ...parkNodes.map((node) {
              const cellWidth = 28.0;
              const cellHeight = 18.0;
              return Positioned(
                left: node.x * scaleX - cellWidth / 2,
                top: node.y * scaleY - cellHeight / 2,
                child: _ParkCell(
                  key: ValueKey(node.id),
                  node: node,
                  isOccupied: widget.occupancyMap[node.id],
                  isTarget: widget.targetParkId == node.id,
                ),
              );
            }),
            if (activeNode != null)
              Positioned(
                left: (activeNode.x * scaleX - 20).clamp(0.0, width - 40),
                top: (activeNode.y * scaleY - 20).clamp(0.0, height - 40),
                child: const PulseMarker(),
              ),
          ],
        );
      },
    );
  }

  String _resolveMapAssetUrl() {
    final assetPath = currentMapAssetPath;
    if (assetPath == null || assetPath.isEmpty) {
      return AppConfig.mapSvgUrl;
    }

    if (assetPath.startsWith('http://') || assetPath.startsWith('https://')) {
      return assetPath;
    }

    return '${AppConfig.baseHost}$assetPath';
  }
}

class _MapAssetSurface extends StatelessWidget {
  const _MapAssetSurface({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final headers = ApiClient.buildHeaders(includeJsonContentType: false);
    final contentType = currentMapAssetContentType?.toLowerCase() ?? 'image/svg+xml';

    if (contentType.contains('svg') || url.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        url,
        fit: BoxFit.fill,
        headers: headers,
        placeholderBuilder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.fill,
      headers: headers,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }

        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF7C869C)),
      ),
    );
  }
}

class _ParkCell extends StatelessWidget {
  const _ParkCell({
    super.key,
    required this.node,
    required this.isOccupied,
    required this.isTarget,
  });

  final MapNode node;
  final bool? isOccupied;
  final bool isTarget;

  Color get _cellColor {
    if (isTarget) {
      return const Color(0xFF2155D6);
    }
    if (isOccupied == null) {
      return const Color(0xFFB5BECE);
    }
    return isOccupied! ? const Color(0xFFE25757) : const Color(0xFF1C9B67);
  }

  @override
  Widget build(BuildContext context) {
    final cellColor = _cellColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: 28,
      height: 18,
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 0.7),
        boxShadow: [
          BoxShadow(
            color: cellColor.withValues(alpha: 0.28),
            blurRadius: 4,
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
    );
  }
}
