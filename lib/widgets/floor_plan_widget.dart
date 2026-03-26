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
    this.mapAssetPath,
    this.mapAssetContentType,
    this.mapWidth,
    this.mapHeight,
  });

  final Set<String> visitedIds;
  final String? activeZoneId;
  final List<MapNode>? navigationRoute;
  final Map<String, bool> occupancyMap;
  final List<MapNode>? nodes;
  final String? mapAssetPath;
  final String? mapAssetContentType;
  final int? mapWidth;
  final int? mapHeight;

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
  late final TransformationController _transformationController;
  bool _hasUserMovedViewport = false;
  Size? _viewportSize;

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
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FloorPlanWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final mapChanged =
        oldWidget.mapAssetPath != widget.mapAssetPath ||
        oldWidget.mapWidth != widget.mapWidth ||
        oldWidget.mapHeight != widget.mapHeight;

    if (mapChanged) {
      _hasUserMovedViewport = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnActiveNode(force: true));
      return;
    }

    if (!_hasUserMovedViewport &&
        oldWidget.activeZoneId != widget.activeZoneId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnActiveNode(force: true));
    }
  }

  MapNode? get _activeNode {
    final activeZoneId = widget.activeZoneId;
    if (activeZoneId == null) {
      return null;
    }
    final sourceNodes = widget.nodes ?? allNodes;
    return sourceNodes.where((node) => node.id == activeZoneId).firstOrNull;
  }

  double get _mapWidth => (widget.mapWidth ?? currentMapWidth).toDouble();
  double get _mapHeight => (widget.mapHeight ?? currentMapHeight).toDouble();

  void _centerOnActiveNode({bool force = false}) {
    final viewportSize = _viewportSize;
    final activeNode = _activeNode;
    if (viewportSize == null || activeNode == null) {
      return;
    }

    if (_hasUserMovedViewport && !force) {
      return;
    }

    final childWidth = _mapWidth;
    final childHeight = _mapHeight;

    double translateX;
    if (childWidth <= viewportSize.width) {
      translateX = (viewportSize.width - childWidth) / 2;
    } else {
      final minTranslateX = viewportSize.width - childWidth;
      translateX =
          (viewportSize.width / 2 - activeNode.x).clamp(minTranslateX, 0.0);
    }

    double translateY;
    if (childHeight <= viewportSize.height) {
      translateY = (viewportSize.height - childHeight) / 2;
    } else {
      final minTranslateY = viewportSize.height - childHeight;
      translateY =
          (viewportSize.height / 2 - activeNode.y).clamp(minTranslateY, 0.0);
    }

    _transformationController.value =
        Matrix4.identity()..translateByDouble(translateX, translateY, 0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnActiveNode());
        final activeNode = _activeNode;
        final sourceNodes = widget.nodes ?? allNodes;
        final parkNodes = sourceNodes.where((node) => node.isPark).toList();

        return InteractiveViewer(
          transformationController: _transformationController,
          constrained: false,
          scaleEnabled: false,
          boundaryMargin: const EdgeInsets.all(320),
          onInteractionStart: (_) => _hasUserMovedViewport = true,
          child: SizedBox(
            width: _mapWidth,
            height: _mapHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: _MapAssetSurface(
                    url: _resolveMapAssetUrl(),
                    contentType: widget.mapAssetContentType,
                  ),
                ),
                if (widget.navigationRoute != null &&
                    widget.navigationRoute!.length >= 2)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: NavigationRoutePainter(
                        routeNodes: widget.navigationRoute!,
                        svgWidth: _mapWidth,
                        svgHeight: _mapHeight,
                        animation: _glowAnimation,
                      ),
                    ),
                  ),
                ...parkNodes.map((node) {
                  const cellWidth = 36.0;
                  const cellHeight = 22.0;
                  return Positioned(
                    left: node.x - cellWidth / 2,
                    top: node.y - cellHeight / 2,
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
                    left: activeNode.x - 20,
                    top: activeNode.y - 20,
                    child: const PulseMarker(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _resolveMapAssetUrl() {
    final assetPath = widget.mapAssetPath ?? currentMapAssetPath;
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
  const _MapAssetSurface({required this.url, this.contentType});

  final String url;
  final String? contentType;

  @override
  Widget build(BuildContext context) {
    final headers = ApiClient.buildHeaders(includeJsonContentType: false);
    final resolvedContentType =
        contentType?.toLowerCase() ?? currentMapAssetContentType?.toLowerCase() ?? 'image/svg+xml';

    if (resolvedContentType.contains('svg') || url.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        url,
        fit: BoxFit.cover,
        headers: headers,
        placeholderBuilder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
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
      width: 36,
      height: 22,
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
            fontSize: 8,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
