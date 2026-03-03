enum NodeType { qr, park }

class MapNode {
  final String id, label;
  final double x, y;
  final NodeType type;
  const MapNode(
      {required this.id,
      required this.label,
      required this.x,
      required this.y,
      required this.type});
  bool get isPark => type == NodeType.park;
  bool get isQr => type == NodeType.qr;
}

class MapEdge {
  final String from, to;
  const MapEdge({required this.from, required this.to});
}

const List<MapNode> allNodes = [
  // ── QR Node'ları (31 adet: START + P1-P29 + END) ──
  MapNode(
      id: "START", label: "Başlangıç", x: 600.0, y: 950.0, type: NodeType.qr),
  MapNode(id: "P1", label: "İç Konum 1", x: 600.0, y: 900.0, type: NodeType.qr),
  MapNode(id: "P2", label: "İç Konum 2", x: 600.0, y: 820.0, type: NodeType.qr),
  MapNode(id: "P3", label: "İç Konum 3", x: 600.0, y: 750.0, type: NodeType.qr),
  MapNode(id: "P4", label: "İç Konum 4", x: 600.0, y: 690.0, type: NodeType.qr),
  MapNode(id: "P5", label: "İç Konum 5", x: 600.0, y: 630.0, type: NodeType.qr),
  MapNode(id: "P6", label: "İç Konum 6", x: 600.0, y: 570.0, type: NodeType.qr),
  MapNode(id: "P7", label: "İç Konum 7", x: 600.0, y: 490.0, type: NodeType.qr),
  MapNode(id: "P8", label: "İç Konum 8", x: 600.0, y: 430.0, type: NodeType.qr),
  MapNode(id: "P9", label: "İç Konum 9", x: 600.0, y: 360.0, type: NodeType.qr),
  MapNode(
      id: "P10", label: "İç Konum 10", x: 600.0, y: 300.0, type: NodeType.qr),
  MapNode(
      id: "P11", label: "İç Konum 11", x: 600.0, y: 240.0, type: NodeType.qr),
  MapNode(
      id: "P12", label: "İç Konum 12", x: 600.0, y: 150.0, type: NodeType.qr),
  MapNode(
      id: "P13", label: "İç Konum 13", x: 600.0, y: 100.0, type: NodeType.qr),
  MapNode(
      id: "P14", label: "İç Konum 14", x: 495.0, y: 80.0, type: NodeType.qr),
  MapNode(
      id: "P15", label: "İç Konum 15", x: 435.0, y: 80.0, type: NodeType.qr),
  MapNode(
      id: "P16", label: "İç Konum 16", x: 395.0, y: 80.0, type: NodeType.qr),
  MapNode(
      id: "P17", label: "İç Konum 17", x: 345.0, y: 80.0, type: NodeType.qr),
  MapNode(
      id: "P18", label: "İç Konum 18", x: 226.0, y: 100.0, type: NodeType.qr),
  MapNode(
      id: "P19", label: "İç Konum 19", x: 226.0, y: 160.0, type: NodeType.qr),
  MapNode(
      id: "P20", label: "İç Konum 20", x: 226.0, y: 220.0, type: NodeType.qr),
  MapNode(
      id: "P21", label: "İç Konum 21", x: 226.0, y: 280.0, type: NodeType.qr),
  MapNode(
      id: "P22", label: "İç Konum 22", x: 226.0, y: 340.0, type: NodeType.qr),
  MapNode(
      id: "P23", label: "İç Konum 23", x: 226.0, y: 400.0, type: NodeType.qr),
  MapNode(
      id: "P24", label: "İç Konum 24", x: 226.0, y: 460.0, type: NodeType.qr),
  MapNode(
      id: "P25", label: "İç Konum 25", x: 226.0, y: 520.0, type: NodeType.qr),
  MapNode(
      id: "P26", label: "İç Konum 26", x: 226.0, y: 580.0, type: NodeType.qr),
  MapNode(
      id: "P27", label: "İç Konum 27", x: 226.0, y: 700.0, type: NodeType.qr),
  MapNode(
      id: "P28", label: "İç Konum 28", x: 226.0, y: 820.0, type: NodeType.qr),
  MapNode(
      id: "P29",
      label: "İç Konum 29",
      x: 226.0,
      y: 900.0,
      type: NodeType.qr), // P1 simetriği
  MapNode(id: "END", label: "Bitiş", x: 226.0, y: 980.0, type: NodeType.qr),
  // ── Park Node'ları (50 adet: A1-A50) ──
  MapNode(id: "A1", label: "Park 1", x: 700.0, y: 900.0, type: NodeType.park),
  MapNode(id: "A2", label: "Park 2", x: 700.0, y: 820.0, type: NodeType.park),
  MapNode(id: "A3", label: "Park 3", x: 700.0, y: 750.0, type: NodeType.park),
  MapNode(id: "A4", label: "Park 4", x: 700.0, y: 690.0, type: NodeType.park),
  MapNode(id: "A5", label: "Park 5", x: 700.0, y: 630.0, type: NodeType.park),
  MapNode(id: "A6", label: "Park 6", x: 700.0, y: 570.0, type: NodeType.park),
  MapNode(id: "A7", label: "Park 7", x: 700.0, y: 490.0, type: NodeType.park),
  MapNode(id: "A8", label: "Park 8", x: 700.0, y: 430.0, type: NodeType.park),
  MapNode(id: "A9", label: "Park 9", x: 700.0, y: 360.0, type: NodeType.park),
  MapNode(id: "A10", label: "Park 10", x: 700.0, y: 300.0, type: NodeType.park),
  MapNode(id: "A11", label: "Park 11", x: 700.0, y: 240.0, type: NodeType.park),
  MapNode(id: "A12", label: "Park 12", x: 700.0, y: 150.0, type: NodeType.park),
  MapNode(id: "A13", label: "Park 13", x: 700.0, y: 100.0, type: NodeType.park),
  MapNode(id: "A14", label: "Park 14", x: 450.0, y: 150.0, type: NodeType.park),
  MapNode(id: "A15", label: "Park 15", x: 450.0, y: 220.0, type: NodeType.park),
  MapNode(id: "A16", label: "Park 16", x: 450.0, y: 290.0, type: NodeType.park),
  MapNode(id: "A17", label: "Park 17", x: 450.0, y: 360.0, type: NodeType.park),
  MapNode(id: "A18", label: "Park 18", x: 450.0, y: 430.0, type: NodeType.park),
  MapNode(id: "A19", label: "Park 19", x: 450.0, y: 500.0, type: NodeType.park),
  MapNode(id: "A20", label: "Park 20", x: 450.0, y: 570.0, type: NodeType.park),
  MapNode(id: "A21", label: "Park 21", x: 450.0, y: 640.0, type: NodeType.park),
  MapNode(id: "A22", label: "Park 22", x: 450.0, y: 710.0, type: NodeType.park),
  MapNode(id: "A23", label: "Park 23", x: 450.0, y: 780.0, type: NodeType.park),
  MapNode(id: "A24", label: "Park 24", x: 450.0, y: 860.0, type: NodeType.park),
  MapNode(id: "A25", label: "Park 25", x: 450.0, y: 940.0, type: NodeType.park),
  MapNode(id: "A26", label: "Park 26", x: 130.0, y: 100.0, type: NodeType.park),
  MapNode(id: "A27", label: "Park 27", x: 130.0, y: 150.0, type: NodeType.park),
  MapNode(id: "A28", label: "Park 28", x: 130.0, y: 220.0, type: NodeType.park),
  MapNode(id: "A29", label: "Park 29", x: 130.0, y: 290.0, type: NodeType.park),
  MapNode(id: "A30", label: "Park 30", x: 130.0, y: 360.0, type: NodeType.park),
  MapNode(id: "A31", label: "Park 31", x: 130.0, y: 430.0, type: NodeType.park),
  MapNode(id: "A32", label: "Park 32", x: 130.0, y: 500.0, type: NodeType.park),
  MapNode(id: "A33", label: "Park 33", x: 130.0, y: 570.0, type: NodeType.park),
  MapNode(id: "A34", label: "Park 34", x: 130.0, y: 640.0, type: NodeType.park),
  MapNode(id: "A35", label: "Park 35", x: 130.0, y: 710.0, type: NodeType.park),
  MapNode(id: "A36", label: "Park 36", x: 130.0, y: 780.0, type: NodeType.park),
  MapNode(id: "A37", label: "Park 37", x: 130.0, y: 860.0, type: NodeType.park),
  MapNode(id: "A38", label: "Park 38", x: 130.0, y: 900.0, type: NodeType.park),
  MapNode(id: "A39", label: "Park 39", x: 340.0, y: 150.0, type: NodeType.park),
  MapNode(id: "A40", label: "Park 40", x: 340.0, y: 220.0, type: NodeType.park),
  MapNode(id: "A41", label: "Park 41", x: 340.0, y: 290.0, type: NodeType.park),
  MapNode(id: "A42", label: "Park 42", x: 340.0, y: 360.0, type: NodeType.park),
  MapNode(id: "A43", label: "Park 43", x: 340.0, y: 430.0, type: NodeType.park),
  MapNode(id: "A44", label: "Park 44", x: 340.0, y: 500.0, type: NodeType.park),
  MapNode(id: "A45", label: "Park 45", x: 340.0, y: 570.0, type: NodeType.park),
  MapNode(id: "A46", label: "Park 46", x: 340.0, y: 630.0, type: NodeType.park),
  MapNode(id: "A47", label: "Park 47", x: 340.0, y: 690.0, type: NodeType.park),
  MapNode(id: "A48", label: "Park 48", x: 340.0, y: 750.0, type: NodeType.park),
  MapNode(id: "A49", label: "Park 49", x: 340.0, y: 820.0, type: NodeType.park),
  MapNode(id: "A50", label: "Park 50", x: 340.0, y: 900.0, type: NodeType.park),
];

