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
import '../widgets/park_bottom_sheet.dart';
import '../widgets/park_confirm_dialog.dart';
import '../widgets/park_suggestion_dialog.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

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
      });

      await _showRouteSegment(0);
    } catch (error) {
      _showError('Giris yakin park onerisi alinamadi: $error');
    }
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

  void _collapseSheet() {
    if (!_sheetController.isAttached) {
      return;
    }

    _sheetController.animateTo(
      ParkBottomSheet.peekSize,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
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
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _collapseSheet,
                  child: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 16, 0),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: widget.onBack,
                                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF182033),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${_site?.name ?? 'Yerleşke'} / ${_building?.name ?? 'Bina'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF182033),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                          child: EmbeddedScanner(
                            controller: _scannerController,
                            onDetect: _onQrDetected,
                            isLoading: _busy,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                              child: FloorPlanWidget(
                                visitedIds: const {},
                                activeZoneId: activeNodeId,
                                navigationRoute: _route,
                                  occupancyMap: _occupancy,
                                  nodes: _displayNodes,
                                  mapAssetPath: _map?.assetPath,
                                  mapAssetContentType: _map?.assetContentType,
                                  mapWidth: _map?.width,
                                  mapHeight: _map?.height,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ParkBottomSheet(
                  controller: _sheetController,
                  occupancyMap: _occupancy,
                  targetPark: _targetPark,
                  parkedAt: _parkedAt,
                  organizationLabel: _hierarchy?.name ?? 'Organizasyon',
                  siteLabel: _site?.name ?? 'Yerleşke',
                  buildingLabel: _building?.name ?? 'Bina',
                  floorLabel: _floor?.name ?? 'Kat',
                  mapName: _map?.name ?? 'Harita',
                  activeReference: _lastScan,
                  emptyCount: emptyCount,
                  fullCount: fullCount,
                  totalCount: _occupancy.length,
                  multiRoute: _multiRoute,
                  activeSegmentIndex: _activeRouteSegmentIndex,
                  onSegmentTap: (index) => unawaited(_showRouteSegment(index)),
                  onOrganizationTap: _showOrganizationPicker,
                  onSiteTap: _showSitePicker,
                  onBuildingTap: _showBuildingPicker,
                  onFloorTap: _showFloorPicker,
                  onParkSelected: (park) {
                    _sheetController.animateTo(ParkBottomSheet.peekSize,
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
