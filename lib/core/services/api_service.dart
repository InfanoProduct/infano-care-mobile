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

  static const _defaultBaseUrl = 'https://api-dev.infano.care/api/';
  static final String _baseUrl = _getNormalizedBaseUrl();

  static String _getNormalizedBaseUrl() {
    String url = const String.fromEnvironment('API_URL', defaultValue: _defaultBaseUrl);
    if (!url.endsWith('/')) {
      return '$url/';
    }
    return url;
  }

  static void init(LocalStorageService storage) {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // ── Request/Response logger (only active during development) ───────────────
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        requestBody: false,
        responseBody: false,
        responseHeader: false,
        error: true,
        logPrint: (o) => debugPrint('[API] $o'),
      ));
    }

    // ── JWT interceptor ───────────────────────────────────────────────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Ensure path doesn't start with a slash when using a baseUrl with a path segment.
        // This prevents Dio from replacing the '/api/' part of the baseUrl.
        if (!options.path.startsWith('http')) {
          if (options.path.startsWith('/')) {
            options.path = options.path.substring(1);
          }
          // Also handle cases where double slashes might be introduced if the path was empty/weird
        }
        
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
              '${_baseUrl}auth/refresh',
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
            
            // CRITICAL FIX: Only clear tokens if the refresh itself is rejected (401/403) or not found (404).
            // If it's a 404, it likely means the backend route changed or is missing, or the session is completely gone.
            if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403 || e.response?.statusCode == 404)) {
              debugPrint('[API] ⚠️ Session invalid (${e.response?.statusCode}). Clearing storage.');
              await storage.clearSession();
            } else {
              debugPrint('[API] 📡 Network error during refresh. Retaining session.');
            }
            
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;
}
