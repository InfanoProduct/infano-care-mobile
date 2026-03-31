import 'package:dio/dio.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

/// Result from verifyOtp — carries enough info to drive navigation.
class OtpVerifyResult {
  final String accessToken;
  final String refreshToken;
  final bool isNewUser;
  final int onboardingStep;
  final String accountStatus;
  final bool isOnboardingCompleted;

  OtpVerifyResult({
    required this.accessToken,
    required this.refreshToken,
    required this.isNewUser,
    required this.onboardingStep,
    required this.accountStatus,
    required this.isOnboardingCompleted,
  });
}

class AuthRepository {
  final Dio _dio;
  final LocalStorageService _storage;

  AuthRepository(this._storage) : _dio = ApiService.instance.dio;

  // ── Send OTP ────────────────────────────────────────────────────────────────
  Future<void> sendOtp(String phone) async {
    try {
      await _dio.post('/auth/otp/send', data: {'phone': phone});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to send OTP.');
    }
  }

  // ── Verify OTP ──────────────────────────────────────────────────────────────
  Future<OtpVerifyResult> verifyOtp(String phone, String otp) async {
    try {
      final resp = await _dio.post('/auth/otp/verify', data: {
        'phone': phone,
        'otp': otp,
      });
      final data = resp.data as Map<String, dynamic>;
      final result = OtpVerifyResult(
        accessToken:     data['accessToken']     as String,
        refreshToken:    data['refreshToken']    as String,
        isNewUser:       data['isNewUser']       as bool,
        onboardingStep: data['onboardingStep'] as int,
        accountStatus:   data['accountStatus']   as String,
        isOnboardingCompleted: data['isOnboardingCompleted'] as bool,
      );
      // Persist tokens and stage immediately
      await _storage.setAuthToken(result.accessToken);
      await _storage.setRefreshToken(result.refreshToken);
      await _storage.setPhone(phone);
      await _storage.setStepComplete(result.onboardingStep.toString());
      await _storage.setIsOnboarded(result.isOnboardingCompleted);
      
      // Clear legacy tempToken if present
      await _storage.clearTempToken();

      return result;
    } on DioException catch (e) {
      throw _extractError(e, 'OTP verification failed.');
    }
  }

  // ── Extract readable error message ──────────────────────────────────────────
  String _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return fallback;
  }
}
