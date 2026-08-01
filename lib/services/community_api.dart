import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:infano_care_mobile/models/circle.dart';
import 'package:infano_care_mobile/models/peerline_session.dart';
import 'package:infano_care_mobile/models/peerline_topic.dart';
import 'package:infano_care_mobile/models/event.dart';
import 'package:infano_care_mobile/models/post.dart';
import 'package:infano_care_mobile/models/chat_message.dart';
import 'package:path/path.dart' as path;


class CommunityApi {
  final Dio _dio;

  CommunityApi(this._dio);

  // Circles
  Future<List<Circle>> getCircles() async {
    final response = await _dio.get('community/circles');
    final data = response.data as Map<String, dynamic>;
    final circles = (data['circles'] as List)
        .map((e) => Circle.fromJson(e as Map<String, dynamic>))
        .toList();
    return circles;
  }

  Future<void> joinCircle(String circleId) async {
    await _dio.post('community/circles/join', data: {'circleIds': [circleId]});
  }

  Future<void> joinCircles(List<String> circleIds) async {
    await _dio.post('community/circles/join', data: {'circleIds': circleIds});
  }

  Future<Map<String, dynamic>> getMyFeed({int page = 1}) async {
    final response = await _dio.get('community/feed', queryParameters: {'page': page});
    return response.data as Map<String, dynamic>;
  }

  Future<void> trackCircleVisit(String circleId) async {
    await _dio.post('community/circles/$circleId/visit');
  }

