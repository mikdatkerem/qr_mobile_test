import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/zone_model.dart';
import '../models/graph_data.dart';
import '../models/exceptions.dart';
import '../services/location_service.dart';
import '../services/zone_service.dart';
import '../services/pathfinding_service.dart';
import '../services/parking_service.dart';
import '../widgets/floor_plan_widget.dart';
import '../widgets/embedded_scanner.dart';
import '../widgets/park_selector_sheet.dart';
import '../widgets/park_suggestion_dialog.dart';
import '../widgets/app_notification.dart';
import '../widgets/app_drawer.dart';
import '../widgets/park_confirm_dialog.dart';
import '../widgets/nav_banner.dart';
import '../widgets/bottom_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final ZoneService _zoneService = ZoneService();
  final PathfindingService _pathfinder = PathfindingService();
  late final ParkingService _parkingService;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  List<ZoneModel> _zones = [];
  final List<String> _visitedOrder = [];
  Set<String> get _visitedIds => _visitedOrder.toSet();

  String? _activeZoneId;
  bool _isLoading = false;
  bool _zonesLoading = true;
  MapNode? _targetPark;
  List<MapNode>? _navigationRoute;
  String? _distanceLabel;
  Map<String, bool> _occupancyMap = {};
  MapNode? _parkedAt;
  AppNotificationBar? _notification;

  String? _lastScannedId;
  DateTime? _lastScannedTime;

  MapNode? get _suggestedPark {
    if (_targetPark != null) return null;
    final emptyParks = allNodes
        .where((n) => n.isPark && _occupancyMap[n.id] == false)
        .toList();
    if (emptyParks.isEmpty) return null;
    if (_activeZoneId != null) {
      final active = allNodes.where((n) => n.id == _activeZoneId).firstOrNull;
      if (active != null) {
        emptyParks.sort((a, b) {
          double d(MapNode n) =>
              (n.x - active.x) * (n.x - active.x) +
              (n.y - active.y) * (n.y - active.y);
          return d(a).compareTo(d(b));
        });
      }
    }
    return emptyParks.first;
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _parkingService = ParkingService(onOccupancyChanged: _onOccupancyChanged);
    _loadZones();
    _loadOccupancy();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _locationService.dispose();
    _zoneService.dispose();
    _parkingService.dispose();
    super.dispose();
  }

  // ── Veri yükleme ─────────────────────────────────────────────────────────

  Future<void> _loadZones() async {
    try {
      final zones = await _zoneService.getZones();
      if (!mounted) return;
      setState(() {
        _zones = zones;
        _zonesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _zonesLoading = false);
      _showErrorSnackBar('Zone listesi yüklenemedi');
    }
  }

  Future<void> _loadOccupancy() async {
    for (int i = 0; i < 3; i++) {
      try {
        final map = await _parkingService.getOccupancyMap();
        if (mounted) setState(() => _occupancyMap = map);
        break;
      } catch (e) {
        if (i < 2)
          await Future.delayed(const Duration(seconds: 2));
        else if (mounted) _showErrorSnackBar('Park durumu yüklenemedi: $e');
      }
    }
    try {
      await _parkingService.startListening();
    } catch (e) {
      if (mounted) _showErrorSnackBar('SignalR bağlantısı kurulamadı: $e');
    }
  }

  // ── SignalR callback ──────────────────────────────────────────────────────

  void _onOccupancyChanged(String spotId, bool isOccupied) {
    if (!mounted) return;
    final wasEmpty = _occupancyMap[spotId] == false;
    setState(() => _occupancyMap[spotId] = isOccupied);

    // Hedef park boş→dolu geçişi yaptıysa park onayı sor
    if (isOccupied && wasEmpty && _targetPark?.id == spotId) {
      _showParkConfirmDialog(spotId);
    }
  }

  // ── QR tarama ────────────────────────────────────────────────────────────

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    final now = DateTime.now();
    if (raw == _lastScannedId &&
        _lastScannedTime != null &&
        now.difference(_lastScannedTime!) < const Duration(seconds: 3)) return;
    _lastScannedId = raw;
    _lastScannedTime = now;
    await _handleScannedId(raw);
  }

  Future<void> _handleScannedId(String locationId) async {
    if (_isLoading) return;
    await HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      await _locationService.getLocation(locationId);
      if (!mounted) return;
      setState(() {
        if (!_visitedIds.contains(locationId)) _visitedOrder.add(locationId);
        _activeZoneId = locationId;
        _isLoading = false;
      });
      if (_targetPark != null) {
        _updateRoute(locationId);
      } else if (locationId == 'START') {
        // START QR → park seçim dialog'u
        _showParkSuggestionDialog();
      } else {
        final suggested = _suggestedPark;
        if (suggested != null) {
          _showNotification(
            message: 'En yakın boş alan: ${suggested.id}',
            style: NotificationStyle.info,
            actionLabel: 'Rotala',
            onAction: () {
              setState(() {
                _targetPark = suggested;
                _navigationRoute = null;
              });
              _updateRoute(locationId);
            },
          );
        }
      }
    } on LocationNotFoundException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Bilinmeyen konum: ${e.locationId}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Beklenmeyen bir hata oluştu');
    }
  }

  // ── Navigasyon ────────────────────────────────────────────────────────────

  Future<void> _updateRoute(String fromId) async {
    if (_targetPark == null) return;
    try {
      final result = await _pathfinder.findPathFromApi(fromId, _targetPark!.id);
      if (!mounted) return;
      setState(() {
        _navigationRoute = result?.nodes;
        _distanceLabel = result?.distanceLabel;
      });
      if (result == null) {
        _showErrorSnackBar('Bu konumdan hedefe rota bulunamadı');
      } else {
        _showNotification(
          message: '${_targetPark!.id} için rota oluşturuldu',
          style: NotificationStyle.success,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Rota hesaplanamadı: $e');
    }
  }

  void _clearNavigation() {
    setState(() {
      _targetPark = null;
      _navigationRoute = null;
      _distanceLabel = null;
    });
  }

  void _navigateToExit() {
    Navigator.pop(context);
    final exit = allNodes.where((n) => n.id == 'END').firstOrNull;
    if (exit == null) return;
    setState(() {
      _targetPark = exit;
      _navigationRoute = null;
      _distanceLabel = null;
    });
    if (_activeZoneId != null) _updateRoute(_activeZoneId!);
  }

  void _navigateToCar() {
    if (_parkedAt == null) return;
    Navigator.pop(context);
    setState(() {
      _targetPark = _parkedAt;
      _navigationRoute = null;
      _distanceLabel = null;
    });
    if (_activeZoneId != null) _updateRoute(_activeZoneId!);
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showParkConfirmDialog(String spotId) {
    final park = allNodes.where((n) => n.id == spotId).firstOrNull;
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
            _navigationRoute = null;
            _distanceLabel = null;
          });
          _showNotification(
            message: 'Araç ${park.id} alanına kaydedildi',
            style: NotificationStyle.success,
            duration: const Duration(seconds: 5),
          );
        },
        onDeny: () => Navigator.pop(context),
      ),
    );
  }

  void _showParkSuggestionDialog() {
    if (_activeZoneId == null) return;
    final nearestToUser =
        _pathfinder.nearestEmptyParkToUser(_activeZoneId!, _occupancyMap);
    final nearestToHospital =
        _pathfinder.nearestEmptyParkToHospital(_occupancyMap);

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => ParkSuggestionDialog(
        nearestToUser: nearestToUser,
        nearestToHospital: nearestToHospital,
        onSelected: (park) {
          setState(() {
            _targetPark = park;
            _navigationRoute = null;
          });
          _updateRoute(_activeZoneId!);
        },
      ),
    );
  }

  void _navigateNearestToUser() {
    if (_activeZoneId == null) {
      _showErrorSnackBar('Önce bir QR kodu okutun');
      return;
    }
    final park =
        _pathfinder.nearestEmptyParkToUser(_activeZoneId!, _occupancyMap);
    if (park == null) {
      _showErrorSnackBar('Boş park alanı bulunamadı');
      return;
    }
    setState(() {
      _targetPark = park;
      _navigationRoute = null;
    });
    _updateRoute(_activeZoneId!);
  }

  void _navigateNearestToHospital() {
    if (_activeZoneId == null) {
      _showErrorSnackBar('Önce bir QR kodu okutun');
      return;
    }
    final park = _pathfinder.nearestEmptyParkToHospital(_occupancyMap);
    if (park == null) {
      _showErrorSnackBar('Boş park alanı bulunamadı');
      return;
    }
    setState(() {
      _targetPark = park;
      _navigationRoute = null;
    });
    _updateRoute(_activeZoneId!);
  }

  void _showParkSelector() {
    if (_activeZoneId == null) {
      _showErrorSnackBar('Önce bir QR kodu okutun');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParkSelectorSheet(
        pathfinder: _pathfinder,
        occupancyMap: _occupancyMap,
        onParkSelected: (park) {
          setState(() {
            _targetPark = park;
            _navigationRoute = null;
          });
          _updateRoute(_activeZoneId!);
        },
      ),
    );
  }

  void _showTestPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text('Test: QR Simüle Et',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _zones.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final zone = _zones[i];
                  final visited = _visitedIds.contains(zone.id);
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: visited
                          ? Colors.green.shade100
                          : Colors.grey.shade100,
                      child: Text(zone.id.replaceAll(RegExp(r'[^0-9]'), ''),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: visited
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600)),
                    ),
                    title: Text(zone.label),
                    subtitle: Text(zone.id),
                    trailing: visited
                        ? Icon(Icons.check_circle,
                            color: Colors.green.shade500, size: 18)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleScannedId(zone.id);
                    },
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  void _showNotification({
    required String message,
    NotificationStyle style = NotificationStyle.info,
    String? actionLabel,
    VoidCallback? onAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    Duration duration = const Duration(seconds: 6),
  }) {
    setState(() {
      _notification = AppNotificationBar(
        key: UniqueKey(),
        message: message,
        style: style,
        actionLabel: actionLabel,
        onAction: onAction,
        secondaryActionLabel: secondaryActionLabel,
        onSecondaryAction: onSecondaryAction,
        duration: duration,
        onDismiss: () => setState(() => _notification = null),
      );
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 237, 218, 155),
      drawer: AppDrawer(
        occupancyMap: _occupancyMap,
        suggestedPark: _suggestedPark,
        activeZoneId: _activeZoneId,
        targetPark: _targetPark,
        parkedAt: _parkedAt,
        onParkSelected: (park) {
          setState(() {
            _targetPark = park;
            _navigationRoute = null;
          });
          if (_activeZoneId != null) _updateRoute(_activeZoneId!);
          Navigator.pop(context);
        },
        onNavigateToExit: _navigateToExit,
        onNavigateToCar: _navigateToCar,
        onClearNav: _clearNavigation,
        onNearestToUser: _navigateNearestToUser,
        onNearestToHospital: _navigateNearestToHospital,
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/mustang.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey.shade800)),
            Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              child: Center(
                  child: Builder(
                      builder: (ctx) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                          ))),
            ),
            Positioned(
              right: 4,
              top: 0,
              bottom: 0,
              child: Center(
                  child: IconButton(
                icon: const Icon(Icons.qr_code, color: Colors.white),
                tooltip: 'Test QR',
                onPressed: _zones.isEmpty ? null : _showTestPicker,
              )),
            ),
          ],
        ),
      ),
      body: _zonesLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                EmbeddedScanner(
                  controller: _scannerController,
                  onDetect: _onQrDetected,
                  isLoading: _isLoading,
                ),
                if (_targetPark != null)
                  NavBanner(
                    targetPark: _targetPark!,
                    distanceLabel: _distanceLabel,
                    onClear: _clearNavigation,
                    onTap: _showParkSelector,
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(children: [
                            FloorPlanWidget(
                              zones: _zones,
                              visitedIds: _visitedIds,
                              activeZoneId: _activeZoneId,
                              navigationRoute: _navigationRoute,
                              occupancyMap: _occupancyMap,
                            ),
                            if (_notification != null)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 8,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _notification,
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
                const SafeArea(top: false, child: BottomBar()),
              ],
            ),
    );
  }
}
