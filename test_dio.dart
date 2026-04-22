import 'package:dio/dio.dart';
void main() {
  final dio = Dio(BaseOptions(baseUrl: 'http://192.168.43.184:4005/api'));
  print('With slash: \\/user/me\ or does it resolve?');
  dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
    print('Resolved: \');
    return h.reject(DioException(requestOptions: o));
  }));
  dio.get('/user/me').catchError((e){});
  dio.get('community/circles').catchError((e){});
}
