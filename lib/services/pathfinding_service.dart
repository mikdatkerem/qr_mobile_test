import 'dart:convert';
import '../main.dart';
import 'package:http/http.dart' as http;
import '../models/graph_data.dart';
import '../models/exceptions.dart';

class PathfindingService {
  String get _baseUrl => AppConfig.apiBaseUrl;

  final http.Client _client;

  PathfindingService({http.Client? client}) : _client = client ?? http.Client();

  /// GET /api/navigation/route?from=P5&to=A12
  /// → RouteDto: { nodes, distanceMeters, distanceLabel }
  Future<RouteResult?> findPathFromApi(String fromId, String toId) async {
    final uri = Uri.parse('$_baseUrl/navigation/route')
        .replace(queryParameters: {'from': fromId, 'to': toId});
    try {
      final response = await _client.get(uri, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw ApiException('Rota alınamadı', statusCode: response.statusCode);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return RouteResult.fromJson(json);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Bağlantı hatası: $e');
    }
  }

  // Park grup listesi için (ParkSelectorSheet kullanır)
  Map<String, List<MapNode>> getParkGroups() {
    final parks = allNodes.where((n) => n.isPark).toList();
    parks.sort((a, b) {
      final na = int.tryParse(a.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final nb = int.tryParse(b.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return na.compareTo(nb);
    });
    return {'A': parks};
  }

  void dispose() => _client.close();
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
