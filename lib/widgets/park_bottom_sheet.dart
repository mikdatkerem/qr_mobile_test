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
    required this.organizationLabel,
    required this.siteLabel,
    required this.buildingLabel,
    required this.floorLabel,
    required this.mapName,
    required this.activeReference,
    required this.emptyCount,
    required this.fullCount,
    required this.totalCount,
    required this.multiRoute,
    required this.activeSegmentIndex,
    required this.onSegmentTap,
    required this.onOrganizationTap,
    required this.onSiteTap,
    required this.onBuildingTap,
    required this.onFloorTap,
    required this.onParkSelected,
    required this.onNavigateToExit,
    required this.onNavigateToCar,
    required this.onClearNav,
    required this.onNearestToUser,
    required this.onNearestToHospital,
  });

  static const double peekSize = 0.08;
  static const double mediumSize = 0.28;
  static const double fullSize = 0.72;

  final Map<String, bool> occupancyMap;
  final MapNode? targetPark;
  final MapNode? parkedAt;
  final String organizationLabel;
  final String siteLabel;
  final String buildingLabel;
  final String floorLabel;
  final String mapName;
  final String? activeReference;
  final int emptyCount;
  final int fullCount;
  final int totalCount;
  final MultiRouteResult? multiRoute;
  final int activeSegmentIndex;
  final ValueChanged<int> onSegmentTap;
  final VoidCallback onOrganizationTap;
  final VoidCallback onSiteTap;
  final VoidCallback onBuildingTap;
  final VoidCallback onFloorTap;
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
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(18, 10, 18, bottom + 16),
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6DDEA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
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
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B2438),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$emptyCount boş · $fullCount dolu · $totalCount toplam',
                          style: const TextStyle(
                            color: Color(0xFF6D7890),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (targetPark != null)
                    _StatusPill(label: 'Rota ${targetPark!.id}'),
                ],
              ),
              const SizedBox(height: 18),
              _SectionTitle(title: 'Bağlam'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SelectionChip(
                    label: organizationLabel,
                    icon: Icons.apartment_rounded,
                    onTap: onOrganizationTap,
                  ),
                  _SelectionChip(
                    label: siteLabel,
                    icon: Icons.location_city_rounded,
                    onTap: onSiteTap,
                  ),
                  _SelectionChip(
                    label: buildingLabel,
                    icon: Icons.business_rounded,
                    onTap: onBuildingTap,
                  ),
                  _SelectionChip(
                    label: floorLabel,
                    icon: Icons.layers_rounded,
                    onTap: onFloorTap,
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                      value: targetPark?.label ?? 'Seçilmedi',
                      icon: Icons.flag_outlined,
                    ),
                  ),
                ],
              ),
              if (multiRoute != null && multiRoute!.segments.length > 1) ...[
                const SizedBox(height: 18),
                _SectionTitle(title: 'Katlar arası rota'),
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
              _SectionTitle(title: 'Aksiyonlar'),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.near_me_rounded,
                title: 'Bana en yakın',
                subtitle: 'Konumunuza göre en uygun boş alan',
                onTap: onNearestToUser,
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.local_hospital_outlined,
                title: 'Hastane girişine yakın',
                subtitle: 'Girişe yakın uygun park alanını bul',
                onTap: onNearestToHospital,
              ),
              const SizedBox(height: 10),
              if (parkedAt != null) ...[
                _ActionTile(
                  icon: Icons.directions_car_outlined,
                  title: 'Aracıma git',
                  subtitle: '${parkedAt!.id} alanına rota çiz',
                  onTap: onNavigateToCar,
                ),
                const SizedBox(height: 10),
              ],
              _ActionTile(
                icon: Icons.logout_rounded,
                title: 'Çıkışa git',
                subtitle: 'Bulunduğunuz kattan çıkış rotası oluştur',
                onTap: onNavigateToExit,
              ),
              if (targetPark != null) ...[
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.close_rounded,
                  title: 'Rotayı temizle',
                  subtitle: 'Aktif hedefe ait rota görünümünü kapat',
                  destructive: true,
                  onTap: onClearNav,
                ),
              ],
              const SizedBox(height: 18),
              _SectionTitle(title: 'Park alanları'),
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
                  final isOccupied = occupancyMap[park.id];
                  final isTarget = targetPark?.id == park.id;
                  final isParkedAt = parkedAt?.id == park.id;

                  Color backgroundColor;
                  Color textColor;

                  if (isParkedAt) {
                    backgroundColor = const Color(0xFFDCE7FF);
                    textColor = const Color(0xFF2155D6);
                  } else if (isTarget) {
                    backgroundColor = const Color(0xFF2155D6);
                    textColor = Colors.white;
                  } else if (isOccupied == true) {
                    backgroundColor = const Color(0xFFFFE3E3);
                    textColor = const Color(0xFFE25757);
                  } else if (isOccupied == false) {
                    backgroundColor = const Color(0xFFE6F6EE);
                    textColor = const Color(0xFF1C9B67);
                  } else {
                    backgroundColor = const Color(0xFFF0F3F8);
                    textColor = const Color(0xFF9AA5BB);
                  }

                  return InkWell(
                    onTap: isOccupied == true ? null : () => onParkSelected(park),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        park.id.replaceAll(RegExp(r'[^0-9]'), ''),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
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
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1B2438),
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E9F4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF2155D6)),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D2435),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: Color(0xFF7C869C),
            ),
          ],
        ),
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
        color: const Color(0xFFF5F7FC),
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
            child: Icon(icon, color: const Color(0xFF2155D6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF7B849A),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1D2435),
                    fontWeight: FontWeight.w700,
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
    final accent = destructive ? const Color(0xFFE25757) : const Color(0xFF2155D6);
    final background =
        destructive ? const Color(0xFFFFF0F0) : const Color(0xFFF6F8FC);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: destructive
                          ? const Color(0xFFD64545)
                          : const Color(0xFF1C2438),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF707A92),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA6BA)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2155D6),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
