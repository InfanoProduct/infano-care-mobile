import 'package:dio/dio.dart';
void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'http://192.168.43.184:4005/api'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
    print('Resolved: ' + o.uri.toString());
    return h.resolve(Response(requestOptions: o, data: {'success': true, 'circles': []}));
  }));
  await dio.get('/user/me').catchError((e){print(e);});
  await dio.get('community/circles').catchError((e){print(e);});
  await dio.get('/community/events').catchError((e){print(e);});
}