  // Community Feed
  Future<Map<String, dynamic>> getCirclePosts(String circleId, {int page = 1}) async {
    final response = await _dio.get('community/circles/$circleId/posts', queryParameters: {'page': page});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPost(String circleId, String content, {bool isChallengeResponse = false, String? challengeId}) async {
    final data = <String, dynamic>{
      'content': content,
      'isChallengeResponse': isChallengeResponse,
    };
    if (challengeId != null && challengeId.isNotEmpty) {
      data['challengeId'] = challengeId;
    }
    final response = await _dio.post('community/circles/$circleId/posts', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<List<CommunityReply>> getPostReplies(String postId) async {
    final response = await _dio.get('community/posts/$postId/replies');
    final data = response.data as Map<String, dynamic>;
    final List repliesJson = data['replies'] ?? [];
    return repliesJson.map((e) => CommunityReply.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createReply(String postId, String content, {String? parentReplyId}) async {
    final data = <String, dynamic>{'content': content};
    if (parentReplyId != null) data['parentReplyId'] = parentReplyId;
    final response = await _dio.post('community/posts/$postId/replies', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> toggleReaction(String contentId, String reaction, {required String contentType, String action = 'add'}) async {
    await _dio.post('community/posts/$contentId/react', data: {
      'reaction': reaction,
      'contentType': contentType,
    });
  }

  Future<void> togglePin(String postId, {required bool pin}) async {
    await _dio.patch('community/posts/$postId/pin', data: {'pin': pin});
  }

  Future<void> reportPost(String contentId, String category, String? note, {required String contentType}) async {
    await _dio.post('community/posts/$contentId/report', data: {
      'category': category,
      'note': note,
      'contentType': contentType,
    });
  }

  Future<void> deletePost(String postId) async {
    await _dio.delete('community/posts/$postId');
  }

  Future<void> submitAppeal(String contentId, String reason, {required String contentType}) async {
    await _dio.post('community/posts/$contentId/appeal', data: {
      'reason': reason,
      'contentType': contentType,
    });
  }

  // PeerLine
  Future<List<PeerLineTopic>> getPeerLineTopics() async {
    final response = await _dio.get('peerline/topics');
    final data = response.data as Map<String, dynamic>;
    return (data['topics'] as List)
        .map((e) => PeerLineTopic.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MentorAvailability> getPeerLineAvailability() async {
    final response = await _dio.get('peerline/availability');
    // Match the new response structure
    if (response.data is Map && response.data.containsKey('availability')) {
      return MentorAvailability.fromJson(response.data['availability'] as Map<String, dynamic>);
    }
    return MentorAvailability.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getMentorStatus() async {
    final response = await _dio.get('peerline/mentor/status');
    return response.data as Map<String, dynamic>;
  }

  /// NEW: Teen sends a connection request to a specific peer mentor.
  /// Returns the connection record (status: MATCHING = pending).
  Future<PeerLineSession> requestConnection({
    required String mentorId,
    List<String> topicIds = const [],
    String? message,
  }) async {
    final dataMap = <String, dynamic>{
      'mentorId': mentorId,
      'topicIds': topicIds,
      if (message != null && message.isNotEmpty) 'message': message,
    };
    final response = await _dio.post('peerline/connections/request', data: dataMap);
    final Map<String, dynamic> data = response.data;
    if (data.containsKey('session')) {
      return PeerLineSession.fromJson(data['session'] as Map<String, dynamic>);
    }
    return PeerLineSession.fromJson(data);
  }

  /// LEGACY: still supported by the API. Use requestConnection for new code.
  Future<PeerLineSession> requestPeerLineSession({required List<String> topicIds, bool requestVerified = false, String? requestedMentorId}) async {
    final dataMap = <String, dynamic>{
      'topicIds': topicIds,
      'requestVerified': requestVerified,
    };
    if (requestedMentorId != null) {
      dataMap['requestedMentorId'] = requestedMentorId;
    }
    final response = await _dio.post('peerline/sessions/request', data: dataMap);
    final Map<String, dynamic> data = response.data;
    if (data.containsKey('session')) {
      return PeerLineSession.fromJson(data['session'] as Map<String, dynamic>);
    }
    return PeerLineSession.fromJson(data);
  }

  /// NEW: Peer mentor accepts a teen's connection request.
  Future<PeerLineSession> acceptConnection(String connectionId) async {
    final response = await _dio.post('peerline/connections/$connectionId/accept');
    final Map<String, dynamic> data = response.data;
    if (data.containsKey('session')) {
      return PeerLineSession.fromJson(data['session'] as Map<String, dynamic>);
    }
    return PeerLineSession.fromJson(data);
  }

  /// NEW: Peer mentor declines a teen's connection request.
  Future<void> declineConnection(String connectionId) async {
    await _dio.post('peerline/connections/$connectionId/decline');
  }

  /// NEW: Teen cancels their own pending connection request.
  Future<void> cancelConnection(String connectionId) async {
    await _dio.post('peerline/connections/$connectionId/cancel');
  }

  /// LEGACY: still works via the old route.
  Future<PeerLineSession> acceptPeerLineSession(String sessionId) async {
    final response = await _dio.post('peerline/mentor/sessions/$sessionId/accept');
    final Map<String, dynamic> data = response.data;
    if (data.containsKey('session')) {
      return PeerLineSession.fromJson(data['session'] as Map<String, dynamic>);
    }
    return PeerLineSession.fromJson(data);
  }

  /// Get all connections/sessions for the current user.
  Future<List<PeerLineSession>> getPeerLineSessions({String role = 'mentee', String? status}) async {
    final Map<String, dynamic> query = {'role': role};
    if (status != null) query['status'] = status;
    final response = await _dio.get('peerline/sessions', queryParameters: query);
    final data = response.data as Map<String, dynamic>;
    return (data['sessions'] as List)
        .map((e) => PeerLineSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PeerLineSession> getSession(String sessionId) async {
    final response = await _dio.get('peerline/sessions/$sessionId');
    final Map<String, dynamic> data = response.data;
    if (data.containsKey('session')) {
      return PeerLineSession.fromJson(data['session'] as Map<String, dynamic>);
    }
    return PeerLineSession.fromJson(data);
  }

  Future<List<ChatMessage>> getChatMessages(String sessionId) async {
    final response = await _dio.get('peerline/sessions/$sessionId/messages');
    final List messagesJson = response.data['messages'] ?? [];
    return messagesJson.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendPeerLineMessage(String sessionId, String content) async {
    await _dio.post('peerline/sessions/$sessionId/messages', data: {
      'content': content,
    });
  }

  Future<Map<String, dynamic>> getMentorStats() async {
    final response = await _dio.get('peerline/mentor/stats');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMentorAvailability(bool isAvailable) async {
    final response = await _dio.patch('peerline/mentor/availability', data: {
      'isAvailable': isAvailable,
    });
    return response.data as Map<String, dynamic>;
  }

  /// DEPRECATED — claim model removed. Kept so existing mentor dashboard code compiles.
  /// In the new model peers only accept incoming connection requests — they don't claim.
  Future<PeerLineSession> claimNextSession() async {
    throw Exception('Session claiming is no longer supported. Peers now accept incoming connection requests.');
  }

  /// Accept a pending connection request. Wraps the new /connections/:id/accept endpoint.
  Future<PeerLineSession> acceptSession(String connectionId) async {
    return acceptConnection(connectionId);
  }

  Future<String> uploadMedia(String filePath, {String folder = 'peerline'}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: path.basename(filePath)),
    });
    
    final response = await _dio.post('peerline/mentor/media', 
      data: formData,
      queryParameters: {'folder': folder},
    );
    
    return response.data['mediaUrl'];
  }

  Future<List<Map<String, dynamic>>> searchMentors(List<String> topicIds) async {

    final path = 'peerline/mentor/search';
    final query = {'topics': topicIds.join(',')};
    
    debugPrint('COMMUNITY_API: Searching mentors at ${_dio.options.baseUrl}$path with query $query');
    
    try {
      final response = await _dio.get(path, queryParameters: query);
      debugPrint('COMMUNITY_API: Search response status: ${response.statusCode}');
      debugPrint('COMMUNITY_API: Search response data: ${response.data}');
      
      final data = response.data as Map<String, dynamic>;
      final mentors = (data['mentors'] as List).map((e) => e as Map<String, dynamic>).toList();
      debugPrint('COMMUNITY_API: Found ${mentors.length} mentors in response');
      return mentors;
    } catch (e) {
      debugPrint('COMMUNITY_API: ERROR in searchMentors: $e');
      if (e is DioException) {
        debugPrint('COMMUNITY_API: ERROR Details: ${e.response?.statusCode} - ${e.response?.data}');
      }
      rethrow;
    }
  }

  // Events
  Future<List<CommunityEvent>> getCommunityEvents({String? status}) async {
    final Map<String, dynamic> query = {};
    if (status != null) query['status'] = status;
    
    final response = await _dio.get('community/events', queryParameters: query);
    final data = response.data as Map<String, dynamic>;
    return (data['events'] as List)
        .map((e) => CommunityEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<EventQuestion>> getEventQuestions(String eventId) async {
    final response = await _dio.get('events/$eventId/questions');
    final data = response.data as Map<String, dynamic>;
    final List questionsJson = data['questions'] ?? [];
    return questionsJson.map((e) => EventQuestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EventQuestion> submitEventQuestion(String eventId, String content, {bool isAnonymous = false}) async {
    final response = await _dio.post('events/$eventId/questions', data: {
      'content': content,
      'isAnonymous': isAnonymous,
    });
    return EventQuestion.fromJson(response.data['question'] as Map<String, dynamic>);
  }

  Future<void> setEventReminder(String eventId) async {
    await _dio.post('events/$eventId/reminder');
  }

  Future<WeeklyChallenge> getWeeklyChallenge() async {
    final response = await _dio.get('community/challenge/weekly');
    final data = response.data as Map<String, dynamic>;
    // Backend wraps the challenge inside a 'challenge' key: { success: true, challenge: {...} }
    final challengeJson = data.containsKey('challenge') && data['challenge'] != null
        ? data['challenge'] as Map<String, dynamic>
        : data;
    return WeeklyChallenge.fromJson(challengeJson);
  }

  // Bookmarks
  Future<Map<String, dynamic>> toggleBookmark(String contentId, {required String contentType}) async {
    final response = await _dio.post('community/posts/$contentId/bookmark', data: {
      'contentType': contentType,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<CommunityPost>> getBookmarks() async {
    final response = await _dio.get('community/bookmarks');
    final data = response.data as Map<String, dynamic>;
    final bookmarksJson = data['bookmarks'] as List? ?? [];
    return bookmarksJson.map((e) => CommunityPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Safety
  Future<Map<String, dynamic>> getCrisisResources({String locale = 'en-IN'}) async {
    final response = await _dio.get('safety/crisis-resources', queryParameters: {'locale': locale});
    return response.data as Map<String, dynamic>;
  }
}
