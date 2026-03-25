enum NodeType { qr, park, entrance, exit, other }

class MapNode {
  const MapNode({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.type,
    this.externalReferenceId,
  });

  final String id;
  final String label;
  final double x;
  final double y;
  final NodeType type;
  final String? externalReferenceId;

  factory MapNode.fromLegacyJson(Map<String, dynamic> json) {
    final nodeTypeInt = json['nodeType'] as int? ?? 1;
    final type = switch (nodeTypeInt) {
      2 => NodeType.park,
      _ => NodeType.qr,
    };

    final id = (json['id'] as String).toUpperCase();
    return MapNode(
      id: id,
      label: json['label'] as String? ?? id,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      type: type,
      externalReferenceId: id,
    );
  }

  factory MapNode.fromFacilityJson(Map<String, dynamic> json) {
    final nodeTypeInt = json['nodeType'] as int? ?? 1;
    final type = switch (nodeTypeInt) {
      2 => NodeType.qr,
      3 => NodeType.entrance,
      4 => NodeType.exit,
      8 => NodeType.park,
      _ => NodeType.other,
    };

    final code = (json['code'] as String?) ?? (json['id']?.toString() ?? '');
    return MapNode(
      id: code.toUpperCase(),
      label: (json['label'] as String?) ?? code,
      x: (json['pixelX'] as num).toDouble(),
      y: (json['pixelY'] as num).toDouble(),
      type: type,
      externalReferenceId: json['externalReferenceId'] as String?,
    );
  }

  bool get isPark => type == NodeType.park;
  bool get isQr => type == NodeType.qr;
}

class MapEdge {
  const MapEdge({required this.from, required this.to});

  final String from;
  final String to;
}

String? currentMapAssetPath;
String? currentMapAssetContentType;
int currentMapWidth = 800;
int currentMapHeight = 1000;

final List<MapNode> allNodes = List<MapNode>.from(_sampleNodes);
final List<MapEdge> allEdges = List<MapEdge>.from(_sampleEdges);

void replaceGraph({
  required Iterable<MapNode> nodes,
  required Iterable<MapEdge> edges,
  String? mapAssetPath,
  String? mapAssetContentType,
  int? mapWidth,
  int? mapHeight,
}) {
  allNodes
    ..clear()
    ..addAll(nodes);

  allEdges
    ..clear()
    ..addAll(edges);

  currentMapAssetPath = mapAssetPath;
  currentMapAssetContentType = mapAssetContentType;
  currentMapWidth = mapWidth ?? currentMapWidth;
  currentMapHeight = mapHeight ?? currentMapHeight;
}

MapNode? nearestQrForPark(String parkId) {
  final edge = allEdges.where((item) => item.from == parkId).firstOrNull;
  if (edge == null) {
    return null;
  }
  return allNodes.where((node) => node.id == edge.to && node.isQr).firstOrNull;
}

