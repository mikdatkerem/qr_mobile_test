import 'package:flutter/material.dart';
import '../models/graph_data.dart';

/// Hamburger ikonuna basınca açılan bottom sheet.
/// İki sekme: Genel (öneri, araç, çıkış) | Park Alanları (grid)
void showParkSheet(
  BuildContext context, {
  required Map<String, bool> occupancyMap,
  required MapNode? suggestedPark,
  required MapNode? targetPark,
  required MapNode? parkedAt,
  required void Function(MapNode) onParkSelected,
  required VoidCallback onNavigateToExit,
  required VoidCallback onNavigateToCar,
  required VoidCallback onClearNav,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ParkSheetContent(
      occupancyMap: occupancyMap,
      suggestedPark: suggestedPark,
      targetPark: targetPark,
      parkedAt: parkedAt,
      onParkSelected: onParkSelected,
      onNavigateToExit: onNavigateToExit,
      onNavigateToCar: onNavigateToCar,
      onClearNav: onClearNav,
    ),
  );
}

// ─── Sheet içeriği ────────────────────────────────────────────────────────────

class _ParkSheetContent extends StatefulWidget {
  final Map<String, bool> occupancyMap;
  final MapNode? suggestedPark;
  final MapNode? targetPark;
  final MapNode? parkedAt;
  final void Function(MapNode) onParkSelected;
  final VoidCallback onNavigateToExit;
  final VoidCallback onNavigateToCar;
  final VoidCallback onClearNav;

  const _ParkSheetContent({
    required this.occupancyMap,
    required this.suggestedPark,
    required this.targetPark,
    required this.parkedAt,
    required this.onParkSelected,
    required this.onNavigateToExit,
    required this.onNavigateToCar,
    required this.onClearNav,
  });

  @override
  State<_ParkSheetContent> createState() => _ParkSheetContentState();
}

class _ParkSheetContentState extends State<_ParkSheetContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parks = allNodes.where((n) => n.isPark).toList();
    final total = parks.length;
    final empty = widget.occupancyMap.values.where((v) => !v).length;
    final full = widget.occupancyMap.values.where((v) => v).length;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Başlık + istatistik ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_parking_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Park Yönetimi',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E))),
                      Text('$empty boş  ·  $full dolu  ·  $total toplam',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                _Chip(label: '$empty', color: Colors.green.shade500),
                const SizedBox(width: 6),
                _Chip(label: '$full', color: Colors.red.shade400),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Tab bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF1A1A2E),
                unselectedLabelColor: Colors.grey.shade400,
                labelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                tabs: const [
                  Tab(text: 'Genel'),
                  Tab(text: 'Park Alanları'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),
          Divider(height: 1, color: Colors.grey.shade100),

          // ── İçerik ──────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // ── Genel sekmesi ────────────────────────────────────────
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
                  child: Column(
                    children: [
                      if (widget.suggestedPark != null) ...[
                        _ActionTile(
                          icon: Icons.stars_rounded,
                          iconBg: Colors.green.shade500,
                          label: 'Önerilen Park',
                          sublabel: widget.suggestedPark!.id,
                          accentColor: Colors.green,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onParkSelected(widget.suggestedPark!);
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (widget.parkedAt != null) ...[
                        _ActionTile(
                          icon: Icons.directions_car_rounded,
                          iconBg: Colors.blue.shade600,
                          label: 'Aracıma Git',
                          sublabel:
                              '${widget.parkedAt!.id} alanında park edildi',
                          accentColor: Colors.blue,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onNavigateToCar();
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      _ActionTile(
                        icon: Icons.exit_to_app_rounded,
                        iconBg: Colors.orange.shade500,
                        label: 'Çıkışa Git',
                        sublabel: 'Çıkış noktasına yol çiz',
                        accentColor: Colors.orange,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onNavigateToExit();
                        },
                      ),
                      if (widget.targetPark != null) ...[
                        const SizedBox(height: 10),
                        _ActionTile(
                          icon: Icons.close_rounded,
                          iconBg: Colors.grey.shade400,
                          label: 'Navigasyonu İptal Et',
                          sublabel:
                              '${widget.targetPark!.id} rotası temizlenecek',
                          accentColor: Colors.grey,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onClearNav();
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Park Alanları sekmesi ────────────────────────────────
                GridView.builder(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: parks.length,
                  itemBuilder: (_, i) {
                    final park = parks[i];
                    final isOccupied = widget.occupancyMap[park.id];
                    final isTarget = widget.targetPark?.id == park.id;
                    final num = park.id.replaceAll(RegExp(r'[^0-9]'), '');

                    final Color bg, border, textColor;
                    if (isTarget) {
                      bg = Colors.blue.shade600;
                      border = Colors.blue.shade700;
                      textColor = Colors.white;
                    } else if (isOccupied == null) {
                      bg = Colors.grey.shade100;
                      border = Colors.grey.shade300;
                      textColor = Colors.grey.shade500;
                    } else if (isOccupied) {
                      bg = Colors.red.shade50;
                      border = Colors.red.shade200;
                      textColor = Colors.red.shade400;
                    } else {
                      bg = Colors.green.shade50;
                      border = Colors.green.shade300;
                      textColor = Colors.green.shade700;
                    }

                    return GestureDetector(
                      onTap: isOccupied == true
                          ? null
                          : () {
                              Navigator.pop(context);
                              widget.onParkSelected(park);
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: border, width: 1.2),
                        ),
                        child: Center(
                          child: Text(num,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textColor)),
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
  }
}

// ─── Yardımcı widgetlar ───────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String sublabel;
  final Color accentColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.sublabel,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 2),
                      Text(sublabel,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ]),
      );
}
