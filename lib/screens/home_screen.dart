import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/facility_models.dart';
import '../models/graph_data.dart';
import '../services/facility_service.dart';
import '../services/parking_service.dart';
import '../services/pathfinding_service.dart';
import '../widgets/embedded_scanner.dart';
import '../widgets/floor_plan_widget.dart';
import '../widgets/nav_banner.dart';
import '../widgets/park_bottom_sheet.dart';
import '../widgets/park_confirm_dialog.dart';
import '../widgets/park_selector_sheet.dart';
import '../widgets/park_suggestion_dialog.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => MapsScreenState();
}

class MapsScreenState extends State<MapsScreen> {
  final _facilityService = FacilityService();
  final _pathfinder = PathfindingService();
  final _scannerController =
      MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  final _sheetController = DraggableScrollableController();
  late final ParkingService _parkingService;

  List<OrganizationSummary> _organizations = [];
  OrganizationHierarchy? _hierarchy;
  SiteHierarchy? _site;
  BuildingHierarchy? _building;
  FloorHierarchy? _floor;
  PublishedMapData? _map;
  List<MapNode> _displayNodes = const [];

  bool _busy = false;
  bool _loading = true;
  MapNode? _targetPark;
  MapNode? _parkedAt;
  List<MapNode>? _route;
  MultiRouteResult? _multiRoute;
  int _activeRouteSegmentIndex = 0;
  String? _distanceLabel;
  String? _lastScan;
  DateTime? _lastScanTime;
  Map<String, bool> _occupancy = {};

  @override
  void initState() {
    super.initState();
    _parkingService = ParkingService(onOccupancyChanged: _onOccupancyChanged);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _sheetController.dispose();
    _parkingService.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadFacilityContext();
    await _parkingService.startListening();
  }

