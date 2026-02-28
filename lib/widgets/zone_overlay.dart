import 'package:flutter/material.dart';
import '../models/zone_model.dart';

class ZoneOverlay extends StatelessWidget {
  final List<ZoneModel> zones;
  final Set<String> visitedIds;
  final String? activeId;
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
              key: ValueKey(zone.id),
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
    super.key,
    required this.zone,
    required this.isVisited,
    required this.isActive,
  });

  @override
  State<_ZoneBox> createState() => _ZoneBoxState();
}

class _ZoneBoxState extends State<_ZoneBox> with TickerProviderStateMixin {
  // Sürekli pulse — aktif zone için
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  // Tek seferlik flash — yeni ziyaret edildiğinde
  late final AnimationController _flashController;
  late final Animation<double> _flashAnim;

  bool _wasActive = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _opacityAnim = Tween<double>(begin: 0.55, end: 0.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flashAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(
        CurvedAnimation(parent: _flashController, curve: Curves.easeOut));

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
      _flashController.forward();
      _wasActive = true;
    }
  }

  @override
  void didUpdateWidget(_ZoneBox old) {
    super.didUpdateWidget(old);

    // Aktif oldu → pulse başlat + flash çak
    if (widget.isActive && !_wasActive) {
      _pulseController.repeat(reverse: true);
      _flashController.forward(from: 0);
      _wasActive = true;
    }

    // Aktif olmaktan çıktı → pulse durdur (ziyaret edildi rengi kalır)
    if (!widget.isActive && _wasActive) {
      _pulseController.stop();
      _pulseController.reset();
      _wasActive = false;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hiç ziyaret edilmemiş ve aktif değil → görünmez
    if (!widget.isVisited && !widget.isActive) {
      return const SizedBox.expand();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _flashController]),
      builder: (context, _) {
        // Flash beyaz overlay opacity'si
        final flashOpacity = _flashAnim.value * 0.6;

        return Transform.scale(
          scale: widget.isActive ? _scaleAnim.value : 1.0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Yeşil kutu
              Container(
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? Colors.green
                          .withOpacity((_opacityAnim.value * 0.5) + 0.25)
                      : Colors.green.withOpacity(0.2),
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
                        size: 14,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.zone.label,
                        style: TextStyle(
                          fontSize: 8,
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

              // Flash overlay (yanıp sönme)
              if (flashOpacity > 0)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(flashOpacity),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
