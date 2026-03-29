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
      if (!mounted) {
        return;
      }

      setState(() {
        _organizations = organizations;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _loading = false);
      _showError(error);
    }
  }

  List<SiteHierarchy> get _availableSites => _hierarchy?.sites ?? const [];

  List<BuildingHierarchy> get _availableBuildings => _site?.buildings ?? const [];

  List<FloorHierarchy> get _availableFloors =>
      _building?.floors.where((item) => item.hasPublishedMap).toList() ?? const [];

  Future<void> _onOrganizationChanged(String? organizationId) async {
    if (organizationId == null) {
      return;
    }

    setState(() {
      _loading = true;
      _hierarchy = null;
      _site = null;
      _building = null;
      _floor = null;
      _map = null;
      _route = null;
      _multiRoute = null;
      _targetPark = null;
      _displayNodes = const [];
      _occupancy = {};
    });

    try {
      final hierarchy = await _facilityService.getOrganizationHierarchy(organizationId);
      if (!mounted) {
        return;
      }

      setState(() {
        _hierarchy = hierarchy;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _loading = false);
      _showError(error);
    }
  }

  void _onSiteChanged(String? siteId) {
    if (siteId == null || _hierarchy == null) {
      return;
    }

    final site = _hierarchy!.sites.where((item) => item.id == siteId).firstOrNull;
    if (site == null) {
      return;
    }

    setState(() {
      _site = site;
      _building = null;
      _floor = null;
      _map = null;
      _route = null;
      _multiRoute = null;
      _targetPark = null;
      _displayNodes = const [];
      _occupancy = {};
    });
  }

  void _onBuildingChanged(String? buildingId) {
    if (buildingId == null || _site == null) {
      return;
    }

    final building = _site!.buildings.where((item) => item.id == buildingId).firstOrNull;
    if (building == null) {
      return;
    }

    setState(() {
      _building = building;
      _floor = null;
      _map = null;
      _route = null;
      _multiRoute = null;
      _targetPark = null;
      _displayNodes = const [];
      _occupancy = {};
    });
  }

  Future<void> _onFloorChanged(String? floorId) async {
    if (floorId == null || _hierarchy == null || _site == null || _building == null) {
      return;
    }

    final floor = _building!.floors.where((item) => item.id == floorId).firstOrNull;
    if (floor == null) {
      return;
    }

    await _applySelection(
      hierarchy: _hierarchy!,
      site: _site!,
      building: _building!,
      floor: floor,
    );
  }

  void _clearSelectedMap() {
    setState(() {
      _site = null;
      _building = null;
      _floor = null;
      _map = null;
      _route = null;
      _multiRoute = null;
      _targetPark = null;
      _displayNodes = const [];
      _occupancy = {};
      _lastScan = null;
    });
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
      if (mounted) {
        _showError('Park durumu yuklenemedi: $error');
      }
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
    if (mounted) {
      setState(() => _loading = true);
    }

    final publishedMap = await _facilityService.getPublishedMap(floor.id);
    replaceGraph(
      nodes: publishedMap.nodes,
      edges: publishedMap.edges,
      mapAssetPath: publishedMap.assetPath,
      mapAssetContentType: publishedMap.assetContentType,
      mapWidth: publishedMap.width,
      mapHeight: publishedMap.height,
    );

    if (!mounted) {
      return;
    }

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
    if (!mounted) {
      return;
    }

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
    if (value == null || value.isEmpty) {
      return;
    }

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
    if (_busy) {
      return;
    }

    await HapticFeedback.mediumImpact();
    if (mounted) {
      setState(() => _busy = true);
    }

    try {
      final context = await _facilityService.resolveQrScanContext(referenceId);
      await _applyScanContext(context);
      if (!mounted) {
        return;
      }

      setState(() => _busy = false);
      if (_targetPark != null) {
        await _updateRoute(referenceId);
      } else {
        _showSuggestionDialog();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _busy = false);
      _showError(error);
    }
  }

  Future<void> openSelection(MapOpenRequest request) async {
    if (_busy) {
      return;
    }

    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final hierarchy = _hierarchy?.id == request.organizationId
          ? _hierarchy!
          : await _facilityService.getOrganizationHierarchy(request.organizationId);

      final site = request.siteId == null
          ? null
          : hierarchy.sites.where((item) => item.id == request.siteId).firstOrNull;
      final building = request.buildingId == null
          ? null
          : site?.buildings.where((item) => item.id == request.buildingId).firstOrNull;
      final floor = request.floorId == null
          ? null
          : building?.floors.where((item) => item.id == request.floorId).firstOrNull;

      if (site != null && building != null && floor != null) {
        await _applySelection(
          hierarchy: hierarchy,
          site: site,
          building: building,
          floor: floor,
        );
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _hierarchy = hierarchy;
        _site = site;
        _building = building;
        _floor = null;
        _map = null;
        _route = null;
        _multiRoute = null;
        _targetPark = null;
        _displayNodes = const [];
        _occupancy = {};
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _loading = false);
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
    if (_targetPark == null || _floor == null) {
      return;
    }

    try {
      final result = await _pathfinder.findFacilityRoute(
        floorId: _floor!.id,
        fromReferenceId: fromReferenceId,
        toReferenceId: _targetPark!.externalReferenceId ?? _targetPark!.id,
      );

      if (!mounted) {
        return;
      }

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

      if (!mounted) {
        return;
      }

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
    if (_lastScan == null) {
      return;
    }

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
    if (park == null) {
      return;
    }

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
    final hasMap = _map != null;
    final activeNodeId = _lastScan == null
        ? null
        : _displayNodes
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
                  onTap: hasMap ? _collapseSheet : null,
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
                                  _building?.name ?? 'Bina secin',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF182033),
                                  ),
                                ),
                              ),
                              if (hasMap)
                                IconButton(
                                  onPressed: _clearSelectedMap,
                                  icon: const Icon(Icons.layers_clear_rounded),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF182033),
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
                                child: hasMap
                                    ? FloorPlanWidget(
                                        visitedIds: const {},
                                        activeZoneId: activeNodeId,
                                        navigationRoute: _route,
                                        occupancyMap: _occupancy,
                                        nodes: _displayNodes,
                                        mapAssetPath: _map?.assetPath,
                                        mapAssetContentType: _map?.assetContentType,
                                        mapWidth: _map?.width,
                                        mapHeight: _map?.height,
                                      )
                                    : _MapSelectionPanel(
                                        organizations: _organizations,
                                        selectedOrganizationId: _hierarchy?.id,
                                        sites: _availableSites,
                                        selectedSiteId: _site?.id,
                                        buildings: _availableBuildings,
                                        selectedBuildingId: _building?.id,
                                        floors: _availableFloors,
                                        selectedFloorId: _floor?.id,
                                        onOrganizationChanged: _onOrganizationChanged,
                                        onSiteChanged: _onSiteChanged,
                                        onBuildingChanged: _onBuildingChanged,
                                        onFloorChanged: _onFloorChanged,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasMap)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * ParkBottomSheet.fullSize,
                      child: ParkBottomSheet(
                        controller: _sheetController,
                        occupancyMap: _occupancy,
                        targetPark: _targetPark,
                        parkedAt: _parkedAt,
                        mapName: _map?.name ?? 'Harita',
                        activeReference: _lastScan,
                        emptyCount: emptyCount,
                        fullCount: fullCount,
                        totalCount: _occupancy.length,
                        multiRoute: _multiRoute,
                        activeSegmentIndex: _activeRouteSegmentIndex,
                        onSegmentTap: (index) => unawaited(_showRouteSegment(index)),
                        onParkSelected: (park) {
                          _sheetController.animateTo(
                            ParkBottomSheet.peekSize,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                          setState(() {
                            _targetPark = park;
                            _route = null;
                            _multiRoute = null;
                          });
                          if (_lastScan != null) {
                            unawaited(_updateRoute(_lastScan!));
                          }
                        },
                        onNavigateToExit: () {
                          unawaited(_navigateToBestExit());
                        },
                        onNavigateToCar: () {
                          if (_parkedAt == null || _lastScan == null) {
                            return;
                          }
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
                          if (_lastScan == null) {
                            return;
                          }
                          final park = _pathfinder.nearestEmptyParkToUser(_lastScan!, _occupancy);
                          if (park == null) {
                            return;
                          }
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
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MapSelectionPanel extends StatelessWidget {
  const _MapSelectionPanel({
    required this.organizations,
    required this.selectedOrganizationId,
    required this.sites,
    required this.selectedSiteId,
    required this.buildings,
    required this.selectedBuildingId,
    required this.floors,
    required this.selectedFloorId,
    required this.onOrganizationChanged,
    required this.onSiteChanged,
    required this.onBuildingChanged,
    required this.onFloorChanged,
  });

  final List<OrganizationSummary> organizations;
  final String? selectedOrganizationId;
  final List<SiteHierarchy> sites;
  final String? selectedSiteId;
  final List<BuildingHierarchy> buildings;
  final String? selectedBuildingId;
  final List<FloorHierarchy> floors;
  final String? selectedFloorId;
  final ValueChanged<String?> onOrganizationChanged;
  final ValueChanged<String?> onSiteChanged;
  final ValueChanged<String?> onBuildingChanged;
  final ValueChanged<String?> onFloorChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFD),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE4EAF5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Harita secin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF182033),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'QR okutursaniz ilgili kat otomatik acilir. Elle secmek icin kurum, yerleske, bina ve kati belirleyin.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF6E7890),
                  ),
                ),
                const SizedBox(height: 18),
                _PickerField<OrganizationSummary>(
                  label: 'Kurum',
                  value: organizations.where((item) => item.id == selectedOrganizationId).firstOrNull,
                  items: organizations,
                  onChanged: (item) => onOrganizationChanged(item?.id),
                  title: (item) => item.name,
                ),
                const SizedBox(height: 12),
                _PickerField<SiteHierarchy>(
                  label: 'Yerleske',
                  value: sites.where((item) => item.id == selectedSiteId).firstOrNull,
                  items: sites,
                  onChanged: (item) => onSiteChanged(item?.id),
                  title: (item) => item.name,
                ),
                const SizedBox(height: 12),
                _PickerField<BuildingHierarchy>(
                  label: 'Bina',
                  value: buildings.where((item) => item.id == selectedBuildingId).firstOrNull,
                  items: buildings,
                  onChanged: (item) => onBuildingChanged(item?.id),
                  title: (item) => item.name,
                ),
                const SizedBox(height: 12),
                _PickerField<FloorHierarchy>(
                  label: 'Kat',
                  value: floors.where((item) => item.id == selectedFloorId).firstOrNull,
                  items: floors,
                  onChanged: (item) => onFloorChanged(item?.id),
                  title: (item) => item.name,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerField<T> extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.title,
  });

  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T item) title;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                title(item),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: items.isEmpty ? null : onChanged,
    );
  }
}