const List<MapEdge> allEdges = [
  // QR zinciri — START sadece P1'e, END sadece P29'a bağlı
  MapEdge(from: "START", to: "P1"),
  MapEdge(from: "P1", to: "P2"),
  MapEdge(from: "P2", to: "P3"),
  MapEdge(from: "P3", to: "P4"),
  MapEdge(from: "P4", to: "P5"),
  MapEdge(from: "P5", to: "P6"),
  MapEdge(from: "P6", to: "P7"),
  MapEdge(from: "P7", to: "P8"),
  MapEdge(from: "P8", to: "P9"),
  MapEdge(from: "P9", to: "P10"),
  MapEdge(from: "P10", to: "P11"),
  MapEdge(from: "P11", to: "P12"),
  MapEdge(from: "P12", to: "P13"),
  MapEdge(from: "P13", to: "P14"),
  MapEdge(from: "P14", to: "P15"),
  MapEdge(from: "P15", to: "P16"),
  MapEdge(from: "P16", to: "P17"),
  MapEdge(from: "P17", to: "P18"),
  MapEdge(from: "P18", to: "P19"),
  MapEdge(from: "P19", to: "P20"),
  MapEdge(from: "P20", to: "P21"),
  MapEdge(from: "P21", to: "P22"),
  MapEdge(from: "P22", to: "P23"),
  MapEdge(from: "P23", to: "P24"),
  MapEdge(from: "P24", to: "P25"),
  MapEdge(from: "P25", to: "P26"),
  MapEdge(from: "P26", to: "P27"),
  MapEdge(from: "P27", to: "P28"),
  MapEdge(from: "P28", to: "P29"),
  MapEdge(from: "P29", to: "END"),
  // Park ↔ QR köprüleri — sağ sütun (A1-A13)
  MapEdge(from: "A1", to: "P1"),
  MapEdge(from: "A2", to: "P2"),
  MapEdge(from: "A3", to: "P3"),
  MapEdge(from: "A4", to: "P4"),
  MapEdge(from: "A5", to: "P5"),
  MapEdge(from: "A6", to: "P6"),
  MapEdge(from: "A7", to: "P7"),
  MapEdge(from: "A8", to: "P8"),
  MapEdge(from: "A9", to: "P9"),
  MapEdge(from: "A10", to: "P10"),
  MapEdge(from: "A11", to: "P11"),
  MapEdge(from: "A12", to: "P12"),
  MapEdge(from: "A13", to: "P13"),
  // Orta sağ (A14-A25)
  MapEdge(from: "A14", to: "P13"),
  MapEdge(from: "A15", to: "P11"),
  MapEdge(from: "A16", to: "P10"),
  MapEdge(from: "A17", to: "P9"),
  MapEdge(from: "A18", to: "P8"),
  MapEdge(from: "A19", to: "P7"),
  MapEdge(from: "A20", to: "P6"),
  MapEdge(from: "A21", to: "P5"),
  MapEdge(from: "A22", to: "P4"),
  MapEdge(from: "A23", to: "P3"),
  MapEdge(from: "A24", to: "P2"),
  MapEdge(from: "A25", to: "P1"),
  // Sol sütun (A26-A38)
  MapEdge(from: "A26", to: "P18"),
  MapEdge(from: "A27", to: "P19"),
  MapEdge(from: "A28", to: "P20"),
  MapEdge(from: "A29", to: "P21"),
  MapEdge(from: "A30", to: "P22"),
  MapEdge(from: "A31", to: "P23"),
  MapEdge(from: "A32", to: "P24"),
  MapEdge(from: "A33", to: "P25"),
  MapEdge(from: "A34", to: "P26"),
  MapEdge(from: "A35", to: "P27"),
  MapEdge(from: "A36", to: "P28"),
  MapEdge(from: "A37", to: "P28"),
  MapEdge(from: "A38", to: "P29"),
  // Orta sol (A39-A50)
  MapEdge(from: "A39", to: "P18"),
  MapEdge(from: "A40", to: "P19"),
  MapEdge(from: "A41", to: "P20"),
  MapEdge(from: "A42", to: "P21"),
  MapEdge(from: "A43", to: "P22"),
  MapEdge(from: "A44", to: "P23"),
  MapEdge(from: "A45", to: "P24"),
  MapEdge(from: "A46", to: "P25"),
  MapEdge(from: "A47", to: "P26"),
  MapEdge(from: "A48", to: "P27"),
  MapEdge(from: "A49", to: "P28"),
  MapEdge(from: "A50", to: "P29"),
];
