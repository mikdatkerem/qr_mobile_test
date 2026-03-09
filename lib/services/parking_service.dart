import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:signalr_netcore/signalr_client.dart';

/// Park yeri anlık doluluk servisi.
/// - İlk yükleme: REST GET /api/parking-spots
/// - Anlık güncelleme: SignalR /hubs/parking → "ParkingUpdated" eventi
class ParkingService {
  static const String _baseUrl = 'http://10.0.2.2:5011/api';
  static const String _hubUrl = 'http://10.0.2.2:5011/hubs/parking';

  final http.Client _client;
  HubConnection? _hubConnection;

  /// Dışarıya açık stream: spotId → isOccupied
  final void Function(String spotId, bool isOccupied)? onOccupancyChanged;

  ParkingService({
    http.Client? client,
    this.onOccupancyChanged,
  }) : _client = client ?? http.Client();

  // ── REST: ilk yükleme ───────────────────────────────────────────────────

  /// GET /api/parking-spots → Map<spotId, isOccupied>
  Future<Map<String, bool>> getOccupancyMap() async {
    final uri = Uri.parse('$_baseUrl/parking-spots');
    final response = await _client.get(uri, headers: {
      'Accept': 'application/json'
    }).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Park durumu alınamadı: ${response.statusCode}');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return {
      for (final e in list) (e['id'] as String): (e['isOccupied'] as bool),
    };
  }

  // ── SignalR: canlı güncelleme ────────────────────────────────────────────

  Future<void> startListening() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(_hubUrl)
        .withAutomaticReconnect()
        .build();

    // "ParkingUpdated" → { spotId, isOccupied }
    _hubConnection!.on('ParkingUpdated', (args) {
      if (args == null || args.isEmpty) return;
      final data = args[0] as Map<String, dynamic>;
      final spotId = data['spotId'] as String;
      final isOccupied = data['isOccupied'] as bool;
      onOccupancyChanged?.call(spotId, isOccupied);
    });

    _hubConnection!.onclose(({error}) {
      // Otomatik reconnect ayarlı, log yeterli
    });

    try {
      await _hubConnection!.start();
    } catch (_) {
      // SignalR bağlanamazsa REST verisiyle devam edilir
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
