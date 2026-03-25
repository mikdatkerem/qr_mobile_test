import 'package:flutter/material.dart';

import '../models/graph_data.dart';

class ParkBottomSheet extends StatefulWidget {
  const ParkBottomSheet({
    super.key,
    this.controller,
    required this.occupancyMap,
    required this.targetPark,
    required this.parkedAt,
    required this.onParkSelected,
    required this.onNavigateToExit,
    required this.onNavigateToCar,
    required this.onClearNav,
    required this.onNearestToUser,
    required this.onNearestToHospital,
  });

  final Map<String, bool> occupancyMap;
  final MapNode? targetPark;
  final MapNode? parkedAt;
  final void Function(MapNode) onParkSelected;
  final VoidCallback onNavigateToExit;
  final VoidCallback onNavigateToCar;
  final VoidCallback onClearNav;
  final VoidCallback onNearestToUser;
  final VoidCallback onNearestToHospital;
  final DraggableScrollableController? controller;

  @override
  State<ParkBottomSheet> createState() => _ParkBottomSheetState();
}

class _ParkBottomSheetState extends State<ParkBottomSheet>
    with SingleTickerProviderStateMixin {
  static const _peekSize = 0.045;
  static const _halfSize = 0.24;
  static const _fullSize = 0.58;

  late final TabController _tabController;
  late final DraggableScrollableController _internalController;

  DraggableScrollableController get _controller =>
      widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _internalController = DraggableScrollableController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _internalController.dispose();
    super.dispose();
  }

  void _collapse() {
    _controller.animateTo(
      _peekSize,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final parks = allNodes.where((node) => node.isPark).toList();
    final empty = widget.occupancyMap.values.where((value) => !value).length;
    final full = widget.occupancyMap.values.where((value) => value).length;
    final total = parks.length;
    final bottom = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: _peekSize,
      minChildSize: _peekSize,
      maxChildSize: _fullSize,
      snap: true,
      snapSizes: const [_peekSize, _halfSize, _fullSize],
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
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6DDEA),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF0FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_parking_rounded,
                        color: Color(0xFF2155D6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Canli Operasyon',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B2438),
                            ),
                          ),
                          Text(
                            '$empty bos · $full dolu · $total toplam',
                            style: const TextStyle(
                              color: Color(0xFF6D7890),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.targetPark != null)
                      _StatusPill(label: 'Rota ${widget.targetPark!.id}'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F5FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: const Color(0xFF2155D6),
                    unselectedLabelColor: const Color(0xFF8B96AC),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    tabs: const [
                      Tab(text: 'Navigasyon'),
                      Tab(text: 'Park Alanlari'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ListView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(18, 4, 18, bottom + 16),
                      children: [
                        _ActionTile(
                          icon: Icons.near_me_rounded,
                          title: 'Bana En Yakin',
                          subtitle: 'Konumunuza gore en uygun bos alan',
                          onTap: () {
                            _collapse();
                            widget.onNearestToUser();
                          },
                        ),
                        const SizedBox(height: 10),
                        _ActionTile(
                          icon: Icons.local_hospital_outlined,
                          title: 'Hastane Girisine Yakin',
                          subtitle: 'Kuruma en yakin bos park alanini bul',
                          onTap: () {
                            _collapse();
                            widget.onNearestToHospital();
                          },
                        ),
                        const SizedBox(height: 10),
                        if (widget.parkedAt != null)
                          _ActionTile(
                            icon: Icons.directions_car_outlined,
                            title: 'Aracima Git',
                            subtitle: '${widget.parkedAt!.id} alanina rota ciz',
                            onTap: () {
                              _collapse();
                              widget.onNavigateToCar();
                            },
                          ),
                        if (widget.parkedAt != null) const SizedBox(height: 10),
                        _ActionTile(
                          icon: Icons.logout_rounded,
                          title: 'Cikisa Git',
                          subtitle: 'Bulundugunuz kattan cikis rotasi olustur',
                          onTap: () {
                            _collapse();
                            widget.onNavigateToExit();
                          },
                        ),
                        if (widget.targetPark != null) ...[
                          const SizedBox(height: 10),
                          _ActionTile(
                            icon: Icons.close_rounded,
                            title: 'Rotayi Temizle',
                            subtitle: 'Aktif park hedefine cizilen rotayi kapat',
                            destructive: true,
                            onTap: () {
                              _collapse();
                              widget.onClearNav();
                            },
                          ),
                        ],
                      ],
                    ),
                    GridView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(18, 4, 18, bottom + 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.12,
                      ),
                      itemCount: parks.length,
                      itemBuilder: (context, index) {
                        final park = parks[index];
                        final isOccupied = widget.occupancyMap[park.id];
                        final isTarget = widget.targetPark?.id == park.id;
                        final isParkedAt = widget.parkedAt?.id == park.id;

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
                          onTap: isOccupied == true
                              ? null
                              : () {
                                  _collapse();
                                  widget.onParkSelected(park);
                                },
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
              ),
            ],
          ),
        );
      },
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
