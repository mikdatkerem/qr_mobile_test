import 'dart:convert';
import '../main.dart';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';
import '../models/exceptions.dart';

class LocationService {
  String get _baseUrl => AppConfig.apiBaseUrl;

  final http.Client _client;

  LocationService({http.Client? client}) : _client = client ?? http.Client();

  /// Flutter QR okutunca → POST /api/scans → konumu döndürür
  Future<LocationModel> getLocation(String locationId) async {
    final uri = Uri.parse('$_baseUrl/scans');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json'
            },
            body: jsonEncode({'locationId': locationId}),
          )
          .timeout(
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
