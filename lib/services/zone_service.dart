import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/zone_model.dart';
import '../models/exceptions.dart';

class ZoneService {
  final Dio _dio;

  ZoneService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// GET /api/locations → tüm QR zone'larını döndürür
  Future<List<ZoneModel>> getZones() async {
    try {
      final response = await _dio.get<List<dynamic>>('/locations');
      return response.data!
          .map((e) => ZoneModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401)
        throw const ApiException('Kimlik doğrulama hatası');
      throw ApiException(e.message ?? 'Bağlantı hatası');
    }
  }

  void dispose() {}
}
