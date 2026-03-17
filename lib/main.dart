import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class AppConfig {
  AppConfig._();

  // flutter run --dart-define=BASE_HOST=https://your-domain.com --dart-define=APP_SECRET=xxx
  static const String baseHost =
      String.fromEnvironment('BASE_HOST', defaultValue: 'http://10.0.2.2:5011');
  static const String appSecret =
      String.fromEnvironment('APP_SECRET', defaultValue: '');

  static String get apiBaseUrl => '$baseHost/api';
  static String get hubBaseUrl => '$baseHost/hubs/parking';
  static String get mapSvgUrl => '$baseHost/maps/kroki.svg';
}

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
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      ),
      home: const HomeScreen(),
    );
  }
}
