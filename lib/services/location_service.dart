import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';
import '../models/exceptions.dart';

class LocationService {
  static const String _baseUrl = 'https://api.site.com';
  final http.Client _client;

  LocationService({http.Client? client}) : _client = client ?? http.Client();

  Future<LocationModel> getLocation(String locationId) async {
    final uri = Uri.parse('$_baseUrl/location/$locationId');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw const ApiException('Bağlantı zaman aşımına uğradı'),
      );

      if (response.statusCode == 404) {
        throw LocationNotFoundException(locationId);
      }

      if (response.statusCode != 200) {
        throw ApiException(
          'Sunucu hatası',
          statusCode: response.statusCode,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return LocationModel.fromJson(json);
    } on LocationNotFoundException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Bağlantı hatası: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}
