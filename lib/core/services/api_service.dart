import 'dart:async';
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

  static Completer<void>? _refreshCompleter;

  /// Override at build/run time:
  ///   flutter run --dart-define=API_URL=http://192.168.1.105:4000/api
  static const _defaultBaseUrl = 'http://109.199.120.104:8084/api'; // VPS fallback (was 10.0.2.2:4000)
  static const _baseUrl = String.fromEnvironment('API_URL', defaultValue: _defaultBaseUrl);

  static void init(LocalStorageService storage) {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // ── Request/Response logger (shows in flutter run console) ───────────────
    // ── Request/Response logger (shows even in release/APK) ────────────────
    _dio.interceptors.add(LogInterceptor(
      requestHeader: false,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      logPrint: (o) => debugPrint('[API] $o'),
    ));

    // ── JWT interceptor ───────────────────────────────────────────────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = storage.authToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && storage.refreshToken != null) {
          // 1. If a refresh is already in progress, wait for it
          if (_refreshCompleter != null) {
            try {
              await _refreshCompleter!.future;
              // Retry the original request with the new token
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer ${storage.authToken}';
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }

          // 2. Start a new refresh operation
          _refreshCompleter = Completer<void>();
          try {
            debugPrint('[API] 🔄 Token expired. Attempting refresh...');
            final resp = await Dio().post(
              '$_baseUrl/auth/refresh',
              data: {'refreshToken': storage.refreshToken},
            );

            final newAccess = resp.data['accessToken'];
            final newRefresh = resp.data['refreshToken'];

            if (newAccess != null) {
              await storage.setAuthToken(newAccess);
              if (newRefresh != null) await storage.setRefreshToken(newRefresh);

              _refreshCompleter!.complete();
              _refreshCompleter = null;

              // Retry the original request
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccess';
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } else {
              throw Exception('Refresh token failed - no access token returned');
            }
          } catch (e) {
            _refreshCompleter!.completeError(e);
            _refreshCompleter = null;
            
            // CRITICAL FIX: Only clear tokens if the refresh itself is rejected (401/403)
            // If it's a network error, we keep the tokens and let the original request fail naturally.
            if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
              debugPrint('[API] ⚠️ Refresh token rejected. Clearing session.');
              await storage.clearSession();
              // The GoRouter refreshListenable (storage) will handle the redirect to splash/login.
            } else {
              debugPrint('[API] 📡 Network error during refresh. Retaining session for retry.');
            }
            
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    ));

    // ── Startup connectivity ping ──────────────────────────────────────────────
    // ── Startup connectivity ping ──────────────────────────────────────────
    Dio().get('${_baseUrl.replaceAll('/api', '')}/health').then((r) {
      debugPrint('[API] ✅ Backend reachable: ${r.data}');
    }).catchError((e) {
      debugPrint('[API] ❌ Backend NOT reachable at $_baseUrl — $e');
    });
  }

  Dio get dio => _dio;
}
