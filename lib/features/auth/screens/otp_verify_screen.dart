import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/core/services/permission_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/auth/repository/auth_repository.dart';
import 'package:infano_care_mobile/core/router/app_router.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';

class OtpVerifyScreen extends StatefulWidget {
  OtpVerifyScreen({
    super.key,
    required this.phone,
    required this.storage,
    this.fromOnboarding = false,
  });
  final String phone;
  final LocalStorageService storage;
  final bool fromOnboarding;

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> with CodeAutoFill {
  String _otp = '';
  bool _loading = false;
  String? _error;
  int _countdown = 60;

  late final AuthRepository _repo;
  late final TextEditingController _pinController;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
    _repo = AuthRepository(widget.storage);
    _startCooldown();
    
    // Production Grade: Start the SMS Auto-fill listening
    _initSmsAutoFill();
  }

  Future<void> _initSmsAutoFill() async {
    // 1. Silent Retriever API (needs hash)
    listenForCode(); 
    
    // 2. User Consent API Fallback (shows a popup, no hash needed)
    // We delay this briefly to let the silent one try first
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _otp.isEmpty) {
        debugPrint("📡 Starting SMS User Consent API fallback...");
        PermissionService.instance.startSmsUserConsent();
      }
    });
    
    final signature = await SmsAutoFill().getAppSignature;
    debugPrint("🚀 App Signature for SMS Retriever: $signature");
  }

  @override
  void codeUpdated() {
    debugPrint("📬 SMS Received signal detected! Raw property 'code': $code");
    // SMS Auto-fill mixin 'code' property gets populated
    if (code != null && code!.isNotEmpty) {
      final digits = code!.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 4) {
        debugPrint("✨ Auto-filling 4-digit code: $digits");
        _pinController.text = digits;
        setState(() {
          _otp = digits;
          _error = null;
        });
        // Auto-verify if session is not expired
        if (!context.read<OnboardingBloc>().state.sessionExpired) {
          _verify();
        }
      }
    } else {
      debugPrint("⚠️ Signal detected but code is null or empty. Check hash match.");
    }
  }

  @override
  void dispose() {
    cancel(); // Stop listening
    _pinController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown = (_countdown - 1).clamp(0, 60));
      return _countdown > 0;
    });
  }

  Future<void> _verify() async {
    if (_otp.length < 4) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _repo.verifyOtp(widget.phone, _otp);

      if (!mounted) return;

      // Resumption Logic:
      if (result.onboardingStep == 0) {
        // Brand new user: Start at path selection
        final bloc = context.read<OnboardingBloc>();
        bloc.add(SetPhone(widget.phone));
        if (mounted) context.go('/onboarding/path');
      } else {
        // Returning or partially onboarded user:
        // Use the centralized helper to find the target route
        final target = getRouteForStep(
          result.onboardingStep.toString(), 
          periodStatus: widget.storage.periodStatus,
        );
        debugPrint('🚀 OTP Verified. Navigating directly to: $target');
        if (mounted) context.go(target);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() { _countdown = 60; _error = null; });
    _startCooldown();
    try {
      // Production Grade: Re-listen for the new SMS code
      listenForCode(); 
      
      final signature = await SmsAutoFill().getAppSignature;
      debugPrint("📤 Resending OTP... Hash: $signature");
      
      await _repo.sendOtp(widget.phone, appHash: signature);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fromOnboarding) {
      return OnboardingScaffold(
        currentStep: 12,
        body: _buildBody(context),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final rawPhone = widget.phone.replaceAll(' ', '');
    final maskedPhone = rawPhone.length > 6
      ? '${rawPhone.substring(0, rawPhone.length - 4).replaceAll(RegExp(r'\d'), '*')}${rawPhone.substring(rawPhone.length - 4)}' 
      : rawPhone;

    return BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              if (!widget.fromOnboarding)
                GestureDetector(
                  onTap: () => context.go('/auth/phone'),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textDark),
                  ),
                ),
              const SizedBox(height: 32),
              Text('Verify it\'s you 🔐', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Code sent to ', style: Theme.of(context).textTheme.bodyLarge),
                  Text(widget.phone, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.purple)),
                ],
              ),
              const SizedBox(height: 48),
              PinCodeTextField(
                appContext: context,
                length: 4,
                animationType: AnimationType.scale,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box, 
                  borderRadius: BorderRadius.circular(16),
                  fieldHeight: 64, fieldWidth: 54,
                  activeFillColor: Colors.white, 
                  inactiveFillColor: AppColors.surfaceCard,
                  selectedFillColor: Colors.white, 
                  activeColor: AppColors.purple,
                  inactiveColor: const Color(0xFFE9D5FF), 
                  selectedColor: AppColors.purple,
                  borderWidth: 2,
                ),
                cursorColor: AppColors.purple,
                enableActiveFill: true,
                keyboardType: TextInputType.number,
                controller: _pinController,
                onChanged: (v) => setState(() { _otp = v; _error = null; }),
                onCompleted: (_) => _verify(),
              ),
              const SizedBox(height: 12),
              // Hint/Status for Auto-fill
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _otp.isEmpty && _countdown > 45
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple)),
                          SizedBox(width: 8),
                          Text('Waiting for SMS...', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                        ],
                      )
                    : const SizedBox.shrink(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.2))),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Center(
                child: _countdown > 0
                  ? Text('Resend code in ${_countdown}s', style: const TextStyle(color: AppColors.textLight))
                  : TextButton(
                      onPressed: _resendOtp, 
                      child: const Text('Resend OTP 📩', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: _otp.length == 4 && !_loading && !state.sessionExpired ? _verify : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: (_otp.length == 4 && !state.sessionExpired) ? AppGradients.brand : null, 
                    color: (_otp.length == 4 && !state.sessionExpired) ? null : AppColors.textLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: (_otp.length == 4) ? [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
                  ),
                  child: Center(
                    child: _loading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Verifying...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
                        )
                      : const Text('Verify & Continue ✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (kDebugMode)
                Center(
                  child: FutureBuilder<String?>(
                    future: SmsAutoFill().getAppSignature,
                    builder: (context, snapshot) {
                      return Opacity(
                        opacity: 0.4,
                        child: Text(
                          'Debug Hash: ${snapshot.data ?? "..."}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      );
    });
  }
}
