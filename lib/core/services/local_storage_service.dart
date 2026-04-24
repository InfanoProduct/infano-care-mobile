import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Typed wrapper around SharedPreferences for onboarding state persistence.
class LocalStorageService extends ChangeNotifier {
  static const _userType       = 'ob_user_type';
  static const _displayName    = 'ob_display_name';
  static const _pronouns       = 'ob_pronouns';
  static const _role           = 'user_role';
  static const _points         = 'ob_points';
  static const _stepComplete   = 'ob_step_complete';
  static const _personalization = 'ob_personalization';
  static const _avatar         = 'ob_avatar';
  static const _journeyName    = 'ob_journey_name';
  static const _trackerSetup   = 'ob_tracker_setup';
  static const _authToken      = 'auth_token';
  static const _refreshToken   = 'refresh_token';
  static const _userId         = 'user_id';
  static const _phone          = 'user_phone';
  static const _tempToken      = 'auth_temp_token';
  static const _birthMonth     = 'ob_birth_month';
  static const _birthYear      = 'ob_birth_year';
  static const _termsAccepted   = 'ob_terms_accepted';
  static const _privacyAccepted = 'ob_privacy_accepted';
  static const _marketingOptIn  = 'ob_marketing_opt_in';
  static const _isOnboarded     = 'ob_is_onboarded';
  static const _periodStatus    = 'ob_period_status';
  static const _calendarVisited = 'ob_calendar_visited';
  static const _contentTier     = 'user_content_tier';
  static const _savedArticles   = 'saved_articles_list';
  static const _predictionBannerDismissedAt = 'ob_prediction_banner_dismissed_at';

  final SharedPreferences _prefs;
  LocalStorageService(this._prefs);

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // ── Onboarding step checkpoints ──────────────────────────────────────────
  String? get stepComplete      => _prefs.getString(_stepComplete);
  Future<void> setStepComplete(String step) async {
    await _prefs.setString(_stepComplete, step);
    notifyListeners();
  }

  bool get isOnboarded => _prefs.getBool(_isOnboarded) ?? false;
  Future<void> setIsOnboarded(bool value) async {
    await _prefs.setBool(_isOnboarded, value);
    notifyListeners();
  }

  // ── Identity ──────────────────────────────────────────────────────────────
  String? get userType          => _prefs.getString(_userType);
  String? get displayName       => _prefs.getString(_displayName);
  String? get pronouns          => _prefs.getString(_pronouns);
  String? get phone             => _prefs.getString(_phone);
  String? get role              => _prefs.getString(_role);
  String? get contentTier       => _prefs.getString(_contentTier);

  Future<void> setUserType(String t) async {
    await _prefs.setString(_userType, t);
    notifyListeners();
  }
  Future<void> setDisplayName(String n) async {
    await _prefs.setString(_displayName, n);
    notifyListeners();
  }
  Future<void> setPronouns(String? p) async {
    if (p != null) await _prefs.setString(_pronouns, p);
    else await _prefs.remove(_pronouns);
    notifyListeners();
  }
  Future<void> setPhone(String p) async {
    await _prefs.setString(_phone, p);
    notifyListeners();
  }
  Future<void> setRole(String r) async {
    await _prefs.setString(_role, r);
    notifyListeners();
  }
  Future<void> setContentTier(String tier) async {
    await _prefs.setString(_contentTier, tier);
    notifyListeners();
  }

  String? get periodStatus      => _prefs.getString(_periodStatus);
  Future<void> setPeriodStatus(String s) async {
    await _prefs.setString(_periodStatus, s);
    notifyListeners();
  }

  // ── Points ────────────────────────────────────────────────────────────────
  int get points                => _prefs.getInt(_points) ?? 0;
  Future<void> addPoints(int n) => _prefs.setInt(_points, points + n);
  Future<void> setPoints(int n) => _prefs.setInt(_points, n);

  // ── Auth ──────────────────────────────────────────────────────────────────
  String? get authToken         => _prefs.getString(_authToken);
  String? get refreshToken      => _prefs.getString(_refreshToken);
  String? get userId            => _prefs.getString(_userId);

  Future<void> setAuthToken(String t) async {
    await _prefs.setString(_authToken, t);
    notifyListeners();
  }
  
