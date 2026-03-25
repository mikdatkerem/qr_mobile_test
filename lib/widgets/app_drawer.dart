import 'package:flutter/material.dart';
import '../models/graph_data.dart';

class AppDrawer extends StatelessWidget {
  final Map<String, bool> occupancyMap;
  final MapNode? suggestedPark;
  final String? activeZoneId;
  final MapNode? targetPark;
  final MapNode? parkedAt;
  final void Function(MapNode) onParkSelected;
  final VoidCallback onNavigateToExit;
  final VoidCallback onNavigateToCar;
  final VoidCallback onClearNav;
  final VoidCallback onNearestToUser;
  final VoidCallback onNearestToHospital;

  const AppDrawer({
    super.key,
    required this.occupancyMap,
    required this.suggestedPark,
    required this.activeZoneId,
    required this.targetPark,
    required this.parkedAt,
    required this.onParkSelected,
    required this.onNavigateToExit,
    required this.onNavigateToCar,
    required this.onClearNav,
    required this.onNearestToUser,
    required this.onNearestToHospital,
  });

  @override
  Widget build(BuildContext context) {
    final total = allNodes.where((n) => n.isPark).length;
    final empty = occupancyMap.values.where((v) => !v).length;
    final full = occupancyMap.values.where((v) => v).length;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Başlık ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              color: Colors.blue.shade700,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.local_parking,
                      color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  const Text('Park Durumu',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$empty boş · $full dolu · $total toplam',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Park önerisi butonları ─────────────────────────────────
            DrawerTile(
              icon: Icons.person_pin_circle_rounded,
              iconBg: Colors.blue.shade600,
              bgColor: Colors.blue.shade50,
              label: 'Bana en yakın',
              sublabel: 'Konumunuza göre öneri',
              arrowColor: Colors.blue.shade400,
              onTap: () {
                Navigator.pop(context);
                onNearestToUser();
              },
            ),
            const SizedBox(height: 8),
            DrawerTile(
              icon: Icons.local_hospital_rounded,
              iconBg: Colors.green.shade600,
              bgColor: Colors.green.shade50,
              label: 'Hastane girişine en yakın',
              sublabel: 'En uygun giriş rotası hesaplanacak',
              arrowColor: Colors.green.shade400,
              onTap: () {
                Navigator.pop(context);
                onNearestToHospital();
              },
            ),
            const SizedBox(height: 8),

            if (parkedAt != null) ...[
              DrawerTile(
                icon: Icons.directions_car_rounded,
                iconBg: Colors.blue.shade600,
                bgColor: Colors.blue.shade50,
                label: 'Aracıma Git',
                sublabel: 'Araç ${parkedAt!.id} alanında',
                arrowColor: Colors.blue.shade400,
                onTap: onNavigateToCar,
              ),
              const SizedBox(height: 8),
            ],

            DrawerTile(
              icon: Icons.exit_to_app,
              iconBg: Colors.orange.shade500,
              bgColor: Colors.orange.shade50,
              label: 'Çıkışa Git',
              sublabel: 'Çıkış noktasına yol çiz',
              arrowColor: Colors.orange.shade400,
              onTap: onNavigateToExit,
            ),

            if (targetPark != null) ...[
              const SizedBox(height: 8),
              DrawerTile(
                icon: Icons.cancel_outlined,
                iconBg: Colors.grey.shade500,
                bgColor: Colors.grey.shade100,
                label: 'Rotayı İptal Et',
                sublabel: '${targetPark!.id} rotası temizlenecek',
                arrowColor: Colors.grey.shade400,
                onTap: () {
                  Navigator.pop(context);
                  onClearNav();
                },
              ),
            ],

            const SizedBox(height: 16),
            const Divider(indent: 12, endIndent: 12),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Tüm Park Yerleri',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5)),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.3,
                ),
                itemCount: allNodes.where((n) => n.isPark).length,
                itemBuilder: (_, i) {
                  final park = allNodes.where((n) => n.isPark).toList()[i];
                  final isOccupied = occupancyMap[park.id];
                  final isTarget = targetPark?.id == park.id;
                  final isParkedAt = parkedAt?.id == park.id;
                  final num = park.id.replaceAll(RegExp(r'[^0-9]'), '');

                  Color bg, border, text;
                  if (isParkedAt) {
                    bg = Colors.blue.shade100;
                    border = Colors.blue.shade400;
                    text = Colors.blue.shade800;
                  } else if (isTarget) {
                    bg = Colors.blue.shade600;
                    border = Colors.blue.shade700;
                    text = Colors.white;
                  } else if (isOccupied == null) {
                    bg = Colors.grey.shade100;
                    border = Colors.grey.shade300;
                    text = Colors.grey.shade500;
                  } else if (isOccupied) {
                    bg = Colors.red.shade50;
                    border = Colors.red.shade200;
                    text = Colors.red.shade700;
                  } else {
                    bg = Colors.green.shade50;
                    border = Colors.green.shade300;
                    text = Colors.green.shade700;
                  }

                  return GestureDetector(
                    onTap:
                        isOccupied == true ? null : () => onParkSelected(park),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border, width: 1),
                      ),
                      child: Center(
                        child: Text(num,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: text)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Drawer tile ─────────────────────────────────────────────────────────────

class DrawerTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color bgColor;
  final String label;
  final String sublabel;
  final Color arrowColor;
  final VoidCallback onTap;

  const DrawerTile({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.bgColor,
    required this.label,
    required this.sublabel,
    required this.arrowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: iconBg, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: Colors.white, size: 22)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E))),
                    Text(sublabel,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                )),
                Icon(Icons.arrow_forward_ios, size: 14, color: arrowColor),
              ]),
            ),
          ),
        ),
      );
}
