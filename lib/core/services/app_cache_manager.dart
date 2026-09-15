import 'package:infano_care_mobile/models/chat_message.dart';
import 'package:infano_care_mobile/models/peerline_session.dart';
import 'package:infano_care_mobile/models/peerline_topic.dart';
import 'package:infano_care_mobile/features/courses/data/models/course_models.dart';

class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Centralized, high-performance in-memory cache manager.
/// Enables 0ms instant loading (Cache-First / Stale-While-Revalidate pattern).
class AppCacheManager {
  AppCacheManager._();
  static final AppCacheManager instance = AppCacheManager._();

  final Map<String, _CacheEntry<dynamic>> _cache = {};

  static const Duration defaultTtl = Duration(minutes: 30);
  static const Duration shortTtl = Duration(minutes: 5);
  static const Duration longTtl = Duration(hours: 2);

  // ── Generic Cache Operations ───────────────────────────────────────────────

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  void set<T>(String key, T data, {Duration ttl = defaultTtl}) {
    _cache[key] = _CacheEntry<T>(
      data: data,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  void invalidate(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  // ── My Inbox Aggregated List ───────────────────────────────────────────────

  List<dynamic>? getMyChats() => get<List<dynamic>>('my_chats_list');

  void setMyChats(List<dynamic> chats) => set<List<dynamic>>('my_chats_list', chats, ttl: shortTtl);

  // ── PeerLine Chat & Messages ───────────────────────────────────────────────

  List<ChatMessage>? getPeerLineMessages(String sessionId) =>
      get<List<ChatMessage>>('peerline_messages_$sessionId');

  void setPeerLineMessages(String sessionId, List<ChatMessage> messages) =>
      set<List<ChatMessage>>('peerline_messages_$sessionId', List.from(messages), ttl: defaultTtl);

  PeerLineSession? getPeerLineSession(String sessionId) =>
      get<PeerLineSession>('peerline_session_$sessionId');

  void setPeerLineSession(String sessionId, PeerLineSession session) =>
      set<PeerLineSession>('peerline_session_$sessionId', session, ttl: defaultTtl);

  // ── Expert Chat Messages ───────────────────────────────────────────────────

  List<Map<String, dynamic>>? getExpertMessages(String sessionId) =>
      get<List<Map<String, dynamic>>>('expert_messages_$sessionId');

  void setExpertMessages(String sessionId, List<Map<String, dynamic>> messages) =>
      set<List<Map<String, dynamic>>>('expert_messages_$sessionId', List.from(messages), ttl: defaultTtl);

  // ── Friend Chat Messages ───────────────────────────────────────────────────

  List<Map<String, dynamic>>? getFriendMessages(String matchId) =>
      get<List<Map<String, dynamic>>>('friend_messages_$matchId');

  void setFriendMessages(String matchId, List<Map<String, dynamic>> messages) =>
      set<List<Map<String, dynamic>>>('friend_messages_$matchId', List.from(messages), ttl: defaultTtl);

  // ── Gigi Assistant Chat ────────────────────────────────────────────────────

  List<dynamic>? getGigiHistory(String sessionId) =>
      get<List<dynamic>>('gigi_history_$sessionId');

  void setGigiHistory(String sessionId, List<dynamic> history) =>
      set<List<dynamic>>('gigi_history_$sessionId', List.from(history), ttl: defaultTtl);

  List<dynamic>? getGigiSessions() => get<List<dynamic>>('gigi_sessions');

  void setGigiSessions(List<dynamic> sessions) =>
      set<List<dynamic>>('gigi_sessions', List.from(sessions), ttl: shortTtl);

  void clearGigiCache() {
    _cache.removeWhere((key, _) => key.startsWith('gigi_'));
  }

  // ── Home Screen Content (Articles, Mentors, Topics, Courses) ───────────────

  List<Map<String, dynamic>>? getArticles() =>
      get<List<Map<String, dynamic>>>('home_articles_list');

  void setArticles(List<Map<String, dynamic>> articles) =>
      set<List<Map<String, dynamic>>>('home_articles_list', articles, ttl: longTtl);

  List<Map<String, dynamic>>? getGoodToKnowArticles() => getArticles();

  void setGoodToKnowArticles(List<Map<String, dynamic>> articles) =>
      setArticles(articles);

  List<PeerLineTopic>? getPeerTopics() =>
      get<List<PeerLineTopic>>('home_peer_topics');

  void setPeerTopics(List<PeerLineTopic> topics) =>
      set<List<PeerLineTopic>>('home_peer_topics', topics, ttl: longTtl);

  List<Map<String, dynamic>>? getPeerMentors() =>
      get<List<Map<String, dynamic>>>('home_peer_mentors');

  void setPeerMentors(List<Map<String, dynamic>> mentors) =>
      set<List<Map<String, dynamic>>>('home_peer_mentors', mentors, ttl: shortTtl);

  List<LmsEnrollment>? getEnrolledCourses() =>
      get<List<LmsEnrollment>>('my_enrolled_courses');

  void setEnrolledCourses(List<LmsEnrollment> courses) =>
      set<List<LmsEnrollment>>('my_enrolled_courses', courses, ttl: shortTtl);

  List<LmsEnrollment>? getMyCourses() => getEnrolledCourses();

  void setMyCourses(List<LmsEnrollment> courses) => setEnrolledCourses(courses);

  // ── LMS Course Details, Curriculum, Progress, & Explore ────────────────────

  LmsCourse? getCourseDetails(String courseId) =>
      get<LmsCourse>('lms_course_details_$courseId');

  void setCourseDetails(String courseId, LmsCourse course) =>
      set<LmsCourse>('lms_course_details_$courseId', course, ttl: defaultTtl);

  List<LmsProgress>? getCourseProgress(String courseId) =>
      get<List<LmsProgress>>('lms_course_progress_$courseId');

  void setCourseProgress(String courseId, List<LmsProgress> progress) =>
      set<List<LmsProgress>>('lms_course_progress_$courseId', List.from(progress), ttl: defaultTtl);

  void updateChapterProgress(String courseId, String chapterId, LmsProgress newProgress) {
    final current = getCourseProgress(courseId) ?? [];
    final updated = List<LmsProgress>.from(current);
    final idx = updated.indexWhere((p) => p.chapterId == chapterId);
    if (idx >= 0) {
      updated[idx] = newProgress;
    } else {
      updated.add(newProgress);
    }
    setCourseProgress(courseId, updated);
  }

  List<LmsCourse>? getExploreCourses() =>
      get<List<LmsCourse>>('lms_explore_courses');

  void setExploreCourses(List<LmsCourse> courses) =>
      set<List<LmsCourse>>('lms_explore_courses', List.from(courses), ttl: defaultTtl);
}
