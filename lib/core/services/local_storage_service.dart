import 'package:shared_preferences/shared_preferences.dart';

/// Typed wrapper around SharedPreferences for onboarding state persistence.
class LocalStorageService {
  static const _userType       = 'ob_user_type';
  static const _displayName    = 'ob_display_name';
  static const _pronouns       = 'ob_pronouns';
  static const _points         = 'ob_points';
  static const _stageComplete  = 'ob_stage_complete';
  static const _personalization = 'ob_personalization';
  static const _avatar         = 'ob_avatar';
  static const _journeyName    = 'ob_journey_name';
  static const _trackerSetup   = 'ob_tracker_setup';
  static const _authToken      = 'auth_token';
  static const _refreshToken   = 'refresh_token';
  static const _userId         = 'user_id';
  static const _phone          = 'user_phone';

  final SharedPreferences _prefs;
  LocalStorageService(this._prefs);

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // ── Onboarding stage checkpoints ─────────────────────────────────────────
  String? get stageComplete     => _prefs.getString(_stageComplete);
  Future<void> setStageComplete(String stage) => _prefs.setString(_stageComplete, stage);

  // ── Identity ──────────────────────────────────────────────────────────────
  String? get userType          => _prefs.getString(_userType);
  String? get displayName       => _prefs.getString(_displayName);
  String? get pronouns          => _prefs.getString(_pronouns);
  String? get phone             => _prefs.getString(_phone);

  Future<void> setUserType(String t)     => _prefs.setString(_userType, t);
  Future<void> setDisplayName(String n)  => _prefs.setString(_displayName, n);
  Future<void> setPronouns(String? p)    => p != null ? _prefs.setString(_pronouns, p) : _prefs.remove(_pronouns);
  Future<void> setPhone(String p)        => _prefs.setString(_phone, p);

  // ── Points ────────────────────────────────────────────────────────────────
  int get points                => _prefs.getInt(_points) ?? 0;
  Future<void> addPoints(int n) => _prefs.setInt(_points, points + n);
  Future<void> setPoints(int n) => _prefs.setInt(_points, n);

  // ── Auth ──────────────────────────────────────────────────────────────────
  String? get authToken         => _prefs.getString(_authToken);
  String? get refreshToken      => _prefs.getString(_refreshToken);
  String? get userId            => _prefs.getString(_userId);

  Future<void> setAuthToken(String t)    => _prefs.setString(_authToken, t);
  Future<void> setRefreshToken(String t) => _prefs.setString(_refreshToken, t);
  Future<void> setUserId(String id)      => _prefs.setString(_userId, id);

  // ── Clear all onboarding state ────────────────────────────────────────────
  Future<void> clearAll() => _prefs.clear();
}