  Future<void> setRefreshToken(String t) async {
    await _prefs.setString(_refreshToken, t);
    notifyListeners();
  }

  Future<void> setUserId(String id) async {
    await _prefs.setString(_userId, id);
    notifyListeners();
  }

  String? get tempToken                  => _prefs.getString(_tempToken);
  Future<void> setTempToken(String t)    => _prefs.setString(_tempToken, t);
  Future<void> clearTempToken()          => _prefs.remove(_tempToken);

  int? get birthMonth                   => _prefs.getInt(_birthMonth);
  int? get birthYear                    => _prefs.getInt(_birthYear);
  bool get termsAccepted                => _prefs.getBool(_termsAccepted)   ?? false;
  bool get privacyAccepted              => _prefs.getBool(_privacyAccepted) ?? false;
  bool get marketingOptIn               => _prefs.getBool(_marketingOptIn)  ?? false;

  Future<void> setBirthDate(int m, int y) async {
    await _prefs.setInt(_birthMonth, m);
    await _prefs.setInt(_birthYear, y);
  }
  Future<void> setConsents({bool? terms, bool? privacy, bool? marketing}) async {
    if (terms != null)     await _prefs.setBool(_termsAccepted, terms);
    if (privacy != null)   await _prefs.setBool(_privacyAccepted, privacy);
    if (marketing != null) await _prefs.setBool(_marketingOptIn, marketing);
  }

  Future<void> clearAuthTokens() async {
    await _prefs.remove(_authToken);
    await _prefs.remove(_refreshToken);
    await _prefs.remove(_tempToken);
    notifyListeners();
  }

  /// Clears tokens and resets progress flags to force a fresh login/sync
  Future<void> clearSession() async {
    await clearAuthTokens();
    await _prefs.remove(_stepComplete);
    await _prefs.remove(_isOnboarded);
    // Note: We keep displayName/phone for 'Welcome Back' UI, 
    // but the app will force login because tokens are gone.
    notifyListeners();
  }

  // ── Clear all onboarding state ────────────────────────────────────────────
  Future<void> clearAll() async {
    await _prefs.clear();
    notifyListeners();
  }

  // ── Calendar ──────────────────────────────────────────────────────────────
  bool get hasCalendarVisited => _prefs.getBool(_calendarVisited) ?? false;
  Future<void> setCalendarVisited(bool value) async {
    await _prefs.setBool(_calendarVisited, value);
    notifyListeners();
  }

  // ── Prediction Banner ─────────────────────────────────────────────────────
  bool get isPredictionBannerDismissedToday {
    final dismissedAtStr = _prefs.getString(_predictionBannerDismissedAt);
    if (dismissedAtStr == null) return false;
    final dismissedAt = DateTime.tryParse(dismissedAtStr);
    if (dismissedAt == null) return false;
    
    final now = DateTime.now();
    return dismissedAt.year == now.year && 
           dismissedAt.month == now.month && 
           dismissedAt.day == now.day;
  }

  Future<void> setPredictionBannerDismissed() async {
    await _prefs.setString(_predictionBannerDismissedAt, DateTime.now().toIso8601String());
    notifyListeners();
  }

  // ── Streak Animation Persistence ──────────────────────────────────────────

  /// Check if a 7-day streak row has already played its animation.
  /// [weekKey] should be in the format `streak_row_animated_YYYY-MM-DD`.
  bool isWeekStreakAnimated(String weekKey) =>
      _prefs.getBool('streak_animated_$weekKey') ?? false;

  /// Mark a 7-day streak row as animated.
  Future<void> setWeekStreakAnimated(String weekKey) async {
    await _prefs.setBool('streak_animated_$weekKey', true);
    notifyListeners();
  }

  // ── Saved Articles ────────────────────────────────────────────────────────
  List<String> get savedArticles => _prefs.getStringList(_savedArticles) ?? [];

  bool isArticleSaved(String title) => savedArticles.contains(title);

  Future<void> toggleSavedArticle(String title) async {
    final current = savedArticles.toList();
    if (current.contains(title)) {
      current.remove(title);
    } else {
      current.add(title);
    }
    await _prefs.setStringList(_savedArticles, current);
    notifyListeners();
  }
}
