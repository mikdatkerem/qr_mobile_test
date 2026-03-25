import 'package:flutter/material.dart';

import '../app/app_session_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.sessionController});

  final AppSessionController sessionController;

  @override
  Widget build(BuildContext context) {
    final profile = sessionController.profile;
    final fullName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : profile?.userName ?? 'Kullanici';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFD8E0EF),
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials(fullName),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF233353),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2155D6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2236),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile?.email ?? 'profil@bulocation.dev',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF687287),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Row(
              children: [
                Expanded(
                  child: _ProfileStat(
                    icon: Icons.local_parking_rounded,
                    value: '42',
                    label: 'TOPLAM\nPARK',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _ProfileStat(
                    icon: Icons.schedule_rounded,
                    value: '12sa',
                    label: 'KAZANILAN\nZAMAN',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _ProfileStat(
                    icon: Icons.star_border_rounded,
                    value: 'P4',
                    label: 'FAVORI\nYER',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2155D6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Premium Uyelik',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Yillik Plan - 12 Ay',
                          style: TextStyle(
                            color: Color(0xFFDCE6FF),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2155D6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Yonet'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _ProfileMenuTile(
              icon: Icons.history_rounded,
              title: 'Gecmis Islemler',
            ),
            const _ProfileMenuTile(
              icon: Icons.credit_card_rounded,
              title: 'Odeme Yontemleri',
            ),
            const _ProfileMenuTile(
              icon: Icons.settings_outlined,
              title: 'Uygulama Ayarlari',
            ),
            const SizedBox(height: 10),
            _ProfileMenuTile(
              icon: Icons.logout_rounded,
              title: 'Cikis Yap',
              destructive: true,
              onTap: sessionController.signOut,
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
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF2155D6)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20293A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              letterSpacing: 0.4,
              color: Color(0xFF67728B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    this.destructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final bool destructive;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? const Color(0xFFE04F4F) : const Color(0xFF2155D6);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: () async => onTap?.call(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: destructive ? const Color(0xFFFFEFEF) : const Color(0xFFEAF0FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: destructive ? const Color(0xFFD73F3F) : const Color(0xFF1B2438),
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: destructive ? const Color(0xFFE7A2A2) : const Color(0xFFA0AABE),
        ),
      ),
    );
  }
}
