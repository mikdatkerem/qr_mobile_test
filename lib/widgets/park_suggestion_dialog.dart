import 'package:flutter/material.dart';
import '../models/graph_data.dart';

class ParkSuggestionDialog extends StatelessWidget {
  final MapNode? nearestToUser;
  final MapNode? nearestToHospital;
  final void Function(MapNode) onSelected;

  const ParkSuggestionDialog({
    super.key,
    required this.nearestToUser,
    required this.nearestToHospital,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.local_parking_rounded,
                  color: Colors.blue.shade600, size: 30),
            ),
            const SizedBox(height: 14),
            const Text('Park Seçeneği',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 4),
            Text('Nereye park etmek istersiniz?',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),

            const SizedBox(height: 20),

            // Bana en yakın
            _SuggestionOption(
              icon: Icons.person_pin_circle_rounded,
              iconBg: Colors.blue.shade600,
              bgColor: Colors.blue.shade50,
              title: 'Bana en yakın',
              subtitle: nearestToUser != null
                  ? 'Alan ${nearestToUser!.id}'
                  : 'Boş alan bulunamadı',
              available: nearestToUser != null,
              onTap: nearestToUser != null
                  ? () {
                      Navigator.pop(context);
                      onSelected(nearestToUser!);
                    }
                  : null,
            ),

            const SizedBox(height: 10),

            // Hastane girişine en yakın
            _SuggestionOption(
              icon: Icons.local_hospital_rounded,
              iconBg: Colors.green.shade600,
              bgColor: Colors.green.shade50,
              title: 'Hastane girişine en yakın',
              subtitle: nearestToHospital != null
                  ? 'Alan ${nearestToHospital!.id}'
                  : 'Boş alan bulunamadı',
              available: nearestToHospital != null,
              onTap: nearestToHospital != null
                  ? () {
                      Navigator.pop(context);
                      onSelected(nearestToHospital!);
                    }
                  : null,
            ),

            const SizedBox(height: 16),

            // Vazgeç
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Şimdi değil',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionOption extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color bgColor;
  final String title;
  final String subtitle;
  final bool available;
  final VoidCallback? onTap;

  const _SuggestionOption({
    required this.icon,
    required this.iconBg,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.available,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = available ? bgColor : Colors.grey.shade50;
    final effectiveIcon = available ? iconBg : Colors.grey.shade400;

    return Material(
      color: effectiveBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: effectiveIcon,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: available
                            ? const Color(0xFF1A1A2E)
                            : Colors.grey.shade400)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: available
                            ? Colors.grey.shade600
                            : Colors.grey.shade400)),
              ],
            )),
            if (available)
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: iconBg),
          ]),
        ),
      ),
    );
  }
}
