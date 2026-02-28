import 'package:flutter/material.dart';
import '../models/zone_model.dart';

class ProgressBar extends StatelessWidget {
  final List<ZoneModel> zones;
  final Set<String> visitedIds;
  final String? activeZoneLabel;

  const ProgressBar({
    super.key,
    required this.zones,
    required this.visitedIds,
    this.activeZoneLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = zones.length;
    final visited = visitedIds.length;
    final progress = total == 0 ? 0.0 : visited / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: visited > 0
                      ? Colors.green.withOpacity(0.15)
                      : theme.colorScheme.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  visited > 0 ? Icons.location_on : Icons.explore_outlined,
                  color: visited > 0
                      ? Colors.green.shade600
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeZoneLabel != null
                          ? 'Şu anda buradasınız'
                          : 'QR kodu okutun',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      activeZoneLabel ?? 'Henüz konum belirlenmedi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Ziyaret sayacı
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: visited > 0
                      ? Colors.green.withOpacity(0.12)
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$visited / $total',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: visited > 0
                        ? Colors.green.shade700
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // İlerleme çubuğu
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    visited == total && total > 0
                        ? Colors.green.shade500
                        : theme.colorScheme.primary,
                  ),
                );
              },
            ),
          ),

          if (visited == total && total > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.celebration, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 6),
                Text(
                  'Tüm noktalar ziyaret edildi!',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
