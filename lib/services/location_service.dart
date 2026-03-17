import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/location_model.dart';
import '../models/exceptions.dart';

class LocationService {
  final Dio _dio;

  LocationService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// POST /api/scans → konumu döndürür
  Future<LocationModel> getLocation(String locationId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/scans',
        data: {'locationId': locationId},
      );
      return LocationModel.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404)
        throw LocationNotFoundException(locationId);
      if (e.response?.statusCode == 401)
        throw const ApiException('Kimlik doğrulama hatası');
      throw ApiException(e.message ?? 'Bağlantı hatası');
    }
  }

  void dispose() {}
}
