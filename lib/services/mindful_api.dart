import 'package:dio/dio.dart';
import '../models/mindful_activity.dart';

class MindfulApi {
  final Dio _dio;

  MindfulApi(this._dio);

  Future<List<MindfulActivity>> getActivities() async {
    try {
      final response = await _dio.get('/mindful');
      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((json) => MindfulActivity.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeActivity(String activityId) async {
    try {
      final response = await _dio.post('/mindful/complete', data: {
        'activityId': activityId,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
