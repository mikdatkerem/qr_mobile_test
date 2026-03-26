import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/auth_models.dart';
import '../models/facility_models.dart';
import '../services/facility_service.dart';

class HomeOverviewScreen extends StatefulWidget {
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
  State<HomeOverviewScreen> createState() => _HomeOverviewScreenState();
}

class _HomeOverviewScreenState extends State<HomeOverviewScreen> {
  final _facilityService = FacilityService();

  bool _loading = true;
  String? _error;
  List<OrganizationSummary> _organizations = const [];
  List<OrganizationHierarchy> _hierarchies = const [];

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    try {
      final organizations = await _facilityService.getOrganizations();
      final hierarchies = <OrganizationHierarchy>[];

      for (final organization in organizations) {
        final hierarchy =
            await _facilityService.getOrganizationHierarchy(organization.id);
        hierarchies.add(hierarchy);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _organizations = organizations;
        _hierarchies = hierarchies;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<SiteHierarchy> get _sites => [
        for (final hierarchy in _hierarchies) ...hierarchy.sites,
      ];

  List<BuildingHierarchy> get _buildings => [
        for (final site in _sites) ...site.buildings,
      ];

  List<_PublishedFloorItem> get _publishedFloors => [
        for (final hierarchy in _hierarchies)
          for (final site in hierarchy.sites)
            for (final building in site.buildings)
              for (final floor in building.floors)
                if (floor.hasPublishedMap)
                  _PublishedFloorItem(
                    organizationName: hierarchy.name,
                    siteName: site.name,
                    buildingName: building.name,
                    floorName: floor.name,
                  ),
      ];

  @override
  Widget build(BuildContext context) {
    final sites = _sites;
    final buildings = _buildings;
    final publishedFloors = _publishedFloors;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _OverviewError(
                    message: _error!,
                    onRetry: _loadOverview,
                  )
                : RefreshIndicator(
                    onRefresh: _loadOverview,
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
                                _initials(
                                  widget.profile?.fullName ??
                                      widget.profile?.userName ??
                                      'BL',
                                ),
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
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE4EAF5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Indoor navigation ağı hazır',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E2639),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${_organizations.length} organizasyon, ${sites.length} yerleşke, ${buildings.length} bina ve ${publishedFloors.length} yayınlanan kat haritası yönetiliyor.',
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.55,
                                  color: Color(0xFF667086),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Organizasyon',
                                      value: '${_organizations.length}',
                                      icon: Icons.apartment_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Yerleşke',
                                      value: '${sites.length}',
                                      icon: Icons.location_city_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Yayınlanan Kat',
                                      value: '${publishedFloors.length}',
                                      icon: Icons.layers_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: widget.onOpenMaps,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF2155D6),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(54),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      icon: const Icon(Icons.map_rounded),
                                      label: const Text('Haritaları Aç'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () => _showQuickScanner(context),
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF0FF),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: const Icon(
                                        Icons.qr_code_scanner_rounded,
                                        color: Color(0xFF2155D6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Yerleşkeler',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2639),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (sites.isEmpty)
                          const _EmptyBlock(
                            message: 'Henüz görüntülenecek yerleşke yok.',
                          )
                        else
                          ...sites.map(
                            (site) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _FacilityTile(
                                icon: Icons.location_city_rounded,
                                title: site.name,
                                subtitle:
                                    '${site.code} · ${site.buildings.length} bina',
                                onTap: widget.onOpenMaps,
                              ),
                            ),
                          ),
                        const SizedBox(height: 22),
                        const Text(
                          'Yayınlanan Kat Haritaları',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2639),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (publishedFloors.isEmpty)
                          const _EmptyBlock(
                            message: 'Henüz yayınlanan kat haritası yok.',
                          )
                        else
                          ...publishedFloors.take(8).map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _FacilityTile(
                                icon: Icons.layers_rounded,
                                title: item.floorName,
                                subtitle:
                                    '${item.siteName} / ${item.buildingName}',
                                trailingLabel: item.organizationName,
                                onTap: widget.onOpenMaps,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
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
                    await widget.onQuickScan(value);
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
                    'QR kodunu okutun. İlgili bina ve kat otomatik açılacak.',
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

class _PublishedFloorItem {
  const _PublishedFloorItem({
    required this.organizationName,
    required this.siteName,
    required this.buildingName,
    required this.floorName,
  });

  final String organizationName;
  final String siteName;
  final String buildingName;
  final String floorName;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2155D6), size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2435),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6E7890),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityTile extends StatelessWidget {
  const _FacilityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
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
            if (trailingLabel != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  trailingLabel!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B96AC),
                  ),
                ),
              ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8C97AF),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF6E7890),
          fontSize: 14,
        ),
      ),
    );
  }
}

class _OverviewError extends StatelessWidget {
  const _OverviewError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: Color(0xFFE25757),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5E677C),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2155D6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
