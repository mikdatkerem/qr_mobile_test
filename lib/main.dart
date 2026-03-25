import 'package:flutter/material.dart';

import 'app/app_session_controller.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';

class AppConfig {
  AppConfig._();

  static const String baseHost = String.fromEnvironment(
    'BASE_HOST',
    defaultValue: 'http://10.0.2.2:5011',
  );

  // Mobile istemcide secret varsayilan olarak gomulu tutulmaz.
  static const String appSecret = String.fromEnvironment(
    'APP_SECRET',
    defaultValue: '',
  );

  static String get apiBaseUrl => '$baseHost/api';
  static String get hubBaseUrl => '$baseHost/hubs/parking';
  static String get mapSvgUrl => '$baseHost/maps/kroki.svg';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessionController = AppSessionController();
  await sessionController.restore();
  runApp(BuLocationApp(sessionController: sessionController));
}

class BuLocationApp extends StatelessWidget {
  const BuLocationApp({super.key, required this.sessionController});

  final AppSessionController sessionController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sessionController,
      builder: (context, _) {
        return MaterialApp(
          title: 'BuLocation',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF3F6FB),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2155D6),
              secondary: Color(0xFF5B7DE8),
              surface: Color(0xFFFFFFFF),
              onSurface: Color(0xFF182033),
              outline: Color(0xFFD7DFEE),
            ),
            fontFamily: 'SF Pro Display',
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              foregroundColor: Color(0xFF182033),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              hintStyle: const TextStyle(color: Color(0xFFA4AFC3)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE4EAF5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE4EAF5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFF2155D6), width: 1.2),
              ),
            ),
          ),
          home: sessionController.isAuthenticated
              ? AppShell(sessionController: sessionController)
              : LoginScreen(sessionController: sessionController),
        );
      },
    );
  }
}
