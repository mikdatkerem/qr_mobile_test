import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/zone_model.dart';
import '../models/exceptions.dart';

class ZoneService {
  static const String _baseUrl = 'https://api.site.com';
  final http.Client _client;

  ZoneService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<ZoneModel>> getZones() async {
    // TODO: Backend hazır olunca aşağıdaki satırı aç, hardcodedZones'u sil.
    // return _fetchZonesFromApi();
    return Future.value(hardcodedZones);
  }

  Future<List<ZoneModel>> _fetchZonesFromApi() async {
    final uri = Uri.parse('$_baseUrl/zones');
    try {
      final response = await _client.get(uri, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ApiException('Zone listesi alınamadı',
            statusCode: response.statusCode);
      }

      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => ZoneModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Bağlantı hatası: $e');
    }
  }

  void dispose() => _client.close();
}

// ─── QR ZONE KOORDİNATLARI ───────────────────────────────────────────────────
// Her ZoneModel'in x,y merkez koordinatı — graph_data.dart'taki MapNode
// koordinatlarıyla eşleştirilmiştir (width/height dokunma alanı için).
// Backend hazır olunca bu listeyi sil, _fetchZonesFromApi() kullan.
const List<ZoneModel> hardcodedZones = [
  // Sağ sütun: START (alt) → P13 (üst köşe)
  ZoneModel(
      id: "START", label: "Başlangıç", x: 560, y: 970, width: 80, height: 60),
  ZoneModel(
      id: "P1", label: "İç Konum 1", x: 560, y: 870, width: 80, height: 60),
  ZoneModel(
      id: "P2", label: "İç Konum 2", x: 560, y: 790, width: 80, height: 60),
  ZoneModel(
      id: "P3", label: "İç Konum 3", x: 560, y: 720, width: 80, height: 60),
  ZoneModel(
      id: "P4", label: "İç Konum 4", x: 560, y: 660, width: 80, height: 60),
  ZoneModel(
      id: "P5", label: "İç Konum 5", x: 560, y: 600, width: 80, height: 60),
  ZoneModel(
      id: "P6", label: "İç Konum 6", x: 560, y: 540, width: 80, height: 60),
  ZoneModel(
      id: "P7", label: "İç Konum 7", x: 560, y: 460, width: 80, height: 60),
  ZoneModel(
      id: "P8", label: "İç Konum 8", x: 560, y: 400, width: 80, height: 60),
  ZoneModel(
      id: "P9", label: "İç Konum 9", x: 560, y: 330, width: 80, height: 60),
  ZoneModel(
      id: "P10", label: "İç Konum 10", x: 560, y: 270, width: 80, height: 60),
  ZoneModel(
      id: "P11", label: "İç Konum 11", x: 560, y: 210, width: 80, height: 60),
  ZoneModel(
      id: "P12", label: "İç Konum 12", x: 560, y: 120, width: 80, height: 60),
  ZoneModel(
      id: "P13", label: "İç Konum 13", x: 560, y: 70, width: 80, height: 60),
  // Üst geçiş: P14 → P17
  ZoneModel(
      id: "P14", label: "İç Konum 14", x: 455, y: 50, width: 80, height: 60),
  ZoneModel(
      id: "P15", label: "İç Konum 15", x: 395, y: 50, width: 80, height: 60),
  ZoneModel(
      id: "P16", label: "İç Konum 16", x: 355, y: 50, width: 80, height: 60),
  ZoneModel(
      id: "P17", label: "İç Konum 17", x: 305, y: 50, width: 80, height: 60),
  // Sol sütun: P18 (üst) → END (alt)
  ZoneModel(
      id: "P18", label: "İç Konum 18", x: 186, y: 70, width: 80, height: 60),
  ZoneModel(
      id: "P19", label: "İç Konum 19", x: 186, y: 120, width: 80, height: 60),
  ZoneModel(
      id: "P20", label: "İç Konum 20", x: 186, y: 220, width: 80, height: 60),
  ZoneModel(
      id: "P21", label: "İç Konum 21", x: 186, y: 280, width: 80, height: 60),
  ZoneModel(
      id: "P22", label: "İç Konum 22", x: 186, y: 340, width: 80, height: 60),
  ZoneModel(
      id: "P23", label: "İç Konum 23", x: 186, y: 410, width: 80, height: 60),
  ZoneModel(
      id: "P24", label: "İç Konum 24", x: 186, y: 470, width: 80, height: 60),
  ZoneModel(
      id: "P25", label: "İç Konum 25", x: 186, y: 540, width: 80, height: 60),
  ZoneModel(
      id: "P26", label: "İç Konum 26", x: 186, y: 600, width: 80, height: 60),
  ZoneModel(
      id: "P27", label: "İç Konum 27", x: 186, y: 690, width: 80, height: 60),
  ZoneModel(
      id: "P28", label: "İç Konum 28", x: 186, y: 790, width: 80, height: 60),
  ZoneModel(
      id: "P29", label: "İç Konum 29", x: 186, y: 870, width: 80, height: 60),
  ZoneModel(id: "END", label: "Bitiş", x: 186, y: 970, width: 80, height: 60),
];
