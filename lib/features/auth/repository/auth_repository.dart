import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
  final String? contentTier;
  final Map<String, dynamic>? profile;

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
    this.contentTier,
    this.profile,
  });
}

/// Returned after a successful login for returning users.
class LoginResult {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final int onboardingStep;
  final String? role;
  final String? contentTier;
  final Map<String, dynamic>? profile;

  LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.onboardingStep,
    this.role,
    this.contentTier,
    this.profile,
  });
}

class AuthRepository {
  final Dio _dio;
  final LocalStorageService _storage;

  AuthRepository(this._storage) : _dio = ApiService.instance.dio;

  // ── Send OTP ────────────────────────────────────────────────────────────────
  Future<OtpVerifyResult?> sendOtp(String phone, {String? appHash}) async {
    try {
      final resp = await _dio.post('/auth/otp/send', data: {
        'phone': phone,
        if (appHash != null) 'appHash': appHash,
      });

      final data = resp.data as Map<String, dynamic>;
      if (data.containsKey('autoLogin') && data['autoLogin'] != null) {
        final loginData = data['autoLogin'] as Map<String, dynamic>;
        final result = OtpVerifyResult(
          tempToken:             loginData['tempToken']             as String? ?? '',
          isNewUser:             loginData['isNewUser']             as bool? ?? false,
          onboardingStep:        loginData['onboardingStep']        as int? ?? 0,
          accountStatus:         loginData['accountStatus']         as String? ?? '',
          isOnboardingCompleted: loginData['isOnboardingCompleted'] as bool? ?? false,
          accessToken:           loginData['accessToken']           as String?,
          refreshToken:          loginData['refreshToken']          as String?,
          role:                  loginData['role']                  as String?,
          userId:                loginData['userId']                as String?,
          contentTier:           loginData['contentTier']           as String?,
          profile:               loginData['profile']               as Map<String, dynamic>?,
        );

        final isCompleted = result.isOnboardingCompleted ||
            (result.profile?['displayName'] != null && result.profile!['displayName'].toString().trim().isNotEmpty);

        await _storage.saveAuthSession(
          authToken: result.accessToken,
          refreshToken: result.refreshToken,
          role: result.role,
          userId: result.userId,
          phone: phone,
          isOnboarded: isCompleted,
          stepComplete: result.onboardingStep.toString(),
          displayName: result.profile?['displayName']?.toString(),
          pronouns: result.profile?['pronouns']?.toString(),
          birthMonth: result.profile?['birthMonth'] as int?,
          birthYear: result.profile?['birthYear'] as int?,
          totalPoints: result.profile?['totalPoints'] as int?,
          avatarUrl: result.profile?['avatarUrl']?.toString(),
          contentTier: result.contentTier,
        );

        return result;
      }
      return null;
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
        tempToken:             data['tempToken']             as String? ?? '',
        isNewUser:             data['isNewUser']             as bool? ?? false,
        onboardingStep:        data['onboardingStep']        as int? ?? 0,
        accountStatus:         data['accountStatus']         as String? ?? '',
        isOnboardingCompleted: data['isOnboardingCompleted'] as bool? ?? false,
        accessToken:           data['accessToken']           as String?,
        refreshToken:          data['refreshToken']          as String?,
        role:                  data['role']                  as String?,
        userId:                data['userId']                as String?,
        contentTier:           data['contentTier']           as String?,
        profile:               data['profile']               as Map<String, dynamic>?,
      );
      
      final isCompleted = result.isOnboardingCompleted ||
          (result.profile?['displayName'] != null && result.profile!['displayName'].toString().trim().isNotEmpty);

      await _storage.saveAuthSession(
        authToken: result.accessToken,
        refreshToken: result.refreshToken,
        role: result.role,
        userId: result.userId,
        phone: phone,
        isOnboarded: isCompleted,
        stepComplete: result.onboardingStep.toString(),
        displayName: result.profile?['displayName']?.toString(),
        pronouns: result.profile?['pronouns']?.toString(),
        birthMonth: result.profile?['birthMonth'] as int?,
        birthYear: result.profile?['birthYear'] as int?,
        totalPoints: result.profile?['totalPoints'] as int?,
        avatarUrl: result.profile?['avatarUrl']?.toString(),
        contentTier: result.contentTier,
      );

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
        contentTier:     data['contentTier']     as String?,
        profile:         data['profile']         as Map<String, dynamic>?,
      );
      await _storage.setAuthToken(result.accessToken);
      await _storage.setRefreshToken(result.refreshToken);
      await _storage.setUserId(result.userId);
      await _storage.setStepComplete(result.onboardingStep.toString());
      if (result.role != null) await _storage.setRole(result.role!);
      
      // Sync profile details if present
      if (result.contentTier != null) await _storage.setContentTier(result.contentTier!);
      if (result.profile != null) {
        final p = result.profile!;
        if (p['displayName'] != null && p['displayName'].toString().trim().isNotEmpty) {
          await _storage.setDisplayName(p['displayName']);
        }
        if (p['pronouns'] != null) await _storage.setPronouns(p['pronouns']);
        if (p['birthYear'] != null) await _storage.setBirthDate(p['birthMonth'] ?? 1, p['birthYear']);
        if (p['totalPoints'] != null) await _storage.setPoints(p['totalPoints']);
        await _storage.setAvatarUrl(p['avatarUrl']?.toString());
      }
      
      return result;
    } on DioException catch (e) {
      throw _extractError(e, 'Login failed.');
    }
  }

  // ── Sync Profile (from /user/me) ──────────────────────────────────────────
  Future<void> syncProfile() async {
    try {
      final resp = await _dio.get('/user/me');
      final data = resp.data as Map<String, dynamic>;
      debugPrint('[syncProfile] Raw API Response from /user/me: $data');
      
      final contentTier = data['contentTier'] as String?;
      final profile = data['profile'] as Map<String, dynamic>?;
      final role = data['role'] as String?;

      if (role != null) await _storage.setRole(role);
      if (contentTier != null) await _storage.setContentTier(contentTier);
      
      if (profile != null) {
        if (profile['displayName'] != null && profile['displayName'].toString().trim().isNotEmpty) {
          await _storage.setDisplayName(profile['displayName']);
        }
        if (profile['pronouns'] != null) await _storage.setPronouns(profile['pronouns']);
        if (profile['birthYear'] != null) {
          await _storage.setBirthDate(profile['birthMonth'] ?? 1, profile['birthYear']);
        }
        if (profile['totalPoints'] != null) await _storage.setPoints(profile['totalPoints']);
        await _storage.setAvatarUrl(profile['avatarUrl']?.toString());
      }
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to sync profile.');
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
