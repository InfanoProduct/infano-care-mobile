import 'package:dio/dio.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';

class ChatRepository {
  final ApiService _api;

  ChatRepository(this._api);

  /// Send a message to Gigi
  Future<Map<String, dynamic>> sendMessage(String content, {String? sessionId, String? moodCode}) async {
    try {
      final response = await _api.dio.post(
        '/chat/send',
        data: {
          'content': content,
          if (sessionId != null) 'sessionId': sessionId,
          if (moodCode != null) 'moodCode': moodCode,
        },
      );
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  /// Get session history with optional cursor for pagination
  Future<List<dynamic>> getHistory(String sessionId, {String? cursor, int limit = 20}) async {
    try {
      final queryParams = <String, dynamic>{
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      };
      
      final response = await _api.dio.get(
        '/chat/history/$sessionId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  /// Get all chat sessions
  Future<List<dynamic>> getSessions() async {
    try {
      final response = await _api.dio.get('/chat/sessions');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a specific chat session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _api.dio.delete('/chat/sessions/$sessionId');
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all chat history
  Future<void> deleteAllSessions() async {
    try {
      await _api.dio.delete('/chat/sessions');
    } catch (e) {
      rethrow;
    }
  }
}
