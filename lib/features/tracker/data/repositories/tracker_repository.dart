import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/core/services/privacy_service.dart';

@lazySingleton
class TrackerRepository {
  final Dio _dio;
  final PrivacyService _privacyService;

  TrackerRepository(this._dio, this._privacyService);

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

  Future<void> updatePeriodRange(DateTime start, DateTime end) async {
    try {
      await _dio.post('/tracker/period-range', data: {
        'startDate': start.toUtc().toIso8601String(),
        'endDate': end.toUtc().toIso8601String(),
      });
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update period range');
    }
  }

  Future<List<CycleLogModel>> getLogs({String? from, String? to}) async {
    try {
      final response = await _dio.get('/tracker/logs', queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      });
      
      var logs = (response.data as List).map((json) => CycleLogModel.fromJson(json)).toList();

      // Inject dummy data for requested user
      if (logs.isEmpty) {
        logs = _getDummyLogs();
      }
      
      return logs;
    } catch (e) {
      return _getDummyLogs();
    }
  }

  Future<List<CycleRecordModel>> getHistory() async {
    try {
      final response = await _dio.get('/tracker/history');
      if (response.statusCode == 200 && response.data != null) {
        var history = (response.data as List).map((json) => CycleRecordModel.fromJson(json)).toList();
        if (history.isEmpty) {
          history = _getDummyHistory();
        }
        return history;
      }
      return _getDummyHistory();
    } catch (e) {
      return _getDummyHistory();
    }
  }

  List<CycleLogModel> _getDummyLogs() {
    final now = DateTime.now();
    final logs = <CycleLogModel>[];
    
    // Last 3 months of data
    for (int i = 0; i < 90; i++) {
      final date = now.subtract(Duration(days: i));
      
      // Period every ~28 days for 5 days
      final dayOfCycle = i % 28;
      String? flow;
      if (dayOfCycle >= 0 && dayOfCycle < 5) {
        flow = dayOfCycle == 0 || dayOfCycle == 4 ? 'light' : 'medium';
      }

      // Random mood for some days
      String? mood;
      if (i % 3 == 0) mood = 'Happy';
      if (i % 7 == 0) mood = 'Calm';

      logs.add(CycleLogModel(
        id: 'dummy_$i',
        date: date,
        flow: flow,
        moodPrimary: mood,
        isRetroactive: i > 0,
      ));
    }
    return logs;
  }

  List<CycleRecordModel> _getDummyHistory() {
    final now = DateTime.now();
    return [
      CycleRecordModel(
        id: 'h1',
        cycleNumber: 1,
        startDate: now.subtract(const Duration(days: 28)),
        periodStartDate: now.subtract(const Duration(days: 28)),
        periodEndDate: now.subtract(const Duration(days: 23)),
        cycleLengthDays: 28,
        periodDurationDays: 5,
        isComplete: true,
      ),
      CycleRecordModel(
        id: 'h2',
        cycleNumber: 2,
        startDate: now.subtract(const Duration(days: 56)),
        periodStartDate: now.subtract(const Duration(days: 56)),
        periodEndDate: now.subtract(const Duration(days: 51)),
        cycleLengthDays: 28,
        periodDurationDays: 5,
        isComplete: true,
      ),
    ];
  }
}
