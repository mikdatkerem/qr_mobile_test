import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // Park doluluk durumu — tüm uygulama genelinde tek kaynak
  Map<String, bool> _occupancyMap = {};

  String? _lastScannedId;
  DateTime? _lastScannedTime;

  // En yakın boş park (henüz park seçilmemişse önerilir)
  MapNode? get _suggestedPark {
    if (_targetPark != null) return null;
    // Boş olan park node'larından ilkini öner
    final emptyParks = allNodes
        .where((n) => n.isPark && _occupancyMap[n.id] == false)
        .toList();
    if (emptyParks.isEmpty) return null;
    return emptyParks.first;
  }

  @override
  void initState() {
    super.initState();
    _parkingService = ParkingService(onOccupancyChanged: _onOccupancyChanged);
    _loadZones();
    _loadOccupancy();
  }

  Future<void> _loadOccupancy() async {
    bool loaded = false;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final map = await _parkingService.getOccupancyMap();
        if (mounted) setState(() => _occupancyMap = map);
        loaded = true;
        break;
      } catch (e) {
        if (attempt < 2) {
          await Future.delayed(const Duration(seconds: 2));
        } else if (mounted) {
          _showErrorSnackBar('Park durumu yüklenemedi: $e');
        }
      }
    }
    if (loaded) await _parkingService.startListening();
  }

  // SignalR'dan gelen anlık güncelleme
  void _onOccupancyChanged(String spotId, bool isOccupied) {
    if (!mounted) return;
    setState(() => _occupancyMap[spotId] = isOccupied);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _locationService.dispose();
    _zoneService.dispose();
    _parkingService.dispose();
    super.dispose();
  }

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

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    final rawValue = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) return;
    final now = DateTime.now();
    if (rawValue == _lastScannedId &&
        _lastScannedTime != null &&
        now.difference(_lastScannedTime!) < const Duration(seconds: 3)) return;
    _lastScannedId = rawValue;
    _lastScannedTime = now;
    await _handleScannedId(rawValue);
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
      if (_targetPark != null) _updateRoute(locationId);
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

  Future<void> _updateRoute(String fromId) async {
    if (_targetPark == null) return;
    try {
      final result = await _pathfinder.findPathFromApi(fromId, _targetPark!.id);
      if (!mounted) return;
      setState(() {
        _navigationRoute = result?.nodes;
        _distanceLabel = result?.distanceLabel;
      });
      if (result == null)
        _showErrorSnackBar('Bu konumdan hedefe rota bulunamadı');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Rota hesaplanamadı: $e');
    }
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

  void _clearNavigation() {
    setState(() {
      _targetPark = null;
      _navigationRoute = null;
      _distanceLabel = null;
    });
  }

  /// Çıkışa yönlendir (END node'unu hedef al)
  void _navigateToExit() {
    Navigator.pop(context); // drawer'ı kapat
    final exitNode = allNodes.where((n) => n.id == 'END').firstOrNull;
    if (exitNode == null) return;
    setState(() {
      _targetPark = exitNode;
      _navigationRoute = null;
      _distanceLabel = null;
    });
    if (_activeZoneId != null) _updateRoute(_activeZoneId!);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 237, 218, 155),
      drawer: _AppDrawer(
        occupancyMap: _occupancyMap,
        suggestedPark: _suggestedPark,
        activeZoneId: _activeZoneId,
        targetPark: _targetPark,
        onParkSelected: (park) {
          setState(() {
            _targetPark = park;
            _navigationRoute = null;
          });
          if (_activeZoneId != null) _updateRoute(_activeZoneId!);
          Navigator.pop(context);
        },
        onNavigateToExit: _navigateToExit,
        onClearNav: _clearNavigation,
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
            // Drawer butonu (sol)
            Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: Builder(
                    builder: (ctx) => IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                        )),
              ),
            ),
            // Test butonu (sağ)
            Positioned(
              right: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.qr_code, color: Colors.white),
                  tooltip: 'Test QR',
                  onPressed: _zones.isEmpty ? null : _showTestPicker,
                ),
              ),
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
                  _NavBanner(
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
                          child: FloorPlanWidget(
                            zones: _zones,
                            visitedIds: _visitedIds,
                            activeZoneId: _activeZoneId,
                            navigationRoute: _navigationRoute,
                            occupancyMap: _occupancyMap,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: _BottomBar(
                    onParkTap: _showParkSelector,
                    targetPark: _targetPark,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── App Drawer ───────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final Map<String, bool> occupancyMap;
  final MapNode? suggestedPark;
  final String? activeZoneId;
  final MapNode? targetPark;
  final void Function(MapNode) onParkSelected;
  final VoidCallback onNavigateToExit;
  final VoidCallback onClearNav;

  const _AppDrawer({
    required this.occupancyMap,
    required this.suggestedPark,
    required this.activeZoneId,
    required this.targetPark,
    required this.onParkSelected,
    required this.onNavigateToExit,
    required this.onClearNav,
  });

  @override
  Widget build(BuildContext context) {
    final total = allNodes.where((n) => n.isPark).length;
    final empty = occupancyMap.values.where((v) => !v).length;
    final full = occupancyMap.values.where((v) => v).length;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Başlık ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              color: Colors.blue.shade700,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.local_parking,
                      color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  const Text('Park Durumu',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$empty boş · $full dolu · $total toplam',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── En yakın boş park önerisi ─────────────────────────────────
            if (suggestedPark != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Material(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onParkSelected(suggestedPark!),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.shade500,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.stars_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Önerilen Park',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600)),
                                Text(suggestedPark!.id,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.green.shade400),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (suggestedPark != null) const SizedBox(height: 8),

            // ── Çıkışa git butonu ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Material(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onNavigateToExit,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade500,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.exit_to_app,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Çıkışa Git',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600)),
                              Text('Çıkış noktasına yol çiz',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 14, color: Colors.orange.shade400),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(indent: 12, endIndent: 12),
            const SizedBox(height: 8),

            // ── Park listesi ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Tüm Park Yerleri',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5)),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.3,
                ),
                itemCount: allNodes.where((n) => n.isPark).length,
                itemBuilder: (_, i) {
                  final park = allNodes.where((n) => n.isPark).toList()[i];
                  final isOccupied = occupancyMap[park.id];
                  final isTarget = targetPark?.id == park.id;
                  final num = park.id.replaceAll(RegExp(r'[^0-9]'), '');

                  Color bg, border, text;
                  if (isTarget) {
                    bg = Colors.blue.shade600;
                    border = Colors.blue.shade700;
                    text = Colors.white;
                  } else if (isOccupied == null) {
                    bg = Colors.grey.shade100;
                    border = Colors.grey.shade300;
                    text = Colors.grey.shade500;
                  } else if (isOccupied) {
                    bg = Colors.red.shade50;
                    border = Colors.red.shade200;
                    text = Colors.red.shade700;
                  } else {
                    bg = Colors.green.shade50;
                    border = Colors.green.shade300;
                    text = Colors.green.shade700;
                  }

                  return GestureDetector(
                    onTap: isOccupied == true
                        ? null
                        : () {
                            onParkSelected(park);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border, width: 1),
                      ),
                      child: Center(
                        child: Text(num,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: text)),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Alt bant ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final VoidCallback onParkTap;
  final MapNode? targetPark;
  const _BottomBar({required this.onParkTap, this.targetPark});

  static const _linkedInUrl = 'https://linkedin.com/in/mikdatkeremkalkan';
  Future<void> _openLinkedIn() async {
    final uri = Uri.parse(_linkedInUrl);
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _openLinkedIn,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link, size: 13, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('Mikdat Kerem Kalkan',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: theme.colorScheme.primary)),
                  Text('  ·  Mehmet Kalkan',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onParkTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_parking,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(targetPark != null ? targetPark!.label : 'Park Seç',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Navigasyon durum bandı ───────────────────────────────────────────────────

class _NavBanner extends StatelessWidget {
  final MapNode targetPark;
  final String? distanceLabel;
  final VoidCallback onClear;
  final VoidCallback onTap;
  const _NavBanner(
      {required this.targetPark,
      this.distanceLabel,
      required this.onClear,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.blue.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            const Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                distanceLabel != null
                    ? '${targetPark.label}  ·  $distanceLabel'
                    : 'Rota hesaplanıyor...',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.close, color: Colors.white70, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
