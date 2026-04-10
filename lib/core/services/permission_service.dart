import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_autofill/sms_autofill.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  /// Comprehensive check and request for a permission with custom UI handling.
  /// Returns true if granted, false otherwise.
  Future<bool> requestPermission(
    BuildContext context, 
    Permission permission, {
    required String title,
    required String message,
  }) async {
    final status = await permission.status;

    if (status.isPermanentlyDenied) {
      if (context.mounted) await _showSettingsDialog(context, title, message);
      return false;
    }

    if (status.isDenied) {
      final result = await permission.request();
      return result.isGranted;
    }

    return status.isGranted;
  }

  /// Specialized for Notification (Critical for FCM)
  Future<bool> requestNotifications(BuildContext context) async {
    return requestPermission(
      context, 
      Permission.notification,
      title: 'Enable Notifications 🔔',
      message: 'To keep you updated on your journey and period alerts, please enable notifications in settings.',
    );
  }

  /// Specialized for SMS (Helper for Auto-fill)
  /// Note: Not strictly required for the SMS User Consent API but improves reliability on some devices.
  Future<bool> requestSms(BuildContext context) async {
    return requestPermission(
      context, 
      Permission.sms,
      title: 'Enable SMS Auto-fill 📲',
      message: 'To automatically pick up your verification code, please allow Infano to read SMS messages.',
    );
  }

  /// Explicitly start the SMS User Consent API (shows a 'Allow' popup)
  Future<void> startSmsUserConsent() async {
    try {
      await SmsAutoFill().listenForCode();
    } catch (e) {
      debugPrint('SMS User Consent error: $e');
    }
  }

  /// Get the App Signature required for Android SMS Retriever API
  Future<String?> getAppSignature() async {
    try {
      return await SmsAutoFill().getAppSignature;
    } catch (e) {
      return null;
    }
  }

  Future<void> _showSettingsDialog(BuildContext context, String title, String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
