import 'dart:math';
import '../models/graph_data.dart';

class _Edge {
  final String to;
  final double weight;
  const _Edge(this.to, this.weight);
}

class PathfindingService {
  // QR-only graph (park node'ları arası geçiş yok)
  late final Map<String, List<_Edge>> _qrAdj;
  // Park → en yakın QR node'u eşlemesi
  late final Map<String, String> _parkToNearestQr;

  final Map<String, MapNode> _nodeMap;

  PathfindingService() : _nodeMap = {for (final n in allNodes) n.id: n} {
    _qrAdj = {};
    _parkToNearestQr = {};

    // Sadece QR node'larını graph'a ekle
    for (final node in allNodes.where((n) => n.isQr)) {
      _qrAdj[node.id] = [];
    }

    // Sadece QR↔QR edge'lerini ekle (park geçişleri yok)
    for (final edge in allEdges) {
      final a = _nodeMap[edge.from]!;
      final b = _nodeMap[edge.to]!;
      if (a.isQr && b.isQr) {
        final w = _dist(a, b);
        _qrAdj[edge.from]!.add(_Edge(edge.to, w));
        _qrAdj[edge.to]!.add(_Edge(edge.from, w));
      }
    }

    // Her park node'u için en yakın QR'ı bul (edge listesinden)
    final parkEdges = <String, List<String>>{};
    for (final edge in allEdges) {
      final a = _nodeMap[edge.from]!;
      final b = _nodeMap[edge.to]!;
      if (a.isPark && b.isQr) {
        parkEdges.putIfAbsent(a.id, () => []).add(b.id);
      }
      if (b.isPark && a.isQr) {
        parkEdges.putIfAbsent(b.id, () => []).add(a.id);
      }
    }

    for (final parkId in parkEdges.keys) {
      final park = _nodeMap[parkId]!;
      final connectedQrs = parkEdges[parkId]!;
      // Bağlı QR'lar arasından en yakınını seç
      connectedQrs.sort((a, b) =>
          _dist(park, _nodeMap[a]!).compareTo(_dist(park, _nodeMap[b]!)));
      _parkToNearestQr[parkId] = connectedQrs.first;
    }
  }

  double _dist(MapNode a, MapNode b) =>
      sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));

  /// fromId (QR) → toId (Park) arası yol:
  /// 1. fromQR → nearestQR(park) dijkstra ile yol üzerinden
  /// 2. Son adımda nearestQR → park node'u eklenir
  List<MapNode>? findPath(String fromId, String toId) {
    final from = _nodeMap[fromId];
    final to = _nodeMap[toId];
    if (from == null || to == null) return null;
    if (fromId == toId) return [from];

    // Hedef park'ın giriş QR'ını bul
    final entryQrId = to.isPark ? _parkToNearestQr[toId] : toId;
    if (entryQrId == null) return null;

    // QR graph'ında Dijkstra
    final qrPath = _dijkstra(fromId, entryQrId);
    if (qrPath == null) return null;

    // Park hedefse son adıma park node'unu ekle
    if (to.isPark) {
      return [...qrPath, to];
    }
    return qrPath;
  }

  List<MapNode>? _dijkstra(String fromId, String toId) {
    if (fromId == toId) return [_nodeMap[fromId]!];

    final dist = <String, double>{};
    final prev = <String, String>{};
    final unvisited = <String>{};

    for (final id in _qrAdj.keys) {
      dist[id] = double.infinity;
      unvisited.add(id);
    }
    dist[fromId] = 0.0;

    while (unvisited.isNotEmpty) {
      final u = unvisited.reduce((a, b) =>
          (dist[a] ?? double.infinity) < (dist[b] ?? double.infinity) ? a : b);

      if ((dist[u] ?? double.infinity) == double.infinity) break;
      if (u == toId) break;

      unvisited.remove(u);

      for (final edge in (_qrAdj[u] ?? [])) {
        if (!unvisited.contains(edge.to)) continue;
        final alt = dist[u]! + edge.weight;
        if (alt < (dist[edge.to] ?? double.infinity)) {
          dist[edge.to] = alt;
          prev[edge.to] = u;
        }
      }
    }

    if (!prev.containsKey(toId) && fromId != toId) return null;

    final path = <String>[];
    String? cur = toId;
    while (cur != null) {
      path.add(cur);
      cur = prev[cur];
    }
    return path.reversed.map((id) => _nodeMap[id]!).toList();
  }

  List<MapNode> getNodesByType(NodeType type) =>
      allNodes.where((n) => n.type == type).toList();

  Map<String, List<MapNode>> getParkGroups() {
    // Tüm parkları tek liste olarak döndür (A1-A50 sıralı)
    final parks = allNodes.where((n) => n.isPark).toList();
    parks.sort((a, b) {
      final na = int.tryParse(a.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final nb = int.tryParse(b.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return na.compareTo(nb);
    });
    return {'A': parks};
  }
}
