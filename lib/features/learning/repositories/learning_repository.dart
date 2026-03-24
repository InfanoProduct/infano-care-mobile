import 'package:dio/dio.dart';
import '../models/learning_models.dart';

class LearningRepository {
  final Dio _dio;

  LearningRepository(this._dio);

  Future<List<LearningJourney>> listJourneys({String? ageBand}) async {
    final response = await _dio.get('/learning/journeys', queryParameters: {
      if (ageBand != null) 'ageBand': ageBand,
    });
    return (response.data as List).map((json) => LearningJourney.fromJson(json)).toList();
  }

  Future<LearningJourney> getJourney(String id) async {
    final response = await _dio.get('/learning/journeys/$id');
    return LearningJourney.fromJson(response.data);
  }

  Future<void> completeSummary({
    required String summaryId,
    required List<dynamic> completedItems,
    String? lastViewedItemId,
  }) async {
    await _dio.post(
      '/learning/summaries/$summaryId/complete',
      data: {
        'completedItems': completedItems,
        'lastViewedItemId': lastViewedItemId,
      },
    );
  }

  Future<List<UserProgress>> getMyProgress() async {
    final response = await _dio.get('/learning/my-progress');
    return (response.data as List).map((json) => UserProgress.fromJson(json)).toList();
  }
}
