import 'package:dio/dio.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

class ApiService {
  ApiService._();
  static ApiService? _instance;
  static late Dio _dio;

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  static void init(LocalStorageService storage) {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://10.0.2.2:4000/api', // Android emulator → localhost
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // JWT interceptor
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
          try {
            final resp = await Dio().post(
              'http://10.0.2.2:4000/api/auth/refresh',
              data: {'refreshToken': storage.refreshToken},
            );
            await storage.setAuthToken(resp.data['accessToken']);
            await storage.setRefreshToken(resp.data['refreshToken']);
            error.requestOptions.headers['Authorization'] = 'Bearer ${resp.data['accessToken']}';
            return handler.resolve(await _dio.fetch(error.requestOptions));
          } catch (_) {
            await storage.clearAll();
          }
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;
}
