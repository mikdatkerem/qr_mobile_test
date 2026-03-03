import 'package:flutter/material.dart';
import '../models/graph_data.dart';
import '../services/pathfinding_service.dart';

class ParkSelectorSheet extends StatelessWidget {
  final PathfindingService pathfinder;
  final void Function(MapNode park) onParkSelected;

  const ParkSelectorSheet({
    super.key,
    required this.pathfinder,
    required this.onParkSelected,
  });

  @override
  Widget build(BuildContext context) {
    final groups = pathfinder.getParkGroups();
    final groupKeys = groups.keys.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          // Handle
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
                  'Park Seç',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  'Bir park yerine yol çizilecek',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
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
                final groupKey = groupKeys[gi];
                final parks = groups[groupKey]!;
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: parks.length,
                      itemBuilder: (_, i) {
                        final park = parks[i];
                        final num = park.id.replaceAll(RegExp(r'[^0-9]'), '');
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            onParkSelected(park);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.blue.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_parking,
                                  size: 18,
                                  color: Colors.blue.shade600,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  num,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
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
        ],
      ),
    );
  }
}
