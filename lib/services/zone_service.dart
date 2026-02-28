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

// ─── YOL KOORDİNATLARI ───────────────────────────────────────────────────────
// SVG viewBox boyutuna göre ayarlandı.
// Her ZoneModel'in x,y'si kutucuğun sol üst köşesi (merkez = x+40, y+30).
// Backend hazır olunca bu listeyi sil, _fetchZonesFromApi() kullan.
// ignore: library_private_types_in_public_api
const List<ZoneModel> hardcodedZones = [
  ZoneModel(
      id: "P1", label: "insideloc 1", x: 560, y: 550, width: 80, height: 60),
  ZoneModel(
      id: "P2", label: "insideloc 2", x: 560, y: 520, width: 80, height: 60),
  ZoneModel(
      id: "P3", label: "insideloc 3", x: 560, y: 490, width: 80, height: 60),
  ZoneModel(
      id: "P4", label: "insideloc 4", x: 560, y: 460, width: 80, height: 60),
  ZoneModel(
      id: "P5", label: "insideloc 5", x: 560, y: 430, width: 80, height: 60),
  ZoneModel(
      id: "P6", label: "insideloc 6", x: 560, y: 400, width: 80, height: 60),
  ZoneModel(
      id: "P7", label: "insideloc 7", x: 560, y: 370, width: 80, height: 60),
  ZoneModel(
      id: "P8", label: "insideloc 8", x: 560, y: 340, width: 80, height: 60),
  ZoneModel(
      id: "P9", label: "insideloc 9", x: 560, y: 310, width: 80, height: 60),
  ZoneModel(
      id: "P10", label: "insideloc 10", x: 560, y: 280, width: 80, height: 60),
  ZoneModel(
      id: "P11", label: "insideloc 11", x: 560, y: 250, width: 80, height: 60),
  ZoneModel(
      id: "P12", label: "insideloc 12", x: 560, y: 220, width: 80, height: 60),
  ZoneModel(
      id: "P13", label: "insideloc 13", x: 560, y: 190, width: 80, height: 60),
  ZoneModel(
      id: "P14", label: "insideloc 14", x: 560, y: 160, width: 80, height: 60),
  ZoneModel(
      id: "P15", label: "insideloc 15", x: 560, y: 130, width: 80, height: 60),
  ZoneModel(
      id: "P16", label: "insideloc 16", x: 560, y: 100, width: 80, height: 60),
  ZoneModel(
      id: "P17", label: "insideloc 17", x: 560, y: 70, width: 80, height: 60),
  ZoneModel(
      id: "P18", label: "insideloc 18", x: 560, y: 40, width: 80, height: 60),
  ZoneModel(
      id: "P19", label: "insideloc 19", x: 455, y: 22, width: 80, height: 60),
  ZoneModel(
      id: "P20", label: "insideloc 20", x: 395, y: 22, width: 80, height: 60),
  ZoneModel(
      id: "P21", label: "insideloc 21", x: 365, y: 22, width: 80, height: 60),
  ZoneModel(
      id: "P22", label: "insideloc 22", x: 305, y: 22, width: 80, height: 60),
  ZoneModel(
      id: "P23", label: "insideloc 23", x: 186, y: 40, width: 80, height: 60),
  ZoneModel(
      id: "P24", label: "insideloc 24", x: 186, y: 70, width: 80, height: 60),
  ZoneModel(
      id: "P25", label: "insideloc 25", x: 186, y: 100, width: 80, height: 60),
  ZoneModel(
      id: "P26", label: "insideloc 26", x: 186, y: 130, width: 80, height: 60),
  ZoneModel(
      id: "P27", label: "insideloc 27", x: 186, y: 160, width: 80, height: 60),
  ZoneModel(
      id: "P28", label: "insideloc 28", x: 186, y: 190, width: 80, height: 60),
  ZoneModel(
      id: "P29", label: "insideloc 29", x: 186, y: 220, width: 80, height: 60),
  ZoneModel(
      id: "P30", label: "insideloc 30", x: 186, y: 250, width: 80, height: 60),
  ZoneModel(
      id: "P31", label: "insideloc 31", x: 186, y: 280, width: 80, height: 60),
  ZoneModel(
      id: "P32", label: "insideloc 32", x: 186, y: 310, width: 80, height: 60),
  ZoneModel(
      id: "P33", label: "insideloc 33", x: 186, y: 340, width: 80, height: 60),
  ZoneModel(
      id: "P34", label: "insideloc 34", x: 186, y: 370, width: 80, height: 60),
  ZoneModel(
      id: "P35", label: "insideloc 35", x: 186, y: 400, width: 80, height: 60),
  ZoneModel(
      id: "P36", label: "insideloc 36", x: 186, y: 430, width: 80, height: 60),
  ZoneModel(
      id: "P37", label: "insideloc 37", x: 186, y: 460, width: 80, height: 60),
  ZoneModel(
      id: "P38", label: "insideloc 38", x: 186, y: 490, width: 80, height: 60),
  ZoneModel(
      id: "P39", label: "insideloc 39", x: 186, y: 520, width: 80, height: 60),
  ZoneModel(
      id: "P40", label: "insideloc 40", x: 186, y: 550, width: 80, height: 60),
];
