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

  final ValueChanged<MapOpenRequest?> onOpenMaps;
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
        hierarchies.add(await _facilityService.getOrganizationHierarchy(organization.id));
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _organizations = organizations;
        _hierarchies = hierarchies;
        _loading = false;
        _error = null;
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

  List<_PublishedFloorCardData> get _publishedFloors => [
        for (final hierarchy in _hierarchies)
          for (final site in hierarchy.sites)
            for (final building in site.buildings)
              for (final floor in building.floors)
                if (floor.hasPublishedMap)
                  _PublishedFloorCardData(
                    organizationId: hierarchy.id,
                    organizationName: hierarchy.name,
                    siteId: site.id,
                    siteName: site.name,
                    buildingId: building.id,
                    buildingName: building.name,
                    floorId: floor.id,
                    floorName: floor.name,
                    floorLevel: floor.level,
                  ),
      ];

  List<_SiteListItemData> get _siteItems => [
        for (final hierarchy in _hierarchies)
          for (final site in hierarchy.sites)
            _SiteListItemData(
              organizationId: hierarchy.id,
              organizationName: hierarchy.name,
              siteId: site.id,
              siteName: site.name,
              buildingCount: site.buildings.length,
              publishedFloorCount: site.buildings
                  .expand((building) => building.floors)
                  .where((floor) => floor.hasPublishedMap)
                  .length,
            ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _OverviewError(message: _error!, onRetry: _loadOverview)
                : Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: _loadOverview,
                  child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 130),
                          children: [
                            Row(
                              children: [
                                const _BrandMark(),
                                const SizedBox(width: 10),
                                const Text(
                                  'BuLocation',
                                  style: TextStyle(
                                    fontSize: 22,
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
                            InkWell(
                              onTap: () => widget.onOpenMaps(null),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                height: 64,
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search_rounded,
                                        color: Color(0xFF7D879C)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _organizations.isEmpty
                                            ? 'Harita secin veya QR okutun'
                                            : 'Yerleske veya bina secin',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          color: Color(0xFF8C95A8),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2155D6),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_outward_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 34),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Yayinlanan Haritalar',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E2639),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => widget.onOpenMaps(null),
                                  child: const Text('Tum Haritalari Gor'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (_publishedFloors.isEmpty)
                              const _EmptyBlock(
                                title: 'Yayinlanmis kat haritasi yok',
                                subtitle: 'Admin panelinden harita yayina alindiginda burada gorunecek.',
                              )
                            else
                              SizedBox(
                                height: 224,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _publishedFloors.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 14),
                                  itemBuilder: (context, index) {
                                    final item = _publishedFloors[index];
                                    return _PublishedFloorCard(
                                      item: item,
                                      onTap: () => widget.onOpenMaps(
                                        MapOpenRequest(
                                          organizationId: item.organizationId,
                                          siteId: item.siteId,
                                          buildingId: item.buildingId,
                                          floorId: item.floorId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 34),
                            const Text(
                              'Tum Yerleskeler',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E2639),
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (_siteItems.isEmpty)
                              const _EmptyBlock(
                                title: 'Yerleske bulunamadi',
                                subtitle: 'Sistemde yayinlanmis bir yerleske verisi olmadiginda bu alan bos kalir.',
                              )
                            else
                              ..._siteItems.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _SiteListTile(
                                    item: item,
                                    onTap: () => widget.onOpenMaps(
                                      MapOpenRequest(
                                        organizationId: item.organizationId,
                                        siteId: item.siteId,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 24,
                        bottom: 28,
                        child: FloatingActionButton(
                          heroTag: 'quick-qr',
                          backgroundColor: const Color(0xFF2155D6),
                          foregroundColor: Colors.white,
                          onPressed: () => _showQuickScanner(context),
                          child: const Icon(Icons.qr_code_scanner_rounded),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Future<void> _showQuickScanner(BuildContext context) async {
    final scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickScannerSheet(
        controller: scanner,
        onDetect: (referenceId) async {
          Navigator.pop(context);
          await widget.onQuickScan(referenceId);
        },
      ),
    );

    await scanner.dispose();
  }

  String _initials(String input) {
    final parts = input
        .split(RegExp(r'\s+'))
        .where((item) => item.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'BL';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF2155D6)),
    );
  }
}

class _PublishedFloorCardData {
  const _PublishedFloorCardData({
    required this.organizationId,
    required this.organizationName,
    required this.siteId,
    required this.siteName,
    required this.buildingId,
    required this.buildingName,
    required this.floorId,
    required this.floorName,
    required this.floorLevel,
  });

  final String organizationId;
  final String organizationName;
  final String siteId;
  final String siteName;
  final String buildingId;
  final String buildingName;
  final String floorId;
  final String floorName;
  final int floorLevel;
}

class _PublishedFloorCard extends StatelessWidget {
  const _PublishedFloorCard({
    required this.item,
    required this.onTap,
  });

  final _PublishedFloorCardData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 116,
              decoration: const BoxDecoration(
                color: Color(0xFFDCE6FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 18,
                    top: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C9B67),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'YAYINDA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: Icon(
                      Icons.map_outlined,
                      size: 58,
                      color: Color(0xFF6E89C9),
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
                    item.buildingName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2639),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.siteName} · ${item.floorName}',
                    style: const TextStyle(
                      color: Color(0xFF5F6B82),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.organizationName,
                    style: const TextStyle(
                      color: Color(0xFF2155D6),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SiteListItemData {
  const _SiteListItemData({
    required this.organizationId,
    required this.organizationName,
    required this.siteId,
    required this.siteName,
    required this.buildingCount,
    required this.publishedFloorCount,
  });

  final String organizationId;
  final String organizationName;
  final String siteId;
  final String siteName;
  final int buildingCount;
  final int publishedFloorCount;
}

class _SiteListTile extends StatelessWidget {
  const _SiteListTile({
    required this.item,
    required this.onTap,
  });

  final _SiteListItemData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.location_city_rounded,
                color: Color(0xFF2155D6),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.siteName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2639),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.organizationName} · ${item.buildingCount} bina · ${item.publishedFloorCount} yayinlanan kat',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6E7890),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA4BA)),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2639),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              height: 1.55,
              color: Color(0xFF6E7890),
            ),
          ),
        ],
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
            const Icon(Icons.error_outline_rounded, size: 34, color: Color(0xFFC53A3A)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF4D5872)),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2155D6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickScannerSheet extends StatelessWidget {
  const _QuickScannerSheet({
    required this.controller,
    required this.onDetect,
  });

  final MobileScannerController controller;
  final Future<void> Function(String referenceId) onDetect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 18),
              const Text(
                'QR okut',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2639),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Okutulan QR hangi kat ya da binaya aitse harita otomatik acilir.',
                style: TextStyle(
                  height: 1.5,
                  color: Color(0xFF6E7890),
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  height: 320,
                  child: MobileScanner(
                    controller: controller,
                    onDetect: (capture) async {
                      final value = capture.barcodes.firstOrNull?.rawValue?.trim();
                      if (value == null || value.isEmpty) {
                        return;
                      }
                      await onDetect(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
