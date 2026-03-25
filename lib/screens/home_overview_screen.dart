import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/auth_models.dart';

class HomeOverviewScreen extends StatelessWidget {
  const HomeOverviewScreen({
    super.key,
    required this.onOpenMaps,
    required this.onQuickScan,
    required this.profile,
  });

  final VoidCallback onOpenMaps;
  final Future<void> Function(String referenceId) onQuickScan;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: Color(0xFF2155D6),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'BuLocation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2155D6),
                  ),
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFD9E2F6),
                  child: Text(
                    _initials(profile?.fullName ?? profile?.userName ?? 'BL'),
                    style: const TextStyle(
                      color: Color(0xFF24314F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE4EAF5)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  const Icon(Icons.search_rounded, color: Color(0xFF97A1B7)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Isletme veya otopark ara...',
                      style: TextStyle(
                        color: Color(0xFF97A1B7),
                        fontSize: 17,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onOpenMaps,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2155D6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.near_me_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 34),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Yakindaki Otoparklar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2639),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Tumunu Gor'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 218,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _ParkingCard(
                    title: 'Merkez AVM Otoparki',
                    distance: '450m',
                    spots: '12 Bos Yer',
                    available: true,
                  ),
                  SizedBox(width: 14),
                  _ParkingCard(
                    title: 'Plaza X Otoparki',
                    distance: '1.2km',
                    spots: '4 Bos Yer',
                    available: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 34),
            const Text(
              'Tum Isletmeler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2639),
              ),
            ),
            const SizedBox(height: 18),
            const _BusinessTile(
              icon: Icons.shopping_bag_outlined,
              title: 'Trend Alisveris Merkezi',
              subtitle: 'Ataturk Cad. No: 45, Besiktas',
            ),
            const SizedBox(height: 12),
            const _BusinessTile(
              icon: Icons.restaurant_outlined,
              title: 'Gurme Restoran Kompleksi',
              subtitle: 'Sahil Yolu, No: 12, Bebek',
            ),
            const SizedBox(height: 12),
            const _BusinessTile(
              icon: Icons.fitness_center_outlined,
              title: 'Peak Performance Gym',
              subtitle: 'Levent Plaza, Kat: B2',
            ),
            const SizedBox(height: 12),
            const _BusinessTile(
              icon: Icons.local_hospital_outlined,
              title: 'Ozel Sehir Hastanesi',
              subtitle: 'Fulya Sokak, No: 88, Sisli',
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => _showQuickScanner(context),
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2155D6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  Future<void> _showQuickScanner(BuildContext context) async {
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    var handled = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (sheetContext) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: MobileScanner(
                  controller: controller,
                  onDetect: (capture) async {
                    if (handled) {
                      return;
                    }
                    final value = capture.barcodes.firstOrNull?.rawValue?.trim();
                    if (value == null || value.isEmpty) {
                      return;
                    }
                    handled = true;
                    Navigator.pop(sheetContext);
                    await onQuickScan(value);
                  },
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 40,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'QR kodunu okutun. Ilgili bina ve kat otomatik acilacak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    await controller.dispose();
  }
}

class _ParkingCard extends StatelessWidget {
  const _ParkingCard({
    required this.title,
    required this.distance,
    required this.spots,
    required this.available,
  });

  final String title;
  final String distance;
  final String spots;
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 268,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110E1830),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFDDE3EE),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_parking_rounded,
                      size: 72,
                      color: Color(0xFF9AA6BC),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E8E62),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      available ? 'MUSAIT' : 'DOLU',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D2435),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 17, color: Color(0xFF77819A)),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: const TextStyle(color: Color(0xFF58627A)),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.local_parking_outlined, size: 17, color: Color(0xFF0E8E62)),
                    const SizedBox(width: 4),
                    Text(
                      spots,
                      style: const TextStyle(
                        color: Color(0xFF0E8E62),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessTile extends StatelessWidget {
  const _BusinessTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF2155D6)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF1D2435),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF6E7890)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8C97AF)),
        ],
      ),
    );
  }
}
