import 'package:dio/dio.dart';
void main() {
  final dio = Dio(BaseOptions(baseUrl: 'http://192.168.43.184:4005/api'));
  print(dio.options.baseUrl);
}
