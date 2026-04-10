import 'package:infano_care_mobile/core/services/api_service.dart';

class OnboardingRepository {
  final ApiService _api;
  OnboardingRepository(this._api);

  // ── Auth ──────────────────────────────────────────────────────────────────────
  Future<void> sendOtp(String phone) async {
    await _api.dio.post('/auth/otp/send', data: {'phone': phone});
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final res = await _api.dio.post('/auth/otp/verify', data: {'phone': phone, 'otp': otp});
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> setupProfile({
    required String displayName,
    required int birthMonth,
    required int birthYear,
    required bool termsAccepted,
    required bool privacyAccepted,
    bool marketingOptIn = false,
    String locale = 'en-IN',
    String timezone = 'Asia/Kolkata',
  }) async {
    final res = await _api.dio.post('/onboarding/profile', data: {
      'displayName':    displayName,
      'birthMonth':     birthMonth,
      'birthYear':      birthYear,
      'termsAccepted':  termsAccepted,
      'privacyAccepted': privacyAccepted,
      'marketingOptIn': marketingOptIn,
      'locale':         locale,
      'timezone':       timezone,
    });
    return Map<String, dynamic>.from(res.data);
  }

  // ── Consent ───────────────────────────────────────────────────────────────────
  Future<void> sendConsentEmail(String parentEmail) async {
    await _api.dio.post('/auth/consent/send', data: {'parentEmail': parentEmail});
  }

  Future<String> getConsentStatus() async {
    final res = await _api.dio.get('/auth/consent/status');
    return res.data['status'] as String;
  }

  // ── Onboarding ────────────────────────────────────────────────────────────────
  Future<void> updateStage(int stage) async {
    await _api.dio.patch('/user/onboarding-step', data: {'step': stage});
  }

  Future<Map<String, dynamic>> savePersonalization({
    required List<String> goals,
    required int periodComfortScore,
    required String periodStatus,
    required List<String> interestTopics,
  }) async {
    final res = await _api.dio.post('/onboarding/personalization', data: {
      'goals':              goals,
      'periodComfortScore': periodComfortScore,
      'periodStatus':       periodStatus,
      'interestTopics':     interestTopics,
    });
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> saveAvatar(Map<String, dynamic> avatarData) async {
    await _api.dio.post('/onboarding/avatar', data: avatarData);
  }

  Future<Map<String, dynamic>> saveJourneyName(String name) async {
    final res = await _api.dio.post('/onboarding/journey-name', data: {'journeyName': name});
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> completeOnboarding() async {
    await _api.dio.post('/onboarding/complete');
  }

  // ── Tracker ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> trackerSetup({
    String? lastPeriodStart,
    String? lastPeriodEnd,
    required int periodLengthDays,
    required int cycleLengthDays,
    required String trackerMode,
    bool periodLengthEstimated = false,
    bool cycleLengthEstimated  = false,
  }) async {
    final res = await _api.dio.post('/tracker/setup', data: {
      'lastPeriodStart':       lastPeriodStart,
      'lastPeriodEnd':         lastPeriodEnd,
      'periodLengthDays':      periodLengthDays,
      'cycleLengthDays':       cycleLengthDays,
      'trackerMode':           trackerMode,
      'periodLengthEstimated': periodLengthEstimated,
      'cycleLengthEstimated':  cycleLengthEstimated,
    });
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> updateStep(int? step) async {
    if (step == null) return;
    try {
      await _api.dio.patch('/user/onboarding-step', data: {'step': step});
    } catch (_) {
      // Ignore errors for now; mostly needed for compilation
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _api.dio.get('/user/me');
    return Map<String, dynamic>.from(res.data);
  }
}
