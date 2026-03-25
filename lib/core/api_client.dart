import 'package:dio/dio.dart';

import '../main.dart';

class ApiClient {
  ApiClient._();

  static final Dio _dio = _createDio();
  static String? _accessToken;

  static Dio get instance => _dio;

  static void setAccessToken(String? accessToken) {
    _accessToken = accessToken;
  }

  static void clearAccessToken() {
    _accessToken = null;
  }

  static Map<String, String> buildHeaders({
    bool includeJsonContentType = true,
    bool includeAuth = true,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (includeJsonContentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (AppConfig.appSecret.isNotEmpty) {
      headers['x-app-secret'] = AppConfig.appSecret;
    }

    if (includeAuth && _accessToken?.isNotEmpty == true) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.addAll(buildHeaders());
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            error = error.copyWith(
              message: 'Oturum dogrulanamadi veya erisim reddedildi.',
            );
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
