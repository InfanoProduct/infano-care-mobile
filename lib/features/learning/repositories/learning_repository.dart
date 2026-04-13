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

  Future<Episode> getEpisode(String id) async {
    final response = await _dio.get('/learning/episodes/$id');
    return Episode.fromJson(response.data);
  }

  /// Fetch progress for a single episode.
  Future<UserProgress?> getEpisodeProgress(String episodeId) async {
    try {
      final response =
          await _dio.get('/learning/episodes/$episodeId/progress');
      return UserProgress.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  /// Post progress to the backend.
  /// [completedSegments] – list of completed segment indices (0-4).
  /// [lastViewedItemId]  – e.g. "segment_2".
  Future<void> updateEpisodeProgress({
    required String episodeId,
    List<int> completedSegments = const [],
    String? lastViewedItemId,
    dynamic history,
  }) async {
    await _dio.post(
      '/learning/episodes/$episodeId/progress',
      data: {
        'completedItems': completedSegments,
        if (lastViewedItemId != null) 'lastViewedItemId': lastViewedItemId,
        if (history != null) 'history': history,
      },
    );
  }

  /// Complete the episode and receive the backend-calculated point totals.
  Future<Map<String, dynamic>> completeEpisode({
    required String episodeId,
    required int knowledgeCheckAccuracy,
    required String reflectionMode,
    String? reflectionContent,
    String? voiceUrl,
    bool isBingeBonus = false,
  }) async {
    final response = await _dio.post(
      '/learning/episodes/$episodeId/complete',
      data: {
        'knowledgeCheckAccuracy': knowledgeCheckAccuracy,
        'reflectionMode': reflectionMode,
        'reflectionContent': reflectionContent,
        'voiceUrl': voiceUrl,
        'isBingeBonus': isBingeBonus,
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getCommunityReflections(String episodeId) async {
    final response =
        await _dio.get('/learning/episodes/$episodeId/reflections');
    return response.data as List;
  }

  Future<List<UserProgress>> getMyProgress() async {
    final response = await _dio.get('/learning/my-progress');
    return (response.data as List)
        .map((json) => UserProgress.fromJson(json))
        .toList();
  }
}
