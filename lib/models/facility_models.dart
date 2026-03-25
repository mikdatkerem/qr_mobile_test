import 'graph_data.dart';

class OrganizationSummary {
  const OrganizationSummary({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  factory OrganizationSummary.fromJson(Map<String, dynamic> json) {
    return OrganizationSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

class OrganizationHierarchy {
  const OrganizationHierarchy({
    required this.id,
    required this.name,
    required this.sites,
  });

  final String id;
  final String name;
  final List<SiteHierarchy> sites;

  factory OrganizationHierarchy.fromJson(Map<String, dynamic> json) {
    return OrganizationHierarchy(
      id: json['id'] as String,
      name: json['name'] as String,
      sites: ((json['sites'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => SiteHierarchy.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SiteHierarchy {
  const SiteHierarchy({
    required this.id,
    required this.code,
    required this.name,
    required this.buildings,
  });

  final String id;
  final String code;
  final String name;
  final List<BuildingHierarchy> buildings;

  factory SiteHierarchy.fromJson(Map<String, dynamic> json) {
    return SiteHierarchy(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      buildings: ((json['buildings'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => BuildingHierarchy.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BuildingHierarchy {
  const BuildingHierarchy({
    required this.id,
    required this.code,
    required this.name,
    required this.floors,
  });

  final String id;
  final String code;
  final String name;
  final List<FloorHierarchy> floors;

  factory BuildingHierarchy.fromJson(Map<String, dynamic> json) {
    return BuildingHierarchy(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      floors: ((json['floors'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => FloorHierarchy.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FloorHierarchy {
  const FloorHierarchy({
    required this.id,
    required this.code,
    required this.name,
    required this.level,
    required this.mapVersions,
  });

  final String id;
  final String code;
  final String name;
  final int level;
  final List<MapVersionSummary> mapVersions;

  factory FloorHierarchy.fromJson(Map<String, dynamic> json) {
    return FloorHierarchy(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      level: json['level'] as int,
      mapVersions: ((json['mapVersions'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => MapVersionSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasPublishedMap =>
      mapVersions.any((version) => version.status.toLowerCase() == 'published');
}

class MapVersionSummary {
  const MapVersionSummary({
    required this.id,
    required this.name,
    required this.status,
  });

  final String id;
  final String name;
  final String status;

  factory MapVersionSummary.fromJson(Map<String, dynamic> json) {
    return MapVersionSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'].toString(),
    );
  }
}

class PublishedMapData {
  const PublishedMapData({
    required this.id,
    required this.floorId,
    required this.name,
    required this.assetPath,
    required this.assetContentType,
    required this.width,
    required this.height,
    required this.nodes,
    required this.edges,
  });

  final String id;
  final String floorId;
  final String name;
  final String assetPath;
  final String assetContentType;
  final int width;
  final int height;
  final List<MapNode> nodes;
  final List<MapEdge> edges;

  factory PublishedMapData.fromJson(Map<String, dynamic> json) {
    final nodes = ((json['nodes'] as List<dynamic>?) ?? const <dynamic>[])
        .map((item) => MapNode.fromFacilityJson(item as Map<String, dynamic>))
        .toList();

    final nodeCodesById = <String, String>{
      for (final item in (json['nodes'] as List<dynamic>? ?? const <dynamic>[]))
        (item as Map<String, dynamic>)['id'] as String:
            ((item['code'] as String?) ?? (item['id'] as String)).toUpperCase(),
    };

    final edges = ((json['connections'] as List<dynamic>?) ?? const <dynamic>[])
        .expand((item) {
      final map = item as Map<String, dynamic>;
      final fromCode = nodeCodesById[map['fromNodeId'] as String];
      final toCode = nodeCodesById[map['toNodeId'] as String];
      if (fromCode == null || toCode == null) {
        return const <MapEdge>[];
      }

      final isBidirectional = map['isBidirectional'] as bool? ?? false;
      return [
        MapEdge(from: fromCode, to: toCode),
        if (isBidirectional) MapEdge(from: toCode, to: fromCode),
      ];
    }).toList();

    return PublishedMapData(
      id: json['id'] as String,
      floorId: json['floorId'] as String,
      name: json['name'] as String,
      assetPath: json['assetPath'] as String,
      assetContentType: json['assetContentType'] as String? ?? 'image/svg+xml',
      width: json['width'] as int,
      height: json['height'] as int,
      nodes: nodes,
      edges: edges,
    );
  }
}

class QrScanContext {
  const QrScanContext({
    required this.referenceId,
    required this.organizationId,
    required this.organizationName,
    required this.siteId,
    required this.siteName,
    required this.buildingId,
    required this.buildingName,
    required this.floorId,
    required this.floorName,
    required this.mapVersionId,
    required this.mapName,
    required this.nodeCode,
    required this.nodeLabel,
  });

  final String referenceId;
  final String organizationId;
  final String organizationName;
  final String siteId;
  final String siteName;
  final String buildingId;
  final String buildingName;
  final String floorId;
  final String floorName;
  final String mapVersionId;
  final String mapName;
  final String nodeCode;
  final String nodeLabel;

  factory QrScanContext.fromJson(Map<String, dynamic> json) {
    return QrScanContext(
      referenceId: json['referenceId'] as String,
      organizationId: json['organizationId'] as String,
      organizationName: json['organizationName'] as String,
      siteId: json['siteId'] as String,
      siteName: json['siteName'] as String,
      buildingId: json['buildingId'] as String,
      buildingName: json['buildingName'] as String,
      floorId: json['floorId'] as String,
      floorName: json['floorName'] as String,
      mapVersionId: json['mapVersionId'] as String,
      mapName: json['mapName'] as String,
      nodeCode: json['nodeCode'] as String,
      nodeLabel: json['nodeLabel'] as String,
    );
  }
}
