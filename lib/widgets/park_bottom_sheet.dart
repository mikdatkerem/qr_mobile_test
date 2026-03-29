import 'package:flutter/material.dart';

import '../models/graph_data.dart';
import '../services/pathfinding_service.dart';

class ParkBottomSheet extends StatelessWidget {
  const ParkBottomSheet({
    super.key,
    this.controller,
    required this.occupancyMap,
    required this.targetPark,
    required this.parkedAt,
    required this.mapName,
    required this.activeReference,
    required this.emptyCount,
    required this.fullCount,
    required this.totalCount,
    required this.multiRoute,
    required this.activeSegmentIndex,
    required this.onSegmentTap,
    required this.onParkSelected,
    required this.onNavigateToExit,
    required this.onNavigateToCar,
    required this.onClearNav,
    required this.onNearestToUser,
    required this.onNearestToHospital,
  });

  static const double peekSize = 0.09;
  static const double mediumSize = 0.28;
  static const double fullSize = 0.72;

  final Map<String, bool> occupancyMap;
  final MapNode? targetPark;
  final MapNode? parkedAt;
  final String mapName;
  final String? activeReference;
  final int emptyCount;
  final int fullCount;
  final int totalCount;
  final MultiRouteResult? multiRoute;
  final int activeSegmentIndex;
  final ValueChanged<int> onSegmentTap;
  final void Function(MapNode) onParkSelected;
  final VoidCallback onNavigateToExit;
  final VoidCallback onNavigateToCar;
  final VoidCallback onClearNav;
  final VoidCallback onNearestToUser;
  final VoidCallback onNearestToHospital;
  final DraggableScrollableController? controller;

  @override
  Widget build(BuildContext context) {
    final parks = allNodes.where((node) => node.isPark).toList();
    final bottom = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      controller: controller,
      expand: false,
      initialChildSize: peekSize,
      minChildSize: peekSize,
      maxChildSize: fullSize,
      snap: true,
      snapSizes: const [peekSize, mediumSize, fullSize],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x18081426),
                blurRadius: 20,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6DDEA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                top: 18,
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(18, 46, 18, bottom + 16),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF0FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.map_rounded,
                            color: Color(0xFF2155D6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mapName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1B2438),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$emptyCount bos · $fullCount dolu · $totalCount toplam',
                                style: const TextStyle(
                                  color: Color(0xFF6D7890),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (targetPark != null) _StatusPill(label: 'Rota ${targetPark!.id}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            title: 'Aktif nokta',
                            value: activeReference ?? 'QR bekleniyor',
                            icon: Icons.pin_drop_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoCard(
                            title: 'Hedef',
                            value: targetPark?.label ?? 'Secilmedi',
                            icon: Icons.flag_outlined,
                          ),
                        ),
                      ],
                    ),
                    if (multiRoute != null && multiRoute!.segments.length > 1) ...[
                      const SizedBox(height: 18),
                      const _SectionTitle(title: 'Katlar arasi rota'),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 60,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: multiRoute!.segments.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final segment = multiRoute!.segments[index];
                            final isActive = index == activeSegmentIndex;

                            return InkWell(
                              onTap: () => onSegmentTap(index),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF2155D6)
                                      : const Color(0xFFF5F7FC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isActive
                                        ? const Color(0xFF2155D6)
                                        : const Color(0xFFE2E8F3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${segment.buildingName} / ${segment.floorName}',
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white
                                            : const Color(0xFF182033),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      segment.siteName,
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white.withValues(alpha: 0.86)
                                            : const Color(0xFF6F7992),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Aksiyonlar'),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.near_me_rounded,
                      title: 'Bana en yakin',
                      subtitle: 'Konumunuza gore en uygun bos alan',
                      onTap: onNearestToUser,
                    ),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.local_hospital_outlined,
                      title: 'Hastane girisine yakin',
                      subtitle: 'Girise yakin uygun park alanini bul',
                      onTap: onNearestToHospital,
                    ),
                    const SizedBox(height: 10),
                    if (parkedAt != null) ...[
                      _ActionTile(
                        icon: Icons.directions_car_outlined,
                        title: 'Aracima git',
                        subtitle: '${parkedAt!.id} alanina rota ciz',
                        onTap: onNavigateToCar,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _ActionTile(
                      icon: Icons.logout_rounded,
                      title: 'Cikisa git',
                      subtitle: 'Bulundugunuz kattan cikis rotasi olustur',
                      onTap: onNavigateToExit,
                    ),
                    if (targetPark != null) ...[
                      const SizedBox(height: 10),
                      _ActionTile(
                        icon: Icons.close_rounded,
                        title: 'Rotayi temizle',
                        subtitle: 'Aktif hedefe ait rota gorunumunu kapat',
                        destructive: true,
                        onTap: onClearNav,
                      ),
                    ],
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Park alanlari'),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.12,
                      ),
                      itemCount: parks.length,
                      itemBuilder: (context, index) {
                        final park = parks[index];
                        final parkKey = (park.externalReferenceId ?? park.id).toUpperCase();
                        final isOccupied = occupancyMap[parkKey];
                        final isTarget = targetPark?.id == park.id;

                        return InkWell(
                          onTap: () => onParkSelected(park),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isTarget ? const Color(0xFF2155D6) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isTarget
                                    ? const Color(0xFF2155D6)
                                    : const Color(0xFFE1E8F2),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  park.id,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: isTarget
                                        ? Colors.white
                                        : const Color(0xFF1B2438),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _spotColor(isOccupied, isTarget),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _spotColor(bool? isOccupied, bool isTarget) {
    if (isTarget) {
      return Colors.white;
    }
    if (isOccupied == null) {
      return const Color(0xFFB5BECE);
    }
    return isOccupied ? const Color(0xFFE25757) : const Color(0xFF1C9B67);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1B2438),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2155D6), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6D7890),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B2438),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final titleColor = destructive ? const Color(0xFFC53A3A) : const Color(0xFF1B2438);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: destructive ? const Color(0xFFC53A3A) : const Color(0xFF2155D6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6D7890),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA5BC)),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2155D6),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
