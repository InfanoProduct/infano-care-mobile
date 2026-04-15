import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

class ApiService {
  ApiService._();
  static ApiService? _instance;
  static late Dio _dio;

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  /// Override at build/run time:
  ///   flutter run --dart-define=API_URL=http://192.168.1.105:4000/api
  static const _defaultBaseUrl = 'http://10.0.2.2:4000/api'; // emulator fallback
  static const _baseUrl = String.fromEnvironment('API_URL', defaultValue: _defaultBaseUrl);

  static void init(LocalStorageService storage) {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // ── Request/Response logger (shows in flutter run console) ───────────────
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        logPrint: (o) => debugPrint('[API] $o'),
      ));
    }

    // ── JWT interceptor ───────────────────────────────────────────────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (!options.path.startsWith('http') && !options.path.startsWith('/')) {
          options.path = '/${options.path}';
        }
        
        final token = storage.authToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && storage.refreshToken != null) {
          try {
            final resp = await Dio().post(
              '$_baseUrl/auth/refresh',   // ← fixed: was hardcoded to 10.0.2.2
              data: {'refreshToken': storage.refreshToken},
            );
            await storage.setAuthToken(resp.data['accessToken']);
            await storage.setRefreshToken(resp.data['refreshToken']);
            error.requestOptions.headers['Authorization'] = 'Bearer ${resp.data['accessToken']}';
            return handler.resolve(await _dio.fetch(error.requestOptions));
          } catch (_) {
            await storage.clearAuthTokens();
          }
        }
        return handler.next(error);
      },
    ));

    // ── Startup connectivity ping ──────────────────────────────────────────────
    if (kDebugMode) {
      Dio().get('${_baseUrl.replaceAll('/api', '')}/health').then((r) {
        debugPrint('[API] ✅ Backend reachable: ${r.data}');
      }).catchError((e) {
        debugPrint('[API] ❌ Backend NOT reachable at $_baseUrl — $e');
      });
    }
  }

  Dio get dio => _dio;
}
