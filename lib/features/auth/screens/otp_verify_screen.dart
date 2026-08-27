import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
      final isCompleted = result.isOnboardingCompleted ||
          (result.profile?['displayName'] != null && result.profile!['displayName'].toString().trim().isNotEmpty) ||
          result.role == 'EXPERT' ||
          result.role == 'ADMIN';

      if (isCompleted) {
        if (result.role == 'EXPERT') {
          context.go('/expert/dashboard');
        } else {
          context.go('/home');
        }
        return;
      }

      // Sync local storage role with backend response
      await widget.storage.setRole(result.role);
      await widget.storage.setUserType(result.role?.toLowerCase());

      if (!mounted) return;

      if (result.role != null) {
        context.go('/onboarding/name');
      } else {
        // Truly new user with no role set — show Path / Role Selector screen
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
      backgroundColor: const Color(0xFF8B7CD8),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 700;
    final isTablet = size.width >= 600 || size.height >= 1000;
    final horizontalPadding = isTablet ? 32.0 : (size.width < 360 ? 14.0 : 20.0);
    final topSpace = isTablet
        ? (size.height * 0.20).clamp(80.0, 220.0)
        : (isCompact ? 60.0 : (size.height * 0.14).clamp(80.0, 150.0));
    final pinFieldWidth = size.width < 360 ? 46.0 : (isTablet ? 64.0 : 54.0);
    final pinFieldHeight = size.width < 360 ? 48.0 : (isTablet ? 60.0 : 52.0);
    final sessionExpired = _countdown == 0;
    final canVerify = _otp.length == 4 && !_loading && !sessionExpired;

    return Stack(
      children: [
        // 1. 3D Background Illustration (Character visible)
        Positioned.fill(
          child: Image.asset(
            'assets/images/phone_entry_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),

        // 2. Subtle Soft Gradient Overlay for depth and clarity
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF5B21B6).withValues(alpha: 0.1),
                  const Color(0xFF2D1557).withValues(alpha: 0.35),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // 3. Back Button (Top Left)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: isTablet ? 32 : 16,
          child: GestureDetector(
            onTap: () {
              if (widget.fromOnboarding) {
                Navigator.of(context).maybePop();
              } else {
                context.go('/auth/phone');
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF5B21B6),
              ),
            ),
          ),
        ),

        // 4. Interactive Glassmorphic OTP Card (Responsive for all mobile & tablet dimensions)
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 480, // Max card width for tablets to prevent excessive stretching
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: topSpace,
                          ), // Leave top space so character girl is visible
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 28 : (size.width < 360 ? 16 : 22),
                              vertical: isCompact ? 20 : 26,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: 0.93,
                              ), // Premium glassmorphic white card
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4C1D95,
                                  ).withValues(alpha: 0.22),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 3D Lock/Shield Badge Icon
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFEDE9FE),
                                        Color(0xFFF5F3FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF6D28D9,
                                        ).withValues(alpha: 0.16),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.lock_person_rounded,
                                      size: 28,
                                      color: Color(0xFF6D28D9),
                                    ),
                                  ),
                                ).animate().scale(
                                  duration: 500.ms,
                                  curve: Curves.elasticOut,
                                ),

                                const SizedBox(height: 14),

                                // Title: Enter Verification Code 📲
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Enter Verification Code",
                                      style: GoogleFonts.nunito(
                                        fontSize: 19.5,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF2D1557),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '📲',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                // Subtitle & Phone Info
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Code sent to ',
                                      style: GoogleFonts.nunito(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6D28D9,
                                        ).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.phone,
                                        style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF5B21B6),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.go('/auth/phone'),
                                      child: const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Icon(
                                          Icons.edit_rounded,
                                          size: 16,
                                          color: Color(0xFF5B21B6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // 4-Digit Pin Input
                                PinCodeTextField(
                                  appContext: context,
                                  length: 4,
                                  animationType: AnimationType.scale,
                                  textStyle: GoogleFonts.nunito(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF111827),
                                  ),
                                  pinTheme: PinTheme(
                                    shape: PinCodeFieldShape.box,
                                    borderRadius: BorderRadius.circular(16),
                                    fieldHeight: pinFieldHeight,
                                    fieldWidth: pinFieldWidth,
                                    activeFillColor: const Color(0xFFF9FAFB),
                                inactiveFillColor: const Color(0xFFF3F4F6),
                                selectedFillColor: Colors.white,
                                activeColor: const Color(0xFF6D28D9),
                                inactiveColor: const Color(0xFFE5E7EB),
                                selectedColor: const Color(0xFF6D28D9),
                                borderWidth: 1.5,
                              ),
                              cursorColor: const Color(0xFF6D28D9),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFF3E8FF,
                                        ).withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF6D28D9),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Waiting for auto-SMS detection...',
                                            style: GoogleFonts.nunito(
                                              color: const Color(0xFF5B21B6),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.error.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.error,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: GoogleFonts.nunito(
                                          color: AppColors.error,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Primary Verify Button
                            AnimatedOpacity(
                              opacity: canVerify ? 1.0 : 0.65,
                              duration: const Duration(milliseconds: 200),
                              child: GestureDetector(
                                onTap: canVerify ? _verify : null,
                                child: Container(
                                  height: 50,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6D28D9),
                                        Color(0xFF5B21B6),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF5B21B6,
                                        ).withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Verify & Continue',
                                                style: GoogleFonts.nunito(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.check_circle_outline_rounded,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Resend OTP section inside/below
                            _countdown > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.timer_outlined,
                                          size: 16,
                                          color: Color(0xFF6B7280),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Resend code in ${_countdown}s',
                                          style: GoogleFonts.nunito(
                                            color: const Color(0xFF4B5563),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : TextButton.icon(
                                    onPressed: _resendOtp,
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                      color: Color(0xFF5B21B6),
                                    ),
                                    label: Text(
                                      'Resend OTP Code',
                                      style: GoogleFonts.nunito(
                                        color: const Color(0xFF5B21B6),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                  ),

                            if (kDebugMode) ...[
                              const SizedBox(height: 12),
                              FutureBuilder<String?>(
                                future: SmsAutoFill().getAppSignature,
                                builder: (context, snapshot) {
                                  return Opacity(
                                    opacity: 0.4,
                                    child: Text(
                                      'Debug Hash: ${snapshot.data ?? "..."}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(
                        begin: 0.08,
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

