import 'package:flutter/material.dart';
import '../models/zone_model.dart';

class ZoneOverlay extends StatelessWidget {
  final List<ZoneModel> zones;
  final Set<String> visitedIds;
  final String? activeId; // en son ziyaret edilen
  final double svgWidth;
  final double svgHeight;

  const ZoneOverlay({
    super.key,
    required this.zones,
    required this.visitedIds,
    required this.svgWidth,
    required this.svgHeight,
    this.activeId,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final scaleX = constraints.maxWidth / svgWidth;
      final scaleY = constraints.maxHeight / svgHeight;

      return Stack(
        children: zones.map((zone) {
          final isVisited = visitedIds.contains(zone.id);
          final isActive = zone.id == activeId;

          return Positioned(
            left: zone.x * scaleX,
            top: zone.y * scaleY,
            width: zone.width * scaleX,
            height: zone.height * scaleY,
            child: _ZoneBox(
              zone: zone,
              isVisited: isVisited,
              isActive: isActive,
            ),
          );
        }).toList(),
      );
    });
  }
}

class _ZoneBox extends StatefulWidget {
  final ZoneModel zone;
  final bool isVisited;
  final bool isActive;

  const _ZoneBox({
    required this.zone,
    required this.isVisited,
    required this.isActive,
  });

  @override
  State<_ZoneBox> createState() => _ZoneBoxState();
}

class _ZoneBoxState extends State<_ZoneBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnim = Tween<double>(begin: 0.55, end: 0.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_ZoneBox old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisited && !widget.isActive) {
      // Ziyaret edilmemiş: tamamen görünmez (fiziksel QR var, kutular ekranda görünmeyecek)
      return const SizedBox.expand();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.scale(
          scale: widget.isActive ? _scaleAnim.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: widget.isActive
                  ? Colors.green.withOpacity(_opacityAnim.value + 0.25)
                  : Colors.green.withOpacity(0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.isActive
                    ? Colors.green.shade600
                    : Colors.green.shade400,
                width: widget.isActive ? 2.0 : 1.5,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 16,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.zone.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