  Future<void> _loadFacilityContext() async {
    try {
      final organizations = await _facilityService.getOrganizations();
      final hierarchy =
          await _facilityService.getOrganizationHierarchy(organizations.first.id);
      final selection = _firstPublishedFloor(hierarchy);
      if (selection == null) {
        throw Exception('Yayinlanmis harita bulunamadi.');
      }
      await _applySelection(
        hierarchy: hierarchy,
        site: selection.site,
        building: selection.building,
        floor: selection.floor,
        organizations: organizations,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(error);
    }
  }

  Future<void> _loadOccupancy() async {
    final floor = _floor;
    if (floor == null) {
      return;
    }

    try {
      final occupancy = await _parkingService.getOccupancyMap(floor.id);
      if (mounted) {
        setState(() => _occupancy = _normalizeOccupancy(occupancy));
      }
    } catch (error) {
      if (mounted) _showError('Park durumu yuklenemedi: $error');
    }
  }

  Map<String, bool> _normalizeOccupancy(Map<String, bool> occupancy) =>
      occupancy.map((key, value) => MapEntry(key.toUpperCase(), value));

  Future<void> _applySelection({
    required OrganizationHierarchy hierarchy,
    required SiteHierarchy site,
    required BuildingHierarchy building,
    required FloorHierarchy floor,
    List<OrganizationSummary>? organizations,
  }) async {
    if (mounted) setState(() => _loading = true);
    final publishedMap = await _facilityService.getPublishedMap(floor.id);
    replaceGraph(
      nodes: publishedMap.nodes,
      edges: publishedMap.edges,
      mapAssetPath: publishedMap.assetPath,
      mapAssetContentType: publishedMap.assetContentType,
      mapWidth: publishedMap.width,
      mapHeight: publishedMap.height,
    );
    if (!mounted) return;
    setState(() {
      _organizations = organizations ?? _organizations;
      _hierarchy = hierarchy;
      _site = site;
      _building = building;
      _floor = floor;
      _map = publishedMap;
      _displayNodes = publishedMap.nodes;
      _loading = false;
      _targetPark = null;
      _route = null;
      _multiRoute = null;
      _activeRouteSegmentIndex = 0;
      _distanceLabel = null;
      _lastScan = null;
    });
    await _loadOccupancy();
  }

  void _onOccupancyChanged(String spotId, bool isOccupied) {
    if (!mounted) return;
    final key = spotId.toUpperCase();
    if (!_occupancy.containsKey(key)) {
      return;
    }
    final wasEmpty = _occupancy[key] == false;
    setState(() => _occupancy[key] = isOccupied);
    final targetRef = (_targetPark?.externalReferenceId ?? _targetPark?.id)?.toUpperCase();
    if (isOccupied && wasEmpty && targetRef == key) {
      _showParkConfirmDialog(key);
    }
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    final value = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (value == null || value.isEmpty) return;
    final now = DateTime.now();
    if (_lastScan == value &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(seconds: 3)) {
      return;
    }
    _lastScan = value;
    _lastScanTime = now;
    await openByQrReference(value);
  }

  Future<void> openByQrReference(String referenceId) async {
    if (_busy) return;
    await HapticFeedback.mediumImpact();
    if (mounted) setState(() => _busy = true);
    try {
      final context = await _facilityService.resolveQrScanContext(referenceId);
      await _applyScanContext(context);
      if (!mounted) return;
      setState(() => _busy = false);
      if (_targetPark != null) {
        await _updateRoute(referenceId);
      } else {
        _showSuggestionDialog();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(error);
    }
  }

  Future<void> _applyScanContext(QrScanContext context) async {
    final hierarchy = _hierarchy?.id == context.organizationId
        ? _hierarchy!
        : await _facilityService.getOrganizationHierarchy(context.organizationId);
    final site = hierarchy.sites.where((item) => item.id == context.siteId).firstOrNull;
    final building =
        site?.buildings.where((item) => item.id == context.buildingId).firstOrNull;
    final floor =
        building?.floors.where((item) => item.id == context.floorId).firstOrNull;
    if (site == null || building == null || floor == null) {
      throw Exception('QR baglami icin kat bulunamadi.');
    }
    if (_floor?.id != floor.id || _hierarchy?.id != hierarchy.id) {
      await _applySelection(
        hierarchy: hierarchy,
        site: site,
        building: building,
        floor: floor,
      );
    }
    _lastScan = context.referenceId;
  }

  Future<void> _updateRoute(String fromReferenceId) async {
    if (_targetPark == null || _floor == null) return;
    try {
      final result = await _pathfinder.findFacilityRoute(
        floorId: _floor!.id,
        fromReferenceId: fromReferenceId,
        toReferenceId: _targetPark!.externalReferenceId ?? _targetPark!.id,
      );
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _multiRoute = null;
          _activeRouteSegmentIndex = 0;
          _route = result.nodes;
          _displayNodes = _map?.nodes ?? allNodes;
          _distanceLabel = result.distanceLabel;
          if (result.mapAssetPath != null) {
            currentMapAssetPath = result.mapAssetPath;
            currentMapWidth = result.mapWidth ?? currentMapWidth;
            currentMapHeight = result.mapHeight ?? currentMapHeight;
          }
        });
        return;
      }

      final multiRoute = await _pathfinder.findFacilityMultiRoute(
        fromReferenceId: fromReferenceId,
        toReferenceId: _targetPark!.externalReferenceId ?? _targetPark!.id,
      );

      if (!mounted) return;
      if (multiRoute == null || multiRoute.segments.isEmpty) {
        _showError('Bu konumdan hedefe rota bulunamadi.');
        return;
      }

      setState(() {
        _multiRoute = multiRoute;
        _activeRouteSegmentIndex = 0;
        _distanceLabel = multiRoute.distanceLabel;
      });

      await _showRouteSegment(0);
    } catch (error) {
      _showError('Rota hesaplanamadi: $error');
    }
  }

  Future<void> _showRouteSegment(int index) async {
    final multiRoute = _multiRoute;
    if (multiRoute == null || index < 0 || index >= multiRoute.segments.length) {
      return;
    }

    final segment = multiRoute.segments[index];
    final occupancy = await _parkingService.getOccupancyMap(segment.floorId);

    if (!mounted) {
      return;
    }

    setState(() {
      _activeRouteSegmentIndex = index;
      _route = segment.nodes;
      _displayNodes = segment.nodes;
      _occupancy = _normalizeOccupancy(occupancy);
      currentMapAssetPath = segment.mapAssetPath;
      currentMapAssetContentType = segment.mapAssetContentType;
      currentMapWidth = segment.mapWidth;
      currentMapHeight = segment.mapHeight;
    });
  }

  void _showSuggestionDialog() {
    if (_lastScan == null) return;
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => ParkSuggestionDialog(
        nearestToUser: _pathfinder.nearestEmptyParkToUser(_lastScan!, _occupancy),
        nearestToHospital: null,
        onSelected: (park) {
          setState(() {
            _targetPark = park;
            _route = null;
            _multiRoute = null;
          });
          unawaited(_updateRoute(_lastScan!));
        },
      ),
    );
  }

  Future<void> _navigateToBestExit() async {
    if (_lastScan == null) {
      _showError('Once bir QR kodu okutun.');
      return;
    }

    try {
      final result = await _pathfinder.findBestExitRoute(fromReferenceId: _lastScan!);
      if (result == null || result.segments.isEmpty) {
        _showError('Cikis rotasi bulunamadi.');
        return;
      }

      setState(() {
        _targetPark = null;
        _multiRoute = result;
        _activeRouteSegmentIndex = 0;
        _distanceLabel = result.distanceLabel;
      });

      await _showRouteSegment(0);
    } catch (error) {
      _showError('Cikis rotasi hesaplanamadi: $error');
    }
  }

  Future<void> _selectParkingNearEntrance() async {
    if (_lastScan == null) {
      _showError('Once bir QR kodu okutun.');
      return;
    }

    try {
      final result = await _pathfinder.findRecommendedParkingNearEntrance(
        fromReferenceId: _lastScan!,
      );

      if (result == null || result.segments.isEmpty) {
        _showError('Giris yakin uygun park alani bulunamadi.');
        return;
      }

      final lastNode = result.segments.last.nodes.last;
      final target = MapNode(
        id: result.target.code.toUpperCase(),
        label: result.target.label,
        x: lastNode.x,
        y: lastNode.y,
        type: NodeType.park,
        externalReferenceId: result.target.externalReferenceId,
      );

      setState(() {
        _targetPark = target;
        _multiRoute = MultiRouteResult(
          segments: result.segments,
          distanceMeters: result.distanceMeters,
          distanceLabel: result.distanceLabel,
        );
        _activeRouteSegmentIndex = 0;
        _distanceLabel = result.distanceLabel;
      });

      await _showRouteSegment(0);
    } catch (error) {
      _showError('Giris yakin park onerisi alinamadi: $error');
    }
  }

  void _showParkSelector() {
    if (_lastScan == null) {
      _showError('Once bir QR kodu okutun.');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParkSelectorSheet(
        pathfinder: _pathfinder,
        occupancyMap: _occupancy,
        onParkSelected: (park) {
          setState(() {
            _targetPark = park;
            _route = null;
            _multiRoute = null;
          });
          unawaited(_updateRoute(_lastScan!));
        },
      ),
    );
  }

  void _showParkConfirmDialog(String spotId) {
    final park = allNodes
        .where((node) => (node.externalReferenceId ?? node.id).toUpperCase() == spotId)
        .firstOrNull;
    if (park == null) return;
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => ParkConfirmDialog(
        park: park,
        onConfirm: () {
          Navigator.pop(context);
          setState(() {
            _parkedAt = park;
            _targetPark = null;
            _route = null;
            _multiRoute = null;
            _displayNodes = _map?.nodes ?? allNodes;
            _distanceLabel = null;
          });
        },
        onDeny: () => Navigator.pop(context),
      ),
    );
  }

  void _showPicker<T>({
    required List<T> items,
    required T? selected,
    required String Function(T) title,
    String Function(T)? subtitle,
    required Future<void> Function(T) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final item = items[index];
            return ListTile(
              title: Text(title(item), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: subtitle != null ? Text(subtitle(item)) : null,
              trailing: identical(item, selected)
                  ? const Icon(Icons.check_circle, color: Color(0xFF2155D6))
                  : null,
              onTap: () async {
                Navigator.pop(sheetContext);
                await onSelected(item);
              },
            );
          },
        ),
      ),
    );
  }

  void _showOrganizationPicker() => _showPicker<OrganizationSummary>(
        items: _organizations,
        selected: _organizations.where((o) => o.id == _hierarchy?.id).firstOrNull,
        title: (item) => item.name,
        subtitle: (item) => item.description ?? '',
        onSelected: (organization) async {
          final hierarchy = await _facilityService.getOrganizationHierarchy(organization.id);
          final selection = _firstPublishedFloor(hierarchy);
          if (selection == null) throw Exception('Yayinlanmis harita bulunamadi.');
          await _applySelection(
            hierarchy: hierarchy,
            site: selection.site,
            building: selection.building,
            floor: selection.floor,
          );
        },
      );

  void _showSitePicker() {
    final hierarchy = _hierarchy;
    if (hierarchy == null) return;
    _showPicker<SiteHierarchy>(
      items: hierarchy.sites,
      selected: _site,
      title: (item) => item.name,
      subtitle: (item) => item.code,
      onSelected: (site) async {
        final selection = _firstPublishedFloorInSite(site);
        if (selection == null) throw Exception('Yayinlanmis harita bulunamadi.');
        await _applySelection(
          hierarchy: hierarchy,
          site: selection.site,
          building: selection.building,
          floor: selection.floor,
        );
      },
    );
  }

  void _showBuildingPicker() {
    final hierarchy = _hierarchy;
    final site = _site;
    if (hierarchy == null || site == null) return;
    _showPicker<BuildingHierarchy>(
      items: site.buildings,
      selected: _building,
      title: (item) => item.name,
      subtitle: (item) => item.code,
      onSelected: (building) async {
        final floor = _firstPublishedFloorInBuilding(building);
        if (floor == null) throw Exception('Yayinlanmis harita bulunamadi.');
        await _applySelection(
          hierarchy: hierarchy,
          site: site,
          building: building,
          floor: floor,
        );
      },
    );
  }

  void _showFloorPicker() {
    final hierarchy = _hierarchy;
    if (hierarchy == null) return;
    final options = <_FloorOption>[
      for (final site in hierarchy.sites)
        for (final building in site.buildings)
          for (final floor in building.floors.where((item) => item.hasPublishedMap))
            _FloorOption(site: site, building: building, floor: floor),
    ];
    _showPicker<_FloorOption>(
      items: options,
      selected: options.where((o) => o.floor.id == _floor?.id).firstOrNull,
      title: (item) => item.floor.name,
      subtitle: (item) => '${item.site.name} / ${item.building.name}',
      onSelected: (item) => _applySelection(
        hierarchy: hierarchy,
        site: item.site,
        building: item.building,
        floor: item.floor,
      ),
    );
  }

  _FloorOption? _firstPublishedFloor(OrganizationHierarchy hierarchy) {
    for (final site in hierarchy.sites) {
      final selection = _firstPublishedFloorInSite(site);
      if (selection != null) return selection;
    }
    return null;
  }

  _FloorOption? _firstPublishedFloorInSite(SiteHierarchy site) {
    for (final building in site.buildings) {
      final floor = _firstPublishedFloorInBuilding(building);
      if (floor != null) return _FloorOption(site: site, building: building, floor: floor);
    }
    return null;
  }

  FloorHierarchy? _firstPublishedFloorInBuilding(BuildingHierarchy building) {
    for (final floor in building.floors) {
      if (floor.hasPublishedMap) return floor;
    }
    return null;
  }

  void _showError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final emptyCount = _occupancy.values.where((value) => value == false).length;
    final fullCount = _occupancy.values.where((value) => value == true).length;
    final activeNodeId = _displayNodes
        .where((node) => node.externalReferenceId == _lastScan)
        .firstOrNull
        ?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_2_rounded, color: Color(0xFF2155D6)),
                            const SizedBox(width: 10),
                            const Text('Haritalar',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _showPicker<MapNode>(
                                items: allNodes.where((node) => node.isQr).toList(),
                                selected: null,
                                title: (item) => item.label,
                                subtitle: (item) => item.externalReferenceId ?? item.id,
                                onSelected: (item) =>
                                    openByQrReference(item.externalReferenceId ?? item.id),
                              ),
                              icon: const Icon(Icons.qr_code_rounded),
                              label: const Text('Test QR'),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: _ContextCard(
                          organization: _hierarchy?.name ?? 'Organizasyon',
                          site: _site?.name ?? 'Yerleske',
                          building: _building?.name ?? 'Bina',
                          floor: _floor?.name ?? 'Kat',
                          onOrganizationTap: _showOrganizationPicker,
                          onSiteTap: _showSitePicker,
                          onBuildingTap: _showBuildingPicker,
                          onFloorTap: _showFloorPicker,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              EmbeddedScanner(
                                controller: _scannerController,
                                onDetect: _onQrDetected,
                                isLoading: _busy,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: _InfoChip(title: 'Aktif Nokta', value: _lastScan ?? 'QR bekleniyor', icon: Icons.pin_drop_outlined)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _InfoChip(title: 'Bos Yer', value: '$emptyCount', icon: Icons.local_parking_outlined)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_targetPark != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: NavBanner(
                            targetPark: _targetPark!,
                            distanceLabel: _distanceLabel,
                            onClear: () => setState(() {
                              _targetPark = null;
                              _route = null;
                              _distanceLabel = null;
                            }),
                            onTap: _showParkSelector,
                          ),
                        ),
                      if (_multiRoute != null && _multiRoute!.segments.length > 1)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: _RouteSegmentsCard(
                            result: _multiRoute!,
                            activeIndex: _activeRouteSegmentIndex,
                            onSegmentTap: (index) => unawaited(_showRouteSegment(index)),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_map?.name ?? 'Harita',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$emptyCount BOS / $fullCount DOLU / ${_occupancy.length} TOPLAM',
                                      style: const TextStyle(color: Color(0xFF1BA46C), fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: _showParkSelector,
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(Icons.search_rounded, color: Color(0xFF6F7992)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: FloorPlanWidget(
                                visitedIds: const {},
                                activeZoneId: activeNodeId,
                                navigationRoute: _route,
                                occupancyMap: _occupancy,
                                nodes: _displayNodes,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ParkBottomSheet(
                  controller: _sheetController,
                  occupancyMap: _occupancy,
                  targetPark: _targetPark,
                  parkedAt: _parkedAt,
                  onParkSelected: (park) {
                    _sheetController.animateTo(0.045,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic);
                    setState(() {
                      _targetPark = park;
                      _route = null;
                      _multiRoute = null;
                    });
                    if (_lastScan != null) unawaited(_updateRoute(_lastScan!));
                  },
                  onNavigateToExit: () {
                    unawaited(_navigateToBestExit());
                  },
                  onNavigateToCar: () {
                    if (_parkedAt == null || _lastScan == null) return;
                    setState(() => _targetPark = _parkedAt);
                    unawaited(_updateRoute(_lastScan!));
                  },
                  onClearNav: () => setState(() {
                    _targetPark = null;
                    _route = null;
                    _multiRoute = null;
                    _displayNodes = _map?.nodes ?? allNodes;
                    _distanceLabel = null;
                  }),
                  onNearestToUser: () {
                    if (_lastScan == null) return;
                    final park = _pathfinder.nearestEmptyParkToUser(_lastScan!, _occupancy);
                    if (park == null) return;
                    setState(() {
                      _targetPark = park;
                      _multiRoute = null;
                    });
                    unawaited(_updateRoute(_lastScan!));
                  },
                  onNearestToHospital: () {
                    unawaited(_selectParkingNearEntrance());
                  },
                ),
              ],
            ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.organization,
    required this.site,
    required this.building,
    required this.floor,
    required this.onOrganizationTap,
    required this.onSiteTap,
    required this.onBuildingTap,
    required this.onFloorTap,
  });

  final String organization;
  final String site;
  final String building;
  final String floor;
  final VoidCallback onOrganizationTap;
  final VoidCallback onSiteTap;
  final VoidCallback onBuildingTap;
  final VoidCallback onFloorTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SelectionChip(label: organization, icon: Icons.apartment_rounded, onTap: onOrganizationTap),
          _SelectionChip(label: site, icon: Icons.location_city_rounded, onTap: onSiteTap),
          _SelectionChip(label: building, icon: Icons.business_rounded, onTap: onBuildingTap),
          _SelectionChip(label: floor, icon: Icons.layers_rounded, onTap: onFloorTap),
        ],
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E9F4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF2155D6)),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 128),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1D2435)),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFF7C869C)),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2155D6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF7B849A), fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF1D2435), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSegmentsCard extends StatelessWidget {
  const _RouteSegmentsCard({
    required this.result,
    required this.activeIndex,
    required this.onSegmentTap,
  });

  final MultiRouteResult result;
  final int activeIndex;
  final ValueChanged<int> onSegmentTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route_rounded, color: Color(0xFF2155D6)),
              const SizedBox(width: 8),
              const Text(
                'Katlar Arasi Rota',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                result.distanceLabel,
                style: const TextStyle(
                  color: Color(0xFF6F7992),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: result.segments.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final segment = result.segments[index];
                final isActive = index == activeIndex;

                return InkWell(
                  onTap: () => onSegmentTap(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF2155D6) : const Color(0xFFF5F7FC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive ? const Color(0xFF2155D6) : const Color(0xFFE2E8F3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${segment.buildingName} / ${segment.floorName}',
                          style: TextStyle(
                            color: isActive ? Colors.white : const Color(0xFF182033),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          segment.siteName,
                          style: TextStyle(
                            color: isActive
                                ? Colors.white.withValues(alpha: 0.86)
                                : const Color(0xFF6F7992),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FloorOption {
  const _FloorOption({
    required this.site,
    required this.building,
    required this.floor,
  });

  final SiteHierarchy site;
  final BuildingHierarchy building;
  final FloorHierarchy floor;
}
