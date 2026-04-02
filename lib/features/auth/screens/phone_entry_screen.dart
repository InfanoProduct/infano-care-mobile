import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/auth/repository/auth_repository.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/shared/widgets/permissions_onboarding_sheet.dart';
import 'package:infano_care_mobile/core/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_autofill/sms_autofill.dart';

class PhoneEntryScreen extends StatefulWidget {
  PhoneEntryScreen({super.key, required this.storage, this.fromOnboarding = false});
  final LocalStorageService storage;
  final bool fromOnboarding;

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _controller = TextEditingController();
  String _countryCode = '+91';
  bool _loading = false;
  String? _error;

  late final AuthRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = AuthRepository(widget.storage);
    _checkPermissions();
  }

  Future<void> _showPhoneHint() async {
    try {
      final String? result = await SmsAutoFill().hint;
      if (result != null && mounted) {
        // Hint returns full number with code, e.g. +919000000000
        // We extract the digits (last 10) and the rest as country code.
        final cleaned = result.replaceAll(' ', '').replaceAll('-', '');
        if (cleaned.length >= 10) {
          setState(() {
            _controller.text = cleaned.substring(cleaned.length - 10);
            _countryCode     = cleaned.substring(0, cleaned.length - 10);
          });
        }
      }
    } catch (e) {
      debugPrint('Phone hint error: $e');
    }
  }

  Future<void> _checkPermissions() async {
    // Info only: Show the sheet to explain the feature, but DON'T request system permissions.
    // The SMS User Consent API will handle the request properly when the SMS arrives.
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          PermissionsOnboardingSheet.show(
            context,
            onAllow: () => _showPhoneHint(), // Trigger native hint picker
            onDeny: () => {},  // Manual fallback
          );
        }
      });
    }
  }

  bool get _valid => _controller.text.length >= 10;

  Future<void> _sendOtp() async {
    setState(() { _loading = true; _error = null; });
    try {
      final phone = '$_countryCode${_controller.text.trim()}';
      await _repo.sendOtp(phone);
      if (mounted) {
        context.go('/auth/otp?phone=${Uri.encodeComponent(phone)}&fromOnboarding=${widget.fromOnboarding}');
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If from onboarding, wrap in OnboardingScaffold for progress bar
    if (widget.fromOnboarding) {
      return OnboardingScaffold(
        currentStep: 11,
        body: _buildBody(context),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Back button
            if (!widget.fromOnboarding)
              GestureDetector(
                onTap: () => context.go('/splash'),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textDark),
                ),
              ),
            const SizedBox(height: 32),
            Text('What\'s your number? 📱', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text('We\'ll send you a 4-digit code to verify. No password needed!', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 40),
            Row(
              children: [
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5)),
                    child: Text('$_countryCode 🔽', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textDark)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    maxLength: 12,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(counterText: '', hintText: '98765 43210'),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            const SizedBox(height: 48),
            AnimatedOpacity(
              opacity: _valid ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: _valid && !_loading ? _sendOtp : null,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(gradient: _valid ? AppGradients.brand : null, color: _valid ? null : AppColors.textLight, borderRadius: BorderRadius.circular(100)),
                  child: Center(
                    child: _loading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text('Send OTP 📲', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, duration: 400.ms),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['+91 🇮🇳 India', '+1 🇺🇸 USA', '+44 🇬🇧 UK', '+61 🇦🇺 Australia'].map((c) =>
            ListTile(
              title: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                setState(() => _countryCode = c.split(' ').first);
                Navigator.pop(context);
              },
            ),
          ).toList(),
        ),
      ),
    );
  }
}
