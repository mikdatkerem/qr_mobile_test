import 'package:dio/dio.dart';
import '../main.dart';

/// Merkezi Dio instance — tüm servisler bunu kullanır.
/// Her isteğe otomatik olarak x-app-secret ve Accept header'ları eklenir.
class ApiClient {
  ApiClient._();

  static final Dio _dio = _createDio();

  static Dio get instance => _dio;

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'x-app-secret': AppConfig.appSecret,
      },
    ));

    dio.interceptors.add(_AppSecretInterceptor());

    return dio;
  }

  /// SignalR için header map — HubConnectionBuilder'a geçilir
  static Map<String, String> get signalRHeaders => {
        'x-app-secret': AppConfig.appSecret,
      };
}

class _AppSecretInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Header zaten BaseOptions'da var, burada loglama yapabiliriz
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 → secret yanlış
    if (err.response?.statusCode == 401) {
      err = err.copyWith(
        message: 'Kimlik doğrulama hatası: x-app-secret geçersiz',
      );
    }
    handler.next(err);
  }
}
