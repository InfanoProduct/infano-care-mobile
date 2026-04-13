import 'package:dio/dio.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

/// Result from verifyOtp — carries enough info to drive navigation.
class OtpVerifyResult {
  final String? accessToken;
  final String? refreshToken;
  final String tempToken;
  final bool isNewUser;
  final int onboardingStep;
  final String accountStatus;
  final bool isOnboardingCompleted;
  final String? role;
  final String? userId;

  OtpVerifyResult({
    this.accessToken,
    this.refreshToken,
    required this.tempToken,
    required this.isNewUser,
    required this.onboardingStep,
    required this.accountStatus,
    required this.isOnboardingCompleted,
    this.role,
    this.userId,
  });
}

/// Returned after a successful login for returning users.
class LoginResult {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final int onboardingStep;
  final String? role;

  LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.onboardingStep,
    this.role,
  });
}

class AuthRepository {
  final Dio _dio;
  final LocalStorageService _storage;

  AuthRepository(this._storage) : _dio = ApiService.instance.dio;

  // ── Send OTP ────────────────────────────────────────────────────────────────
  Future<void> sendOtp(String phone, {String? appHash}) async {
    try {
      await _dio.post('/auth/otp/send', data: {
        'phone': phone,
        if (appHash != null) 'appHash': appHash,
      });
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
        accessToken:           data['accessToken']           as String?,
        refreshToken:          data['refreshToken']          as String?,
        tempToken:             data['tempToken']             as String? ?? '',
        isNewUser:             data['isNewUser']             as bool? ?? false,
        onboardingStep:        data['onboardingStep']        as int? ?? 0,
        accountStatus:         data['accountStatus']         as String? ?? '',
        isOnboardingCompleted: data['isOnboardingCompleted'] as bool? ?? false,
        role:                  data['role']                  as String?,
        userId:                data['userId']                as String?,
      );
      
      // Persist tokens if available (returning user)
      if (result.accessToken != null) await _storage.setAuthToken(result.accessToken!);
      if (result.refreshToken != null) await _storage.setRefreshToken(result.refreshToken!);
      if (result.role != null) await _storage.setRole(result.role!);
      if (result.userId != null) await _storage.setUserId(result.userId!);
      
      // Always store tempToken and basic info
      await _storage.setTempToken(result.tempToken);
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

  // ── Login (returning user) ──────────────────────────────────────────────────
  Future<LoginResult> login(String tempToken) async {
    try {
      final resp = await _dio.post('/auth/login', data: {'tempToken': tempToken});
      final data = resp.data as Map<String, dynamic>;
      final result = LoginResult(
        accessToken:     data['accessToken']     as String,
        refreshToken:    data['refreshToken']    as String,
        userId:          data['userId']          as String,
        onboardingStep:  data['onboardingStep']  as int,
        role:            data['role']            as String?,
      );
      await _storage.setAuthToken(result.accessToken);
      await _storage.setRefreshToken(result.refreshToken);
      await _storage.setUserId(result.userId);
      await _storage.setStepComplete(result.onboardingStep.toString());
      if (result.role != null) await _storage.setRole(result.role!);
      return result;
    } on DioException catch (e) {
      throw _extractError(e, 'Login failed.');
    }
  }

  // ── Extract readable error message ──────────────────────────────────────────
  String _extractError(DioException e, String fallback) {
    // 1. Connection/Timeout errors
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please try again.';
    }

    // 2. Response errors from API
    final data = e.response?.data;
    if (data is Map) {
      final String? error = data['error']?.toString() ?? data['message']?.toString();
      if (error != null) {
        // Map specific API error strings to user-friendly ones if needed
        if (error.contains('Invalid OTP')) return 'Invalid code. Please check and try again.';
        if (error.contains('expired')) return 'The code has expired. Please request a new one.';
        if (error.contains('Too many')) return 'Too many attempts. Please try again later.';
        return error;
      }
    }

    return fallback;
  }
}
