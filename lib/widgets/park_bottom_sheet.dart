import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/graph_data.dart';
import '../services/pathfinding_service.dart';

class ParkBottomSheet extends StatefulWidget {
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
    required this.parks,
  });

  static const double peekSize = 0.08;
  static const double mediumSize = 0.32;
  static const double fullSize = 0.76;

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
  final List<MapNode> parks;
  final DraggableScrollableController? controller;

  @override
  State<ParkBottomSheet> createState() => _ParkBottomSheetState();
}

class _ParkBottomSheetState extends State<ParkBottomSheet> {
  bool _showParks = false;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      controller: widget.controller,
      expand: false,
      initialChildSize: ParkBottomSheet.peekSize,
      minChildSize: ParkBottomSheet.peekSize,
      maxChildSize: ParkBottomSheet.fullSize,
      snap: true,
      snapSizes: const [
        ParkBottomSheet.peekSize,
        ParkBottomSheet.mediumSize,
        ParkBottomSheet.fullSize,
      ],
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF6D6F75).withValues(alpha: 0.78),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.36),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    top: 22,
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(18, 18, 18, bottom + 18),
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.local_parking_rounded,
                                color: Color(0xFF2155D6),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.mapName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.emptyCount} BOS · ${widget.fullCount} DOLU · ${widget.totalCount}',
                                    style: TextStyle(
                                      color: const Color(0xFF7EF0B3)
                                          .withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    'TOPLAM',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _showParks
                                    ? Icons.grid_view_rounded
                                    : Icons.search_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (widget.multiRoute != null &&
                            widget.multiRoute!.segments.length > 1) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 42,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.multiRoute!.segments.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final segment =
                                    widget.multiRoute!.segments[index];
                                final active =
                                    index == widget.activeSegmentIndex;
                                return InkWell(
                                  onTap: () => widget.onSegmentTap(index),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${segment.buildingName} / ${segment.floorName}',
                                      style: TextStyle(
                                        color: active
                                            ? const Color(0xFF182033)
                                            : Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _ModeButton(
                                  active: !_showParks,
                                  label: 'Navigasyon',
                                  onTap: () =>
                                      setState(() => _showParks = false),
                                ),
                              ),
                              Expanded(
                                child: _ModeButton(
                                  active: _showParks,
                                  label: 'Park Alanlari',
                                  onTap: () =>
                                      setState(() => _showParks = true),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!_showParks) ...[
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.52,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _ActionCard(
                                icon: Icons.near_me_rounded,
                                title: 'Bana En\nYakin',
                                enabled: true,
                                onTap: widget.onNearestToUser,
                              ),
                              _ActionCard(
                                icon: Icons.local_hospital_outlined,
                                title: 'Hastane\nGirisi',
                                enabled: true,
                                onTap: widget.onNearestToHospital,
                              ),
                              _ActionCard(
                                icon: Icons.directions_car_outlined,
                                title: 'Aracima\nGit',
                                enabled: widget.parkedAt != null,
                                onTap: widget.parkedAt != null
                                    ? widget.onNavigateToCar
                                    : null,
                              ),
                              _ActionCard(
                                icon: Icons.logout_rounded,
                                title: 'Cikisa Git',
                                enabled: true,
                                onTap: widget.onNavigateToExit,
                              ),
                            ],
                          ),
                          if (widget.targetPark != null) ...[
                            const SizedBox(height: 12),
                            _GhostAction(
                              label: 'Rotayi Temizle',
                              onTap: widget.onClearNav,
                            ),
                          ],
                        ] else ...[
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.15,
                            ),
                            itemCount: widget.parks.length,
                            itemBuilder: (context, index) {
                              final park = widget.parks[index];
                              final parkKey =
                                  (park.externalReferenceId ?? park.id)
                                      .toUpperCase();
                              final isOccupied = widget.occupancyMap[parkKey];
                              final isTarget = widget.targetPark?.id == park.id;

                              return InkWell(
                                onTap: () => widget.onParkSelected(park),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isTarget
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isTarget
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        park.label,
                                        style: TextStyle(
                                          color: isTarget
                                              ? const Color(0xFF182033)
                                              : Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color:
                                              _spotColor(isOccupied, isTarget),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _spotColor(bool? isOccupied, bool isTarget) {
    if (isTarget) {
      return const Color(0xFF2155D6);
    }
    if (isOccupied == null) {
      return const Color(0xFFB5BECE);
    }
    return isOccupied ? const Color(0xFFE25757) : const Color(0xFF1C9B67);
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.active,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: active ? 1 : 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color:
                    enabled ? const Color(0xFF2155D6) : const Color(0xFFA4ACB9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: enabled ? 1 : 0.55),
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GhostAction extends StatelessWidget {
  const _GhostAction({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Rotayi Temizle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
