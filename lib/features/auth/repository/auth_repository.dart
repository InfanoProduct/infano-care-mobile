import 'package:dio/dio.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

/// Result from verifyOtp — carries enough info to drive navigation.
class OtpVerifyResult {
  final String tempToken;
  final bool isNewUser;
  final int onboardingStage;
  final String accountStatus;
  final String? accessToken;
  final String? refreshToken;
  final String? role;
  final String? userId;

  OtpVerifyResult({
    required this.tempToken,
    required this.isNewUser,
    required this.onboardingStage,
    required this.accountStatus,
    this.accessToken,
    this.refreshToken,
    this.role,
    this.userId,
  });
}

/// Returned after a successful login for returning users.
class LoginResult {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final int onboardingStage;
  final String? role;

  LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.onboardingStage,
    this.role,
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
        tempToken:       data['tempToken']       as String,
        isNewUser:       data['isNewUser']       as bool,
        onboardingStage: data['onboardingStage'] as int,
        accountStatus:   data['accountStatus']   as String,
        accessToken:     data['accessToken']     as String?,
        refreshToken:    data['refreshToken']    as String?,
        role:            data['role']            as String?,
        userId:          data['userId']          as String?,
      );
      
      // Persist tokens if this is a returning user login
      if (result.accessToken != null) await _storage.setAuthToken(result.accessToken!);
      if (result.refreshToken != null) await _storage.setRefreshToken(result.refreshToken!);
      if (result.role != null) await _storage.setRole(result.role!);
      if (result.userId != null) await _storage.setUserId(result.userId!);
      
      await _storage.setTempToken(result.tempToken);
      await _storage.setPhone(phone);
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
        onboardingStage: data['onboardingStage'] as int,
        role:            data['role']            as String?,
      );
      await _storage.setAuthToken(result.accessToken);
      await _storage.setRefreshToken(result.refreshToken);
      await _storage.setUserId(result.userId);
      await _storage.setStageComplete(result.onboardingStage.toString());
      if (result.role != null) await _storage.setRole(result.role!);
      return result;
    } on DioException catch (e) {
      throw _extractError(e, 'Login failed.');
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
