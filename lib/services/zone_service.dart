import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/zone_model.dart';
import '../models/exceptions.dart';

class ZoneService {
  static const String _baseUrl = 'https://api.site.com';
  final http.Client _client;

  ZoneService({http.Client? client}) : _client = client ?? http.Client();

  /// Backend hazır olunca bu metodu kullan.
  /// Şu an hardcoded test verisi döndürüyor.
  Future<List<ZoneModel>> getZones() async {
    // TODO: Backend hazır olunca aşağıdaki satırı aç, _hardcodedZones'u sil.
    // return _fetchZonesFromApi();
    return Future.value(_hardcodedZones);
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

// ─── YOL KOORDİNATLARI ───────────────────────────────────────────────────────
// SVG viewBox boyutuna göre ayarlandı.
// Her ZoneModel'in x,y'si kutucuğun sol üst köşesi (merkez = x+40, y+30).
// Backend hazır olunca bu listeyi sil, _fetchZonesFromApi() kullan.
const List<ZoneModel> _hardcodedZones = [
  ZoneModel(id: "P01", label: "Durak 1", x: 478, y: 904, width: 80, height: 60),
  ZoneModel(id: "P02", label: "Durak 2", x: 482, y: 862, width: 80, height: 60),
  ZoneModel(id: "P03", label: "Durak 3", x: 480, y: 824, width: 80, height: 60),
  ZoneModel(id: "P04", label: "Durak 4", x: 482, y: 791, width: 80, height: 60),
  ZoneModel(id: "P05", label: "Durak 5", x: 483, y: 753, width: 80, height: 60),
  ZoneModel(id: "P06", label: "Durak 6", x: 483, y: 722, width: 80, height: 60),
  ZoneModel(id: "P07", label: "Durak 7", x: 483, y: 693, width: 80, height: 60),
  ZoneModel(id: "P08", label: "Durak 8", x: 483, y: 659, width: 80, height: 60),
  ZoneModel(id: "P09", label: "Durak 9", x: 481, y: 623, width: 80, height: 60),
  ZoneModel(
      id: "P10", label: "Durak 10", x: 482, y: 589, width: 80, height: 60),
  ZoneModel(
      id: "P11", label: "Durak 11", x: 485, y: 558, width: 80, height: 60),
  ZoneModel(
      id: "P12", label: "Durak 12", x: 486, y: 526, width: 80, height: 60),
  ZoneModel(
      id: "P13", label: "Durak 13", x: 476, y: 484, width: 80, height: 60),
  ZoneModel(
      id: "P14", label: "Durak 14", x: 476, y: 457, width: 80, height: 60),
  ZoneModel(
      id: "P15", label: "Durak 15", x: 473, y: 407, width: 80, height: 60),
  ZoneModel(
      id: "P16", label: "Durak 16", x: 476, y: 385, width: 80, height: 60),
  ZoneModel(
      id: "P17", label: "Durak 17", x: 477, y: 340, width: 80, height: 60),
  ZoneModel(
      id: "P18", label: "Durak 18", x: 478, y: 320, width: 80, height: 60),
  ZoneModel(
      id: "P19", label: "Durak 19", x: 476, y: 254, width: 80, height: 60),
  ZoneModel(
      id: "P20", label: "Durak 20", x: 479, y: 218, width: 80, height: 60),
  ZoneModel(
      id: "P21", label: "Durak 21", x: 477, y: 183, width: 80, height: 60),
  ZoneModel(
      id: "P22", label: "Durak 22", x: 479, y: 156, width: 80, height: 60),
  ZoneModel(
      id: "P23", label: "Durak 23", x: 482, y: 124, width: 80, height: 60),
  ZoneModel(id: "P24", label: "Durak 24", x: 475, y: 63, width: 80, height: 60),
  ZoneModel(id: "P25", label: "Durak 25", x: 368, y: 25, width: 80, height: 60),
  ZoneModel(id: "P26", label: "Durak 26", x: 310, y: 24, width: 80, height: 60),
  ZoneModel(id: "P27", label: "Durak 27", x: 270, y: 25, width: 80, height: 60),
  ZoneModel(id: "P28", label: "Durak 28", x: 221, y: 26, width: 80, height: 60),
  ZoneModel(id: "P29", label: "Durak 29", x: 126, y: 80, width: 80, height: 60),
  ZoneModel(
      id: "P30", label: "Durak 30", x: 125, y: 143, width: 80, height: 60),
  ZoneModel(
      id: "P31", label: "Durak 31", x: 127, y: 189, width: 80, height: 60),
  ZoneModel(
      id: "P32", label: "Durak 32", x: 126, y: 211, width: 80, height: 60),
  ZoneModel(
      id: "P33", label: "Durak 33", x: 124, y: 248, width: 80, height: 60),
  ZoneModel(
      id: "P34", label: "Durak 34", x: 122, y: 276, width: 80, height: 60),
  ZoneModel(
      id: "P35", label: "Durak 35", x: 120, y: 322, width: 80, height: 60),
  ZoneModel(
      id: "P36", label: "Durak 36", x: 119, y: 344, width: 80, height: 60),
  ZoneModel(
      id: "P37", label: "Durak 37", x: 118, y: 379, width: 80, height: 60),
  ZoneModel(
      id: "P38", label: "Durak 38", x: 117, y: 411, width: 80, height: 60),
  ZoneModel(
      id: "P39", label: "Durak 39", x: 117, y: 456, width: 80, height: 60),
  ZoneModel(
      id: "P40", label: "Durak 40", x: 116, y: 481, width: 80, height: 60),
  ZoneModel(
      id: "P41", label: "Durak 41", x: 115, y: 519, width: 80, height: 60),
  ZoneModel(
      id: "P42", label: "Durak 42", x: 115, y: 542, width: 80, height: 60),
  ZoneModel(
      id: "P43", label: "Durak 43", x: 116, y: 588, width: 80, height: 60),
  ZoneModel(
      id: "P44", label: "Durak 44", x: 119, y: 618, width: 80, height: 60),
  ZoneModel(
      id: "P45", label: "Durak 45", x: 119, y: 659, width: 80, height: 60),
  ZoneModel(
      id: "P46", label: "Durak 46", x: 118, y: 679, width: 80, height: 60),
  ZoneModel(
      id: "P47", label: "Durak 47", x: 119, y: 719, width: 80, height: 60),
  ZoneModel(
      id: "P48", label: "Durak 48", x: 119, y: 758, width: 80, height: 60),
  ZoneModel(
      id: "P49", label: "Durak 49", x: 119, y: 791, width: 80, height: 60),
  ZoneModel(
      id: "P50", label: "Durak 50", x: 118, y: 813, width: 80, height: 60),
  ZoneModel(
      id: "P51", label: "Durak 51", x: 119, y: 860, width: 80, height: 60),
  ZoneModel(
      id: "P52", label: "Durak 52", x: 122, y: 907, width: 80, height: 60),
];
