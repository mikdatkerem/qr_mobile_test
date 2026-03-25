import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/exceptions.dart';
import '../models/facility_models.dart';

class FacilityService {
  FacilityService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<List<OrganizationSummary>> getOrganizations() async {
    try {
      final response = await _dio.get<List<dynamic>>('/client/facilities/organizations');
      return response.data!
          .map((item) => OrganizationSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException(_extractMessage(error, 'Organizasyonlar yuklenemedi.'));
    }
  }

  Future<OrganizationHierarchy> getOrganizationHierarchy(String organizationId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/client/facilities/organizations/$organizationId',
      );
      return OrganizationHierarchy.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException(_extractMessage(error, 'Organizasyon detayi yuklenemedi.'));
    }
  }

  Future<PublishedMapData> getPublishedMap(String floorId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/client/facilities/floors/$floorId/published-map',
      );
      return PublishedMapData.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException(_extractMessage(error, 'Yayinlanmis harita yuklenemedi.'));
    }
  }

  Future<QrScanContext> resolveQrScanContext(String referenceId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/client/facilities/scan-context/$referenceId',
      );
      return QrScanContext.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException(_extractMessage(error, 'QR baglami cozulemedi.'));
    }
  }

  String _extractMessage(DioException error, String fallback) {
    final body = error.response?.data;
    final detail = body is Map<String, dynamic> ? body['detail']?.toString() : null;
    return detail ?? error.message ?? fallback;
  }
}
