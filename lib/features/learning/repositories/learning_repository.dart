import 'package:dio/dio.dart';

class LearningRepository {
  final Dio _dio;

  LearningRepository(this._dio);

  /// Fetch all active learning programs.
  Future<List<dynamic>> listActivePrograms() async {
    final response = await _dio.get('/programs');
    return response.data['data'] as List;
  }

  /// Fetch user enrolled programs (including programs linked via parent).
  Future<List<dynamic>> getMyProgramEnrollments() async {
    final response = await _dio.get('/programs/me');
    return response.data['data'] as List;
  }

  /// Fetch user book orders and their payment/shipping status.
  Future<List<dynamic>> getMyBookOrders() async {
    final response = await _dio.get('/shop/orders/me');
    return response.data as List;
  }

  /// Book a new program demo session
  Future<Map<String, dynamic>> bookDemoSession(Map<String, dynamic> data) async {
    final response = await _dio.post('/programs/demo/book', data: data);
    return response.data as Map<String, dynamic>;
  }
}
