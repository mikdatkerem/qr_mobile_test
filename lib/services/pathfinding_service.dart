import 'dart:math';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/graph_data.dart';
import '../models/exceptions.dart';

// Hastane kapısı — P16 sabit
const String kHospitalNodeId = 'P16';

class PathfindingService {
  final Dio _dio;

  PathfindingService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// GET /api/navigation/route?from=P5&to=A12
  Future<RouteResult?> findPathFromApi(String fromId, String toId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/navigation/route',
        queryParameters: {'from': fromId, 'to': toId},
      );
      return RouteResult.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      if (e.response?.statusCode == 401)
        throw const ApiException('Kimlik doğrulama hatası');
      throw ApiException(e.message ?? 'Rota hesaplanamadı');
    }
  }

  // ── Park önerisi algoritmaları ─────────────────────────────────────────────

  /// Kullanıcının bulunduğu node'a Öklid mesafesi en yakın boş park
  MapNode? nearestEmptyParkToUser(
      String fromNodeId, Map<String, bool> occupancyMap) {
    final from = allNodes.where((n) => n.id == fromNodeId).firstOrNull;
    if (from == null) return null;
    return _nearestEmptyPark(from, occupancyMap);
  }

  /// P16 (hastane girişi) node'una Öklid mesafesi en yakın boş park
  MapNode? nearestEmptyParkToHospital(Map<String, bool> occupancyMap) {
    final hospital = allNodes.where((n) => n.id == kHospitalNodeId).firstOrNull;
    if (hospital == null) return null;
    return _nearestEmptyPark(hospital, occupancyMap);
  }

  /// Verilen referans node'a en yakın boş park — Öklid mesafesi
  MapNode? _nearestEmptyPark(MapNode from, Map<String, bool> occupancyMap) {
    final emptyParks =
        allNodes.where((n) => n.isPark && occupancyMap[n.id] == false).toList();
    if (emptyParks.isEmpty) return null;

    emptyParks
        .sort((a, b) => _euclidean(from, a).compareTo(_euclidean(from, b)));

    return emptyParks.first;
  }

  double _euclidean(MapNode a, MapNode b) =>
      sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));

  Map<String, List<MapNode>> getParkGroups() {
    final parks = allNodes.where((n) => n.isPark).toList()
      ..sort((a, b) {
        final na = int.tryParse(a.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final nb = int.tryParse(b.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return na.compareTo(nb);
      });
    return {'A': parks};
  }

  void dispose() {}
}

/// API'den dönen rota sonucu
class RouteResult {
  final List<MapNode> nodes;
  final double distanceMeters;
  final String distanceLabel;

  const RouteResult({
    required this.nodes,
    required this.distanceMeters,
    required this.distanceLabel,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    final nodeList = (json['nodes'] as List<dynamic>)
        .map((e) => MapNode.fromJson(e as Map<String, dynamic>))
        .toList();
    return RouteResult(
      nodes: nodeList,
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      distanceLabel: json['distanceLabel'] as String,
    );
  }
}
