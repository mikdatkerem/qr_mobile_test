import 'dart:convert';
import '../main.dart';
import 'package:http/http.dart' as http;
import '../models/zone_model.dart';
import '../models/exceptions.dart';

class ZoneService {
  // Android emülatör: 10.0.2.2 → bilgisayarının localhost'u
  // Fiziksel cihaz: bilgisayarının local IP'si (örn. 192.168.1.x)
  // iOS simülatör / web: localhost
  String get _baseUrl => AppConfig.apiBaseUrl;

  final http.Client _client;

  ZoneService({http.Client? client}) : _client = client ?? http.Client();

  /// GET /api/locations → tüm QR zone'larını döndürür
  Future<List<ZoneModel>> getZones() async {
    final uri = Uri.parse('$_baseUrl/locations');
    try {
      final response = await _client.get(uri, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ApiException('Zone listesi alınamadı',
            statusCode: response.statusCode);
      }

      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => ZoneModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Bağlantı hatası: $e');
    }
  }

  void dispose() => _client.close();
}
