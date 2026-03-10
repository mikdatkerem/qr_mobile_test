import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

/// ── Uygulama geneli konfigürasyon ──────────────────────────────────────────
class AppConfig {
  AppConfig._();

  // Android emülatör  : http://10.0.2.2:5011
  // iOS simülatör/web : http://localhost:5011
  // Fiziksel cihaz    : http://192.168.x.x:5011
  // Cloudflare tunnel : https://xxxx.trycloudflare.com
  static const String baseHost =
      'https://give-contain-roles-permitted.trycloudflare.com';

  static String get apiBaseUrl => '$baseHost/api';
  static String get hubBaseUrl => '$baseHost/hubs/parking';
  static String get mapSvgUrl => '$baseHost/maps/kroki.svg';
}
// ────────────────────────────────────────────────────────────────────────────

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QrLocationApp());
}

class QrLocationApp extends StatelessWidget {
  const QrLocationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Konum Haritası',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.light,
          background: const Color(0xFFFFF176),
          surface: const Color(0xFFFFF9C4),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
