import 'package:permission_handler/permission_handler.dart';
import 'package:sms_autofill/sms_autofill.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  /// Check specifically for SMS User Consent capability.
  /// Note: This doesn't require a Manifest permission on modern Android.
  Future<bool> hasSmsPermission() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  /// Request SMS permission (Manifest based - only for older Android or specific needs).
  /// For SMS User Consent API, this is NOT strictly needed but good for "Silent" reading.
  Future<PermissionStatus> requestSmsPermission() async {
    return await Permission.sms.request();
  }

  /// Get the App Signature required for Android SMS Retriever API
  Future<String?> getAppSignature() async {
    try {
      return await SmsAutoFill().getAppSignature;
    } catch (e) {
      return null;
    }
  }

  /// Comprehensive check for all "Phone Basic" permissions
  Future<Map<Permission, PermissionStatus>> requestAllBasicPermissions() async {
    return await [
      Permission.sms,
      // Permission.phone, // Recommended only if needed for carrier/number info
    ].request();
  }

  /// Open App Settings if permission is permanently denied
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
