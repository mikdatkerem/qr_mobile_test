import 'package:flutter/material.dart';
import '../models/graph_data.dart';

class NavBanner extends StatelessWidget {
  final MapNode targetPark;
  final String? distanceLabel;
  final VoidCallback onClear;
  final VoidCallback onTap;

  const NavBanner({
    super.key,
    required this.targetPark,
    this.distanceLabel,
    required this.onClear,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.blue.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(children: [
          const Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              distanceLabel != null
                  ? '${targetPark.label}  ·  $distanceLabel'
                  : 'Rota hesaplanıyor...',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.close, color: Colors.white70, size: 16),
            ),
          ),
        ]),
      ),
    );
  }
}
