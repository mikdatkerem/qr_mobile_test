import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';
import '../models/exceptions.dart';
import 'zone_service.dart' show hardcodedZones;

class LocationService {
  /// ✅ Mock mod açık → API isteği atılmaz, zone listesinden yanıt üretilir.
  /// 🔌 API hazır olunca false yap.
  static const bool _mockMode = true;

  static const String _baseUrl = 'https://api.site.com';
  final http.Client _client;

  LocationService({http.Client? client}) : _client = client ?? http.Client();

  Future<LocationModel> getLocation(String locationId) {
    return _mockMode
        ? _mockGetLocation(locationId)
        : _apiGetLocation(locationId);
  }

  // ─── MOCK ────────────────────────────────────────────────────────────────

  Future<LocationModel> _mockGetLocation(String locationId) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final zone = hardcodedZones.where((z) => z.id == locationId).firstOrNull;

    if (zone == null) throw LocationNotFoundException(locationId);

    return LocationModel(
      id: zone.id,
      name: zone.label,
      x: zone.centerX,
      y: zone.centerY,
    );
  }

  // ─── GERÇEK API ───────────────────────────────────────────────────────────

  Future<LocationModel> _apiGetLocation(String locationId) async {
    final uri = Uri.parse('$_baseUrl/location/$locationId');
    try {
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw const ApiException('Bağlantı zaman aşımına uğradı'),
      );

      if (response.statusCode == 404)
        throw LocationNotFoundException(locationId);
      if (response.statusCode != 200) {
        throw ApiException('Sunucu hatası', statusCode: response.statusCode);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return LocationModel.fromJson(json);
    } on LocationNotFoundException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Bağlantı hatası: $e');
    }
  }

  void dispose() => _client.close();
}
