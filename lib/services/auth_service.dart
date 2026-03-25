import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/auth_models.dart';
import '../models/exceptions.dart';

class AuthService {
  AuthService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/auth/login', data: {
        'emailOrUserName': email.trim(),
        'password': password,
      });

      return _toSession(response.data!);
    } on DioException catch (error) {
      throw ApiException(_mapLoginMessage(error));
    }
  }

  Future<AuthSession> register({
    required String userName,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/auth/register', data: {
        'userName': userName.trim(),
        'email': email.trim(),
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'password': password,
      });

      return _toSession(response.data!);
    } on DioException catch (error) {
      throw ApiException(_mapRegisterMessage(error));
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post<void>(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } on DioException {
      // Local session kapanisi icin burada sessiz geciyoruz.
    } finally {
      ApiClient.clearAccessToken();
    }
  }

  Future<UserProfile> getCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return UserProfile.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException(_mapProfileMessage(error));
    }
  }

  Future<AuthSession> _toSession(Map<String, dynamic> body) async {
    final accessToken = body['accessToken'] as String;
    final refreshToken = body['refreshToken'] as String;

    ApiClient.setAccessToken(accessToken);
    final profile = await getCurrentUser();

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      profile: profile,
    );
  }

  String _mapLoginMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    final body = error.response?.data;
    final detail = body is Map<String, dynamic> ? body['detail']?.toString() : null;

    if (statusCode == 400 || statusCode == 401) {
      return detail ?? 'E-posta veya sifre hatali.';
    }

    return detail ?? error.message ?? 'Giris sirasinda bir hata olustu.';
  }

  String _mapProfileMessage(DioException error) {
    final body = error.response?.data;
    final detail = body is Map<String, dynamic> ? body['detail']?.toString() : null;
    return detail ?? error.message ?? 'Kullanici profili yuklenemedi.';
  }

  String _mapRegisterMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    final body = error.response?.data;
    final detail = body is Map<String, dynamic> ? body['detail']?.toString() : null;

    if (statusCode == 400 || statusCode == 409) {
      return detail ?? 'Kayit bilgileri gecersiz veya zaten kullanimda.';
    }

    return detail ?? error.message ?? 'Kayit olusturulurken bir hata olustu.';
  }
}
