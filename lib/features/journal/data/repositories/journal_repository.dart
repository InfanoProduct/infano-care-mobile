import 'package:dio/dio.dart';
import 'package:infano_care_mobile/features/journal/data/models/journal_entry.dart';
import 'package:infano_care_mobile/features/journal/data/models/journal_streak.dart';

class JournalRepository {
  final Dio _dio;

  const JournalRepository(this._dio);

  // ── Entries ──────────────────────────────────────────────────────────────────

  Future<JournalEntry> createEntry({
    required String mode,
    required Map<String, dynamic> content,
    String? promptId,
    String? moodTag,
    String? moodColor,
    String? title,
    bool isSealedTimeCapsule = false,
    String? capsuleRevealDate,
    String visibility = 'private',
    String? linkedLearningEpisodeId,
  }) async {
    final res = await _dio.post('/journal/entries', data: {
      'mode': mode,
      'content': content,
      'promptId': ?promptId,
      'moodTag': ?moodTag,
      'moodColor': ?moodColor,
      'title': ?title,
      'isSealedTimeCapsule': isSealedTimeCapsule,
      'capsuleRevealDate': ?capsuleRevealDate,
      'visibility': visibility,
      'linkedLearningEpisodeId': ?linkedLearningEpisodeId,
    });
    return JournalEntry.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> listEntries({
    int page = 1,
    int limit = 20,
    String? mode,
    String? from,
    String? to,
  }) async {
    final res = await _dio.get('/journal/entries', queryParameters: {
      'page': page,
      'limit': limit,
      'mode': ?mode,
      'from': ?from,
      'to': ?to,
    });
    final data = res.data as Map<String, dynamic>;
    return {
      'entries': (data['entries'] as List)
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      'total': data['total'],
      'page': data['page'],
      'pages': data['pages'],
    };
  }

  Future<JournalEntry> getEntry(String id) async {
    final res = await _dio.get('/journal/entries/$id');
    return JournalEntry.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<JournalEntry> updateEntry(String id, Map<String, dynamic> dto) async {
    final res = await _dio.put('/journal/entries/$id', data: dto);
    return JournalEntry.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteEntry(String id) async {
    await _dio.delete('/journal/entries/$id');
  }

  // ── Prompts ──────────────────────────────────────────────────────────────────

  Future<JournalPrompt?> getDailyPrompt() async {
    final res = await _dio.get('/journal/prompts/daily');
    final data = res.data['data'];
    if (data == null) return null;
    return JournalPrompt.fromJson(data as Map<String, dynamic>);
  }

  Future<JournalPrompt?> getRandomPrompt({String? category}) async {
    final res = await _dio.get('/journal/prompts/jar',
        queryParameters: {'category': ?category});
    final data = res.data['data'];
    if (data == null) return null;
    return JournalPrompt.fromJson(data as Map<String, dynamic>);
  }

  Future<List<JournalPrompt>> getAllPrompts() async {
    final res = await _dio.get('/journal/prompts');
    return (res.data['data'] as List)
        .map((e) => JournalPrompt.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Streak & Insights ─────────────────────────────────────────────────────────

  Future<JournalStreak?> getStreak() async {
    final res = await _dio.get('/journal/streak');
    final data = res.data['data'];
    if (data == null) return null;
    return JournalStreak.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getMoodWeather({int months = 3}) async {
    final res = await _dio.get('/journal/mood-weather', queryParameters: {'months': months});
    return Map<String, dynamic>.from(res.data['data'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> getTimeCapsules() async {
    final res = await _dio.get('/journal/time-capsules');
    return Map<String, dynamic>.from(res.data['data'] as Map? ?? {});
  }

  Future<List<JournalEntry>> getOnThisDay() async {
    final res = await _dio.get('/journal/on-this-day');
    return (res.data['data'] as List)
        .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> shareEntryToCommunity({
    required String entryId,
    String? circleId,
    String? caption,
    bool isAnonymous = false,
  }) async {
    await _dio.post('/journal/entries/$entryId/share', data: {
      'circleId': ?circleId,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      'isAnonymous': isAnonymous,
    });
  }
}
