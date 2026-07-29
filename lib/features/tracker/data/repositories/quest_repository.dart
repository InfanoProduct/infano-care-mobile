import 'package:dio/dio.dart';
import '../models/quest_models.dart';

class QuestRepository {
  final Dio _dio;

  QuestRepository(this._dio);

  Future<List<UserQuest>> getDailyQuests() async {
    print('[QUEST] API CALL: /quest/daily');
    final response = await _dio.get('/quest/daily');
    print('[QUEST] API RESPONSE received. Success: ${response.data['success']}');
    
    if (response.data['success']) {
      final data = response.data['data'] as List;
      print('[QUEST] Found ${data.length} quests in response');
      return data
          .map((json) => UserQuest.fromJson(json))
          .toList();
    }
    throw Exception('Failed to load daily quests');
  }

  Future<UserQuest> acceptQuest(String userQuestId) async {
    final response = await _dio.post('/quest/$userQuestId/accept');
    if (response.data['success']) {
      return UserQuest.fromJson(response.data['data']);
    }
    throw Exception('Failed to accept quest');
  }

  Future<UserQuestProgress> getProgress() async {
    final response = await _dio.get('/quest/progress');
    if (response.data['success']) {
      return UserQuestProgress.fromJson(response.data['data']);
    }
    throw Exception('Failed to load progress');
  }

  Future<List<Badge>> getBadges() async {
    final response = await _dio.get('/quest/badges');
    if (response.data['success']) {
      return (response.data['data'] as List)
          .map((json) => Badge.fromJson(json))
          .toList();
    }
    throw Exception('Failed to load badges');
  }

  Future<void> completeQuestManual(String userQuestId) async {
    await _dio.post('/quest/$userQuestId/complete-manual');
  }
}
