import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:infano_care_mobile/core/services/permission_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/auth/repository/auth_repository.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({
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
    if (code != null && code!.isNotEmpty) {
      final digits = code!.replaceAll(RegExp(r'\D'), '');
      debugPrint("🔍 Parsed digits: '$digits'");
      if (digits.length == 4) {
        debugPrint("✨ Auto-filling 4-digit code: $digits");

        // Update controller
        _pinController.text = digits;

        setState(() {
          _otp = digits;
          _error = null;
        });

        // Delay briefly to allow the UI to display the digits before automatic navigation
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _countdown > 0) {
            _verify();
          }
        });
      }
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.verifyOtp(widget.phone, _otp);

      if (!mounted) return;

      // Route based on what the backend told us: role + onboardingCompleted
      if (result.isOnboardingCompleted) {
        context.go('/home');
        return;
      }

      // Not yet onboarded — set userType from role and go to onboarding
      final role = result.role ?? widget.storage.role;
      if (role != null) {
        widget.storage.setUserType(role.toLowerCase());
        context.go('/onboarding/name');
      } else {
        // Truly new user with no role yet — show path selector
        context.go('/onboarding/path');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _countdown = 60;
      _error = null;
    });
    _startCooldown();
    try {
      listenForCode();
      final signature = await SmsAutoFill().getAppSignature;
      debugPrint("📤 Resending OTP... Hash: $signature");
      await _repo.sendOtp(widget.phone, appHash: signature);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
      body: SafeArea(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final sessionExpired = _countdown == 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (!widget.fromOnboarding)
                          GestureDetector(
                            onTap: () => context.go('/auth/phone'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.purple.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textDark),
                            ),
                          )
                        else
                          const SizedBox(width: 44),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_rounded, size: 14, color: AppColors.purple),
                              SizedBox(width: 6),
                              Text(
                                'Secure Verification',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 1),
                    const SizedBox(height: 12),

                    // Hero Emblem
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFEDE9FE), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🔐', style: TextStyle(fontSize: 40)),
                        ),
                      ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.easeOutBack),
                    ),

                    const SizedBox(height: 20),

                    // Title & Phone info chip
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Enter Verification Code 📲',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Code sent to ',
                                style: TextStyle(fontSize: 14, color: AppColors.textMedium),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.phone,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.only(left: 4),
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.purple),
                                onPressed: () => context.go('/auth/phone'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, duration: 400.ms),

                    const SizedBox(height: 24),
                    const Spacer(flex: 1),

                    // OTP Input Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFEDE9FE), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.07),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          PinCodeTextField(
                            appContext: context,
                            length: 4,
                            animationType: AnimationType.scale,
                            textStyle: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(16),
                              fieldHeight: 64,
                              fieldWidth: 56,
                              activeFillColor: Colors.white,
                              inactiveFillColor: const Color(0xFFFAF5FF),
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
                            onChanged: (v) => setState(() {
                              _otp = v;
                              _error = null;
                            }),
                            onCompleted: (_) => _verify(),
                          ),
                          const SizedBox(height: 10),

                          // Auto-detect banner
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _otp.isEmpty && _countdown > 40
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3E8FF).withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Waiting for auto-SMS detection...',
                                          style: TextStyle(
                                            color: AppColors.purple,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Verify CTA Button
                          InkWell(
                            onTap: _otp.length == 4 && !_loading && !sessionExpired ? _verify : null,
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              constraints: const BoxConstraints(minHeight: 54),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: (_otp.length == 4 && !sessionExpired)
                                    ? const LinearGradient(
                                        colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      )
                                    : null,
                                color: (_otp.length == 4 && !sessionExpired) ? null : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: (_otp.length == 4 && !sessionExpired)
                                    ? [
                                        BoxShadow(
                                          color: AppColors.purple.withValues(alpha: 0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: _loading
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Verifying...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'Verify & Continue',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.check_circle_outline_rounded, size: 20, color: Colors.white),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, duration: 350.ms),

                    const SizedBox(height: 24),
                    const Spacer(flex: 2),

                    // Resend Section
                    Center(
                      child: _countdown > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFEDE9FE)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.textMedium),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Resend code in ${_countdown}s',
                                    style: const TextStyle(
                                      color: AppColors.textMedium,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : TextButton.icon(
                              onPressed: _resendOtp,
                              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.purple),
                              label: const Text(
                                'Resend OTP Code',
                                style: TextStyle(
                                  color: AppColors.purple,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

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
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
