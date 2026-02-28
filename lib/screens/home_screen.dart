import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/zone_model.dart';
import '../models/exceptions.dart';
import '../services/location_service.dart';
import '../services/zone_service.dart';
import '../widgets/floor_plan_widget.dart';
import '../widgets/embedded_scanner.dart';
import '../widgets/progress_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final ZoneService _zoneService = ZoneService();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  List<ZoneModel> _zones = [];
  final List<String> _visitedOrder = [];
  Set<String> get _visitedIds => _visitedOrder.toSet();

  String? _activeZoneId;
  bool _isLoading = false;
  bool _zonesLoading = true;

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
        now.difference(_lastScannedTime!) < const Duration(seconds: 3)) {
      return;
    }
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
        if (!_visitedIds.contains(locationId)) {
          _visitedOrder.add(locationId);
        }
        _activeZoneId = locationId;
        _isLoading = false;
      });
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

  /// Test: zone ID'lerini listeden seçerek simüle et
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
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Test: QR Simüle Et',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
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
                            : Colors.grey.shade600,
                      ),
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
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  String? get _activeZoneLabel => _activeZoneId == null
      ? null
      : _zones.where((z) => z.id == _activeZoneId).firstOrNull?.label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'Test QR',
            onPressed: _zones.isEmpty ? null : _showTestPicker,
          ),
        ],
      ),
      body: _zonesLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Kamera — tam genişlik bant
                EmbeddedScanner(
                  controller: _scannerController,
                  onDetect: _onQrDetected,
                  isLoading: _isLoading,
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
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FloorPlanWidget(
                            zones: _zones,
                            visitedIds: _visitedIds,
                            activeZoneId: _activeZoneId,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ProgressBar(
                  zones: _zones,
                  visitedIds: _visitedIds,
                  activeZoneLabel: _activeZoneLabel,
                ),
              ],
            ),
    );
  }
}
