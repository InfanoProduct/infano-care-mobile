import 'package:dio/dio.dart';
import '../models/creative_journey_models.dart';

class CreativeJourneyRepository {
  final Dio _dio;

  CreativeJourneyRepository(this._dio);

  // ── Journeys ────────────────────────────────────────────────────────────────

  Future<List<CreativeJourney>> listJourneys() async {
    final response = await _dio.get('/creative-journey/journeys');
    final data = response.data;
    final List rawList = data is List
        ? data
        : (data is Map && data['data'] is List ? data['data'] as List : []);
    return rawList
        .map((j) => CreativeJourney.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<CreativeJourney> getJourney(String id) async {
    final response = await _dio.get('/creative-journey/journeys/$id');
    final data = response.data;
    final map = data is Map<String, dynamic>
        ? (data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data)
        : <String, dynamic>{};
    return CreativeJourney.fromJson(map);
  }

  Future<CreativeEpisode> getEpisode(String episodeId) async {
    final response = await _dio.get('/creative-journey/episodes/$episodeId');
    final data = response.data;
    final map = data is Map<String, dynamic>
        ? (data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data)
        : <String, dynamic>{};
    return CreativeEpisode.fromJson(map);
  }

  // ── Node Order (seeded shuffle) ─────────────────────────────────────────────

  Future<List<String>> getOrCreateNodeOrder(String episodeId) async {
    try {
      final response =
          await _dio.get('/creative-journey/episodes/$episodeId/node-order');
      final data = response.data;
      if (data is Map && data['nodeOrder'] is List) {
        return List<String>.from(data['nodeOrder'] as List);
      }
    } catch (_) {}
    return [];
  }

  // ── Progress ────────────────────────────────────────────────────────────────

  Future<List<NodeProgress>> getEpisodeProgress(String episodeId) async {
    try {
      final response =
          await _dio.get('/creative-journey/episodes/$episodeId/progress');
      final data = response.data;
      final List rawList = data is List
          ? data
          : (data is Map && data['data'] is List ? data['data'] as List : []);
      return rawList
          .map((p) => NodeProgress.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> updateNodeProgress({
    required String episodeId,
    required String nodeId,
    required String status,
    int xpEarned = 0,
    String? lastScreen,
  }) async {
    try {
      await _dio.post(
        '/creative-journey/episodes/$episodeId/nodes/$nodeId/progress',
        data: {
          'status': status,
          'xpEarned': xpEarned,
          'lastScreen': lastScreen,
        },
      );
    } catch (_) {
      // Gracefully ignore network exceptions during offline node transitions
    }
  }

  Future<List<NodeProgress>> getMyProgress() async {
    try {
      final response = await _dio.get('/creative-journey/my-progress');
      final data = response.data;
      final List rawList = data is List
          ? data
          : (data is Map && data['data'] is List ? data['data'] as List : []);
      return rawList
          .map((p) => NodeProgress.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Ask Gigi ────────────────────────────────────────────────────────────────

  Future<void> saveGigiEntry({
    required String episodeId,
    required String nodeId,
    required String entryText,
  }) async {
    await _dio.post(
      '/creative-journey/episodes/$episodeId/nodes/$nodeId/gigi-entry',
      data: {'entryText': entryText},
    );
  }

  /// Episode-aware Gigi AI call.
  ///
  /// [question]        — the raw user question text
  /// [episodeTitle]    — e.g. "Skin Stories" — restricts Gigi to episode scope
  /// [episodeTopics]   — short comma-separated list of what the episode covers
  /// [history]         — previous turns in this Ask Gigi session for continuity
  Future<String> askGigiAi(
    String question, {
    String? episodeTitle,
    String? episodeTopics,
    List<Map<String, String>> history = const [],
  }) async {
    try {
      // Build an episode-scoped content string so Gigi's SYSTEM_PROMPT context
      // knows to restrict answers to the episode's scope.
      final String scopedContent = _buildScopedContent(
        question: question,
        episodeTitle: episodeTitle,
        episodeTopics: episodeTopics,
      );

      final response = await _dio.post(
        '/chat/send',
        data: {
          'content': scopedContent,
          'platform': 'mobile',
          // Pass previous turns so Gigi has conversational continuity
          if (history.isNotEmpty) 'history': history,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        // Real API structure: { success: true, data: { message: { content, sender, ... }, sessionId } }
        final dataWrapper = response.data['data'];
        if (dataWrapper is Map) {
          final msg = dataWrapper['message'];
          if (msg is Map) {
            final content = msg['content'];
            if (content != null && content.toString().isNotEmpty) {
              return content.toString();
            }
          }
          // Fallback: some versions return data.response
          final fallbackContent = dataWrapper['response'] ?? dataWrapper['content'];
          if (fallbackContent != null && fallbackContent.toString().isNotEmpty) {
            return fallbackContent.toString();
          }
        }
        // Legacy flat fallback
        final legacy = response.data['response'] ?? response.data['message'];
        if (legacy != null && legacy.toString().isNotEmpty) {
          return legacy.toString();
        }
      }
    } catch (_) {}

    // Offline / error fallback — still episode-aware
    if (episodeTitle != null) {
      return "I'm here for you! 🌸 In this episode on $episodeTitle, there's a lot to explore. If you have a question about ${episodeTopics ?? 'this topic'}, feel free to ask and I'll do my best to help!";
    }
    return "I'm here for you! 🌸 Remember, Gigi is always in your corner. Ask me anything about this episode!";
  }

  /// Wraps the user's question with an episode scope instruction so the
  /// Gigi AI naturally restricts itself to episode-relevant content.
  String _buildScopedContent({
    required String question,
    String? episodeTitle,
    String? episodeTopics,
  }) {
    if (episodeTitle == null) return question;

    return '''[EPISODE CONTEXT — RESTRICT TO THIS SCOPE ONLY]
You are answering a question inside the "$episodeTitle" learning episode.
This episode covers: ${episodeTopics ?? episodeTitle}.

IMPORTANT RULES FOR THIS CONTEXT:
1. Answer ONLY questions related to the topics covered in this episode.
2. If the question is completely unrelated to this episode's topics, politely say:
   "I'm focused on the $episodeTitle episode right now! For anything else, let's connect in the Talk to Gigi chat on your home screen. 💬"
3. Keep answers warm, age-appropriate (10–16 years), and concise (2–4 sentences max).
4. Do NOT discuss unrelated topics like family issues, school stress, relationships, etc. — redirect to Talk to Gigi for those.

USER'S QUESTION: $question''';
  }
}

