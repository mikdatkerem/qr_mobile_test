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
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  List<ZoneModel> _zones = [];
  final List<String> _visitedOrder = [];
  Set<String> get _visitedIds => _visitedOrder.toSet();

  String? _activeZoneId;
  bool _isLoading = false;
  bool _zonesLoading = true;

  // Navigasyon
  MapNode? _targetPark;
  List<MapNode>? _navigationRoute;

  String? _lastScannedId;
  DateTime? _lastScannedTime;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _locationService.dispose();
    _zoneService.dispose();
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
      // Navigasyon aktifse rotayı güncelle
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

  void _updateRoute(String fromId) {
    if (_targetPark == null) return;
    final route = _pathfinder.findPath(fromId, _targetPark!.id);
    setState(() => _navigationRoute = route);
    if (route == null) {
      _showErrorSnackBar('Bu konumdan hedefe rota bulunamadı');
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ParkSelectorSheet(
        pathfinder: _pathfinder,
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
    });
  }

  void _showTestPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Text('Test: QR Simüle Et',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _zones.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final zone = _zones[i];
                final visited = _visitedIds.contains(zone.id);
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        visited ? Colors.green.shade100 : Colors.grey.shade100,
                    child: Text(
                      zone.id.replaceAll(RegExp(r'[^0-9]'), ''),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: visited
                              ? Colors.green.shade700
                              : Colors.grey.shade600),
                    ),
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
        ],
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
      backgroundColor: Theme.of(context).colorScheme.background,
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

                // Navigasyon durumu bandı
                if (_targetPark != null)
                  _NavBanner(
                    targetPark: _targetPark!,
                    routeLength: _navigationRoute?.length,
                    onClear: _clearNavigation,
                  ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FloorPlanWidget(
                            zones: _zones,
                            visitedIds: _visitedIds,
                            activeZoneId: _activeZoneId,
                            navigationRoute: _navigationRoute,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const _CreditBar(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showParkSelector,
        icon: const Icon(Icons.local_parking),
        label: const Text('Park Seç'),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }
}

// ─── Navigasyon durum bandı ──────────────────────────────────────────────────

class _NavBanner extends StatelessWidget {
  final MapNode targetPark;
  final int? routeLength;
  final VoidCallback onClear;
  const _NavBanner(
      {required this.targetPark, this.routeLength, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade600,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.navigation, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              routeLength != null
                  ? '${targetPark.label} · ${routeLength! - 1} adım'
                  : 'Rota hesaplanıyor...',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }
}

// ─── Alt kredi bandı ─────────────────────────────────────────────────────────

class _CreditBar extends StatelessWidget {
  const _CreditBar();
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _openLinkedIn,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text('Mikdat Kerem Kalkan',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: theme.colorScheme.primary)),
              ],
            ),
          ),
          Text('  ·  Mehmet Kalkan',
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