const List<MapNode> _sampleNodes = [
  MapNode(id: 'START', label: 'Baslangic', x: 600, y: 950, type: NodeType.qr, externalReferenceId: 'START'),
  MapNode(id: 'P1', label: 'Ic Konum 1', x: 600, y: 900, type: NodeType.qr, externalReferenceId: 'P1'),
  MapNode(id: 'P2', label: 'Ic Konum 2', x: 600, y: 820, type: NodeType.qr, externalReferenceId: 'P2'),
  MapNode(id: 'P3', label: 'Ic Konum 3', x: 600, y: 750, type: NodeType.qr, externalReferenceId: 'P3'),
  MapNode(id: 'P4', label: 'Ic Konum 4', x: 600, y: 690, type: NodeType.qr, externalReferenceId: 'P4'),
  MapNode(id: 'P5', label: 'Ic Konum 5', x: 600, y: 630, type: NodeType.qr, externalReferenceId: 'P5'),
  MapNode(id: 'P6', label: 'Ic Konum 6', x: 600, y: 570, type: NodeType.qr, externalReferenceId: 'P6'),
  MapNode(id: 'P7', label: 'Ic Konum 7', x: 600, y: 490, type: NodeType.qr, externalReferenceId: 'P7'),
  MapNode(id: 'P8', label: 'Ic Konum 8', x: 600, y: 430, type: NodeType.qr, externalReferenceId: 'P8'),
  MapNode(id: 'P9', label: 'Ic Konum 9', x: 600, y: 360, type: NodeType.qr, externalReferenceId: 'P9'),
  MapNode(id: 'P10', label: 'Ic Konum 10', x: 600, y: 300, type: NodeType.qr, externalReferenceId: 'P10'),
  MapNode(id: 'P11', label: 'Ic Konum 11', x: 600, y: 230, type: NodeType.qr, externalReferenceId: 'P11'),
  MapNode(id: 'P12', label: 'Ic Konum 12', x: 600, y: 160, type: NodeType.qr, externalReferenceId: 'P12'),
  MapNode(id: 'P13', label: 'Ic Konum 13', x: 600, y: 100, type: NodeType.qr, externalReferenceId: 'P13'),
  MapNode(id: 'P14', label: 'Ic Konum 14', x: 495, y: 80, type: NodeType.qr, externalReferenceId: 'P14'),
  MapNode(id: 'P15', label: 'Ic Konum 15', x: 435, y: 80, type: NodeType.qr, externalReferenceId: 'P15'),
  MapNode(id: 'P16', label: 'Ic Konum 16', x: 395, y: 80, type: NodeType.qr, externalReferenceId: 'P16'),
  MapNode(id: 'P17', label: 'Ic Konum 17', x: 345, y: 80, type: NodeType.qr, externalReferenceId: 'P17'),
  MapNode(id: 'P18', label: 'Ic Konum 18', x: 226, y: 100, type: NodeType.qr, externalReferenceId: 'P18'),
  MapNode(id: 'P19', label: 'Ic Konum 19', x: 226, y: 160, type: NodeType.qr, externalReferenceId: 'P19'),
  MapNode(id: 'P20', label: 'Ic Konum 20', x: 226, y: 230, type: NodeType.qr, externalReferenceId: 'P20'),
  MapNode(id: 'P21', label: 'Ic Konum 21', x: 226, y: 300, type: NodeType.qr, externalReferenceId: 'P21'),
  MapNode(id: 'P22', label: 'Ic Konum 22', x: 226, y: 360, type: NodeType.qr, externalReferenceId: 'P22'),
  MapNode(id: 'P23', label: 'Ic Konum 23', x: 226, y: 430, type: NodeType.qr, externalReferenceId: 'P23'),
  MapNode(id: 'P24', label: 'Ic Konum 24', x: 226, y: 490, type: NodeType.qr, externalReferenceId: 'P24'),
  MapNode(id: 'P25', label: 'Ic Konum 25', x: 226, y: 570, type: NodeType.qr, externalReferenceId: 'P25'),
  MapNode(id: 'P26', label: 'Ic Konum 26', x: 226, y: 630, type: NodeType.qr, externalReferenceId: 'P26'),
  MapNode(id: 'P27', label: 'Ic Konum 27', x: 226, y: 690, type: NodeType.qr, externalReferenceId: 'P27'),
  MapNode(id: 'P28', label: 'Ic Konum 28', x: 226, y: 750, type: NodeType.qr, externalReferenceId: 'P28'),
  MapNode(id: 'P29', label: 'Ic Konum 29', x: 226, y: 820, type: NodeType.qr, externalReferenceId: 'P29'),
  MapNode(id: 'P30', label: 'Ic Konum 30', x: 226, y: 900, type: NodeType.qr, externalReferenceId: 'P30'),
  MapNode(id: 'END', label: 'Bitis', x: 226, y: 950, type: NodeType.exit, externalReferenceId: 'END'),
  MapNode(id: 'A1', label: 'Park 1', x: 700, y: 900, type: NodeType.park, externalReferenceId: 'A1'),
  MapNode(id: 'A2', label: 'Park 2', x: 700, y: 820, type: NodeType.park, externalReferenceId: 'A2'),
  MapNode(id: 'A3', label: 'Park 3', x: 700, y: 750, type: NodeType.park, externalReferenceId: 'A3'),
  MapNode(id: 'A4', label: 'Park 4', x: 700, y: 690, type: NodeType.park, externalReferenceId: 'A4'),
  MapNode(id: 'A5', label: 'Park 5', x: 700, y: 630, type: NodeType.park, externalReferenceId: 'A5'),
  MapNode(id: 'A6', label: 'Park 6', x: 700, y: 570, type: NodeType.park, externalReferenceId: 'A6'),
  MapNode(id: 'A7', label: 'Park 7', x: 700, y: 490, type: NodeType.park, externalReferenceId: 'A7'),
  MapNode(id: 'A8', label: 'Park 8', x: 700, y: 430, type: NodeType.park, externalReferenceId: 'A8'),
  MapNode(id: 'A9', label: 'Park 9', x: 700, y: 360, type: NodeType.park, externalReferenceId: 'A9'),
  MapNode(id: 'A10', label: 'Park 10', x: 700, y: 300, type: NodeType.park, externalReferenceId: 'A10'),
  MapNode(id: 'A11', label: 'Park 11', x: 700, y: 230, type: NodeType.park, externalReferenceId: 'A11'),
  MapNode(id: 'A12', label: 'Park 12', x: 700, y: 160, type: NodeType.park, externalReferenceId: 'A12'),
  MapNode(id: 'A13', label: 'Park 13', x: 700, y: 100, type: NodeType.park, externalReferenceId: 'A13'),
];

const List<MapEdge> _sampleEdges = [
  MapEdge(from: 'START', to: 'P1'),
  MapEdge(from: 'P1', to: 'P2'),
  MapEdge(from: 'P2', to: 'P3'),
  MapEdge(from: 'P3', to: 'P4'),
  MapEdge(from: 'P4', to: 'P5'),
  MapEdge(from: 'P5', to: 'P6'),
  MapEdge(from: 'P6', to: 'P7'),
  MapEdge(from: 'P7', to: 'P8'),
  MapEdge(from: 'P8', to: 'P9'),
  MapEdge(from: 'P9', to: 'P10'),
  MapEdge(from: 'P10', to: 'P11'),
  MapEdge(from: 'P11', to: 'P12'),
  MapEdge(from: 'P12', to: 'P13'),
  MapEdge(from: 'A1', to: 'P1'),
  MapEdge(from: 'A2', to: 'P2'),
  MapEdge(from: 'A3', to: 'P3'),
  MapEdge(from: 'A4', to: 'P4'),
  MapEdge(from: 'A5', to: 'P5'),
  MapEdge(from: 'A6', to: 'P6'),
  MapEdge(from: 'A7', to: 'P7'),
  MapEdge(from: 'A8', to: 'P8'),
  MapEdge(from: 'A9', to: 'P9'),
  MapEdge(from: 'A10', to: 'P10'),
  MapEdge(from: 'A11', to: 'P11'),
  MapEdge(from: 'A12', to: 'P12'),
  MapEdge(from: 'A13', to: 'P13'),
];
