import 'dart:convert';
import 'dart:developer' as developer;
import '../main.dart';
import 'package:http/http.dart' as http;
import 'package:signalr_netcore/signalr_client.dart';

class ParkingService {
  String get _baseUrl => AppConfig.apiBaseUrl;
  String get _hubUrl => AppConfig.hubBaseUrl;

  final http.Client _client;
  HubConnection? _hubConnection;
  final void Function(String spotId, bool isOccupied)? onOccupancyChanged;

  ParkingService({http.Client? client, this.onOccupancyChanged})
      : _client = client ?? http.Client();

  // ── REST: ilk yükleme ─────────────────────────────────────────────────────

  Future<Map<String, bool>> getOccupancyMap() async {
    final uri = Uri.parse('$_baseUrl/ParkingSpots');
    final response = await _client.get(uri, headers: {
      'Accept': 'application/json'
    }).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    final result = <String, bool>{};
    for (final item in list) {
      final e = item as Map<String, dynamic>;
      final id = (e['id'] ?? e['Id']) as String;
      final isOccupied = (e['isOccupied'] ?? e['IsOccupied']) as bool;
      result[id] = isOccupied;
    }
    developer.log('Park durumu yüklendi: ${result.length} alan',
        name: 'ParkingService');
    return result;
  }

  // ── SignalR: canlı güncelleme ─────────────────────────────────────────────

  Future<void> startListening() async {
    try {
      final hubUrl = _hubUrl;
      developer.log('SignalR bağlanıyor: $hubUrl', name: 'ParkingService');

      _hubConnection = HubConnectionBuilder()
          .withUrl(hubUrl)
          .withAutomaticReconnect()
          .build();

      _hubConnection!.on('ParkingUpdated', (args) {
        developer.log('ParkingUpdated alındı: $args', name: 'ParkingService');
        if (args == null || args.isEmpty) return;
        try {
          final data = args[0] as Map<String, dynamic>;
          final spotId = (data['spotId'] ?? data['SpotId']) as String;
          final isOccupied = (data['isOccupied'] ?? data['IsOccupied']) as bool;
          onOccupancyChanged?.call(spotId, isOccupied);
        } catch (e) {
          developer.log('ParkingUpdated parse hatası: $e',
              name: 'ParkingService');
        }
      });

      _hubConnection!.onclose(({error}) {
        developer.log('SignalR bağlantısı kapandı: $error',
            name: 'ParkingService');
      });

      _hubConnection!.onreconnecting(({error}) {
        developer.log('SignalR yeniden bağlanıyor: $error',
            name: 'ParkingService');
      });

      _hubConnection!.onreconnected(({connectionId}) {
        developer.log('SignalR yeniden bağlandı: $connectionId',
            name: 'ParkingService');
      });

      await _hubConnection!.start();
      developer.log('SignalR bağlandı ✓', name: 'ParkingService');
    } catch (e) {
      developer.log('SignalR bağlantı hatası: $e', name: 'ParkingService');
      rethrow;
    }
  }

  Future<void> stopListening() async {
    await _hubConnection?.stop();
    _hubConnection = null;
  }

  void dispose() {
    stopListening();
    _client.close();
  }
}
