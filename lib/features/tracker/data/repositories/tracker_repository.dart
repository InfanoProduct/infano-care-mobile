import 'package:dio/dio.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';

class TrackerRepository {
  final Dio _dio;

  TrackerRepository(this._dio);

  Future<CycleProfileModel?> getProfile() async {
    try {
      final response = await _dio.get('/tracker/profile');
      if (response.statusCode == 200 && response.data != null) {
        return CycleProfileModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PredictionResultModel?> getPrediction() async {
    try {
      final response = await _dio.get('/tracker/prediction');
      if (response.statusCode == 200 && response.data != null) {
        return PredictionResultModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> logDaily(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/tracker/log', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to log daily data');
    }
  }

  Future<CycleProfileModel> setupTracker(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/tracker/setup', data: data);
      return CycleProfileModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to setup tracker');
    }
  }

  Future<List<CycleLogModel>> getLogs({String? from, String? to}) async {
    try {
      final response = await _dio.get('/tracker/logs', queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      });
      return (response.data as List)
          .map((json) => CycleLogModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
