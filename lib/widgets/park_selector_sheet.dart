import 'package:flutter/material.dart';

import '../models/graph_data.dart';
import '../services/pathfinding_service.dart';

class ParkSelectorSheet extends StatelessWidget {
  const ParkSelectorSheet({
    super.key,
    required this.pathfinder,
    required this.onParkSelected,
    this.occupancyMap = const {},
    this.nodes = const [],
  });

  final PathfindingService pathfinder;
  final void Function(MapNode park) onParkSelected;
  final Map<String, bool> occupancyMap;
  final List<MapNode> nodes;

  @override
  Widget build(BuildContext context) {
    final groups = pathfinder.getParkGroups(nodes);
    final groupKeys = groups.keys.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.local_parking, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Park Sec',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  _LegendDot(color: Colors.green.shade500, label: 'Bos'),
                  const SizedBox(width: 8),
                  _LegendDot(color: Colors.red.shade500, label: 'Dolu'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: groupKeys.length,
                itemBuilder: (_, gi) {
                  final parks = groups[groupKeys[gi]]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                        child: Text(
                          'Park Yerleri',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: parks.length,
                        itemBuilder: (_, i) {
                          final park = parks[i];
                          final num = park.id.replaceAll(RegExp(r'[^0-9]'), '');
                          final isOccupied = occupancyMap[park.id];
                          final Color bgColor;
                          final Color borderColor;
                          final Color iconColor;
                          final Color textColor;

                          if (isOccupied == null) {
                            bgColor = Colors.grey.shade100;
                            borderColor = Colors.grey.shade300;
                            iconColor = Colors.grey.shade400;
                            textColor = Colors.grey.shade600;
                          } else if (isOccupied) {
                            bgColor = Colors.red.shade50;
                            borderColor = Colors.red.shade200;
                            iconColor = Colors.red.shade400;
                            textColor = Colors.red.shade700;
                          } else {
                            bgColor = Colors.green.shade50;
                            borderColor = Colors.green.shade300;
                            iconColor = Colors.green.shade500;
                            textColor = Colors.green.shade700;
                          }

                          return GestureDetector(
                            onTap: isOccupied == true
                                ? null
                                : () {
                                    Navigator.pop(ctx);
                                    onParkSelected(park);
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor, width: 1),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_parking, size: 18, color: iconColor),
                                  const SizedBox(height: 2),
                                  Text(
                                    num,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                    ],
                  );
                },
              ),
            ),
            SafeArea(top: false, child: const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      );
}
