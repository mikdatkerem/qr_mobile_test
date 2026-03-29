import 'dart:math';

import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/exceptions.dart';
import '../models/graph_data.dart';

class PathfindingService {
  PathfindingService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<RouteResult?> findFacilityRoute({
    required String floorId,
    required String fromReferenceId,
    required String toReferenceId,
    bool accessibleOnly = false,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/navigation/facility-route',
        queryParameters: {
          'floorId': floorId,
          'fromReferenceId': fromReferenceId,
          'toReferenceId': toReferenceId,
          'accessibleOnly': accessibleOnly,
        },
      );
      return RouteResult.fromFacilityJson(response.data!);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      if (error.response?.statusCode == 401) {
        throw const ApiException('Kimlik dogrulama hatasi');
      }
      final detail = error.response?.data is Map<String, dynamic>
          ? (error.response!.data['detail']?.toString())
          : null;
      throw ApiException(detail ?? error.message ?? 'Rota hesaplanamadi');
    }
  }

  Future<MultiRouteResult?> findFacilityMultiRoute({
    required String fromReferenceId,
    required String toReferenceId,
    bool accessibleOnly = false,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/navigation/facility-multi-route',
        queryParameters: {
          'fromReferenceId': fromReferenceId,
          'toReferenceId': toReferenceId,
          'accessibleOnly': accessibleOnly,
        },
      );
      return MultiRouteResult.fromJson(response.data!);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      if (error.response?.statusCode == 401) {
        throw const ApiException('Kimlik dogrulama hatasi');
      }
      final detail = error.response?.data is Map<String, dynamic>
          ? (error.response!.data['detail']?.toString())
          : null;
      throw ApiException(detail ?? error.message ?? 'Cok katli rota hesaplanamadi');
    }
  }

  Future<MultiRouteResult?> findBestExitRoute({
    required String fromReferenceId,
    bool accessibleOnly = false,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/navigation/facility-best-exit-route',
        queryParameters: {
          'fromReferenceId': fromReferenceId,
          'accessibleOnly': accessibleOnly,
        },
      );
      return MultiRouteResult.fromJson(response.data!);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      final detail = error.response?.data is Map<String, dynamic>
          ? (error.response!.data['detail']?.toString())
          : null;
      throw ApiException(detail ?? error.message ?? 'Cikis rotasi hesaplanamadi');
    }
  }

  Future<RecommendedRouteResult?> findRecommendedParkingNearEntrance({
    required String fromReferenceId,
    bool accessibleOnly = false,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/navigation/facility-recommended-parking-near-entrance',
        queryParameters: {
          'fromReferenceId': fromReferenceId,
          'accessibleOnly': accessibleOnly,
        },
      );
      return RecommendedRouteResult.fromJson(response.data!);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      final detail = error.response?.data is Map<String, dynamic>
          ? (error.response!.data['detail']?.toString())
          : null;
      throw ApiException(detail ?? error.message ?? 'Giris yakin park onerisi alinamadi');
    }
  }

  MapNode? nearestEmptyParkToUser(
    String fromNodeId,
    Map<String, bool> occupancyMap,
    Iterable<MapNode> nodes,
  ) {
    final sourceNodes = nodes.toList();
    final from = sourceNodes.where((node) => node.id == fromNodeId).firstOrNull;
    if (from == null) {
      return null;
    }
    return _nearestEmptyPark(from, occupancyMap, sourceNodes);
  }

  MapNode? _nearestEmptyPark(
    MapNode from,
    Map<String, bool> occupancyMap,
    Iterable<MapNode> nodes,
  ) {
    final emptyParks = nodes
        .where((node) => node.isPark && occupancyMap[node.id] == false)
        .toList();
    if (emptyParks.isEmpty) {
      return null;
    }

    emptyParks.sort(
      (left, right) => _euclidean(from, left).compareTo(_euclidean(from, right)),
    );

    return emptyParks.first;
  }

  double _euclidean(MapNode a, MapNode b) =>
      sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));

  Map<String, List<MapNode>> getParkGroups(Iterable<MapNode> nodes) {
    final parks = nodes.where((node) => node.isPark).toList()
      ..sort((left, right) {
        final leftNum = int.tryParse(left.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final rightNum = int.tryParse(right.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return leftNum.compareTo(rightNum);
      });

    return {'A': parks};
  }

  void dispose() {}
}

class RouteResult {
  const RouteResult({
    required this.nodes,
    required this.distanceMeters,
    required this.distanceLabel,
    this.mapAssetPath,
    this.mapWidth,
    this.mapHeight,
  });

  final List<MapNode> nodes;
  final double distanceMeters;
  final String distanceLabel;
  final String? mapAssetPath;
  final int? mapWidth;
  final int? mapHeight;

  factory RouteResult.fromFacilityJson(Map<String, dynamic> json) {
    final nodeList = (json['nodes'] as List<dynamic>)
        .map((item) => MapNode.fromFacilityJson(item as Map<String, dynamic>))
        .toList();

    return RouteResult(
      nodes: nodeList,
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      distanceLabel: json['distanceLabel'] as String,
      mapAssetPath: json['mapAssetPath'] as String?,
      mapWidth: json['mapWidth'] as int?,
      mapHeight: json['mapHeight'] as int?,
    );
  }
}

class MultiRouteSegment {
  const MultiRouteSegment({
    required this.mapVersionId,
    required this.floorId,
    required this.floorName,
    required this.buildingId,
    required this.buildingName,
    required this.siteId,
    required this.siteName,
    required this.mapName,
    required this.mapAssetPath,
    required this.mapAssetContentType,
    required this.mapWidth,
    required this.mapHeight,
    required this.nodes,
  });

  final String mapVersionId;
  final String floorId;
  final String floorName;
  final String buildingId;
  final String buildingName;
  final String siteId;
  final String siteName;
  final String mapName;
  final String mapAssetPath;
  final String mapAssetContentType;
  final int mapWidth;
  final int mapHeight;
  final List<MapNode> nodes;

  factory MultiRouteSegment.fromJson(Map<String, dynamic> json) {
    return MultiRouteSegment(
      mapVersionId: json['mapVersionId'] as String,
      floorId: json['floorId'] as String,
      floorName: json['floorName'] as String,
      buildingId: json['buildingId'] as String,
      buildingName: json['buildingName'] as String,
      siteId: json['siteId'] as String,
      siteName: json['siteName'] as String,
      mapName: json['mapName'] as String,
      mapAssetPath: json['mapAssetPath'] as String,
      mapAssetContentType: json['mapAssetContentType'] as String,
      mapWidth: json['mapWidth'] as int,
      mapHeight: json['mapHeight'] as int,
      nodes: (json['nodes'] as List<dynamic>)
          .map((item) => MapNode.fromFacilityJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MultiRouteResult {
  const MultiRouteResult({
    required this.segments,
    required this.distanceMeters,
    required this.distanceLabel,
  });

  final List<MultiRouteSegment> segments;
  final double distanceMeters;
  final String distanceLabel;

  factory MultiRouteResult.fromJson(Map<String, dynamic> json) {
    return MultiRouteResult(
      segments: (json['segments'] as List<dynamic>)
          .map((item) => MultiRouteSegment.fromJson(item as Map<String, dynamic>))
          .toList(),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      distanceLabel: json['distanceLabel'] as String,
    );
  }
}

class RecommendedRouteTarget {
  const RecommendedRouteTarget({
    required this.code,
    required this.label,
    required this.externalReferenceId,
  });

  final String code;
  final String label;
  final String? externalReferenceId;

  factory RecommendedRouteTarget.fromJson(Map<String, dynamic> json) {
    return RecommendedRouteTarget(
      code: json['code'] as String,
      label: json['label'] as String,
      externalReferenceId: json['externalReferenceId'] as String?,
    );
  }
}

class RecommendedRouteResult {
  const RecommendedRouteResult({
    required this.target,
    required this.segments,
    required this.distanceMeters,
    required this.distanceLabel,
  });

  final RecommendedRouteTarget target;
  final List<MultiRouteSegment> segments;
  final double distanceMeters;
  final String distanceLabel;

  factory RecommendedRouteResult.fromJson(Map<String, dynamic> json) {
    return RecommendedRouteResult(
      target: RecommendedRouteTarget.fromJson(json['target'] as Map<String, dynamic>),
      segments: (json['segments'] as List<dynamic>)
          .map((item) => MultiRouteSegment.fromJson(item as Map<String, dynamic>))
          .toList(),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      distanceLabel: json['distanceLabel'] as String,
    );
  }
}
