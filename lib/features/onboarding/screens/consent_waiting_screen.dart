import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';

class ConsentWaitingScreen extends StatefulWidget {
  const ConsentWaitingScreen({super.key});

  @override
  State<ConsentWaitingScreen> createState() => _ConsentWaitingScreenState();
}

class _ConsentWaitingScreenState extends State<ConsentWaitingScreen> {
  Timer? _pollTimer;
  Timer? _factTimer;
  Timer? _cooldownTimer;
  int _factIndex = 0;
  int _resendCooldown = 0;

  static const _facts = [
    'Did you know? The human body has about 37 trillion cells! 🌿',
    'Girls who read regularly score higher in empathy — true story! 📚',
    'Your heart beats about 100,000 times every single day! ❤️',
    'There are more stars in the universe than grains of sand on Earth! 🌟',
  ];

  @override
  void initState() {
    super.initState();
    _startPolling();
    _rotateFacts();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        context.read<OnboardingBloc>().add(const CheckConsentStatus());
      }
    });
  }

  void _rotateFacts() {
    _factTimer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _factIndex = (_factIndex + 1) % _facts.length);
    });
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _factTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 700;
    final isVerySmall = size.width < 360;
    final isTablet = size.width >= 600 || size.height >= 1000;
    final horizontalPadding = isTablet ? 32.0 : (isVerySmall ? 14.0 : 20.0);
    final topSpace = isTablet
        ? (size.height * 0.20).clamp(80.0, 220.0)
        : (isCompact ? 60.0 : (size.height * 0.14).clamp(80.0, 150.0));

    return BlocListener<OnboardingBloc, OnboardingState>(
      listenWhen: (prev, curr) => prev.consentStatus != curr.consentStatus,
      listener: (context, state) {
        if (state.consentStatus == 'approved') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Parent permission approved! 🎉',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
          context.go('/onboarding/goals');
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 1. 3D Background Illustration (Character visible)
            Positioned.fill(
              child: Image.asset(
                'assets/images/phone_entry_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            // 2. Soft Gradient Overlay for depth & clarity
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

            // 3. Glassmorphic Consent Waiting Card (Positioned at bottom so character girl Gigi's face is fully visible!)
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
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
                          maxWidth: 480, // Responsive card width limit for tablets
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: topSpace,
                            ), // Leave top space so Gigi's face is fully visible!
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 26 : (isVerySmall ? 16 : 22),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Animated 3D Sprout Badge Icon
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFEDE9FE),
                                          Color(0xFFF5F3FF),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF6D28D9,
                                          ).withValues(alpha: 0.18),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '🌱',
                                        style: TextStyle(fontSize: 32),
                                      ),
                                    ),
                                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                                    .scale(
                                      begin: const Offset(0.94, 0.94),
                                      end: const Offset(1.06, 1.06),
                                      duration: 1500.ms,
                                      curve: Curves.easeInOut,
                                    ),

                                  const SizedBox(height: 16),

                                  // Title: We've sent the note! 💌
                                  Text(
                                    "We've sent the note! 💌",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: isVerySmall ? 19 : 21,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF2D1557),
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // Subtitle
                                  Text(
                                    "Waiting for approval from your parent or guardian...",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280),
                                      height: 1.3,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Animated Rotating Fun Fact Box
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    child: Container(
                                      key: ValueKey(_factIndex),
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6D28D9).withValues(alpha: 0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.lightbulb_outline_rounded,
                                                color: Color(0xFF6D28D9),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Fun Fact While You Wait',
                                                style: GoogleFonts.nunito(
                                                  color: const Color(0xFF6D28D9),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _facts[_factIndex],
                                            style: GoogleFonts.nunito(
                                              color: const Color(0xFF374151),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              height: 1.35,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Resend Email Button with Cooldown Timer
                                  SizedBox(
                                    width: double.infinity,
                                    height: 46,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF6D28D9),
                                        side: BorderSide(
                                          color: _resendCooldown == 0
                                              ? const Color(0xFF6D28D9)
                                              : const Color(0xFFE5E7EB),
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        backgroundColor: Colors.white,
                                      ),
                                      icon: Icon(
                                        Icons.refresh_rounded,
                                        color: _resendCooldown == 0
                                            ? const Color(0xFF6D28D9)
                                            : const Color(0xFF9CA3AF),
                                        size: 18,
                                      ),
                                      label: Text(
                                        _resendCooldown > 0
                                            ? 'Resend in ${_resendCooldown}s'
                                            : 'Resend Email',
                                        style: GoogleFonts.nunito(
                                          color: _resendCooldown == 0
                                              ? const Color(0xFF6D28D9)
                                              : const Color(0xFF9CA3AF),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      onPressed: _resendCooldown == 0
                                          ? () {
                                              final parentEmail = context
                                                  .read<OnboardingBloc>()
                                                  .state
                                                  .parentEmail;
                                              if (parentEmail != null) {
                                                context
                                                    .read<OnboardingBloc>()
                                                    .add(SendConsentEmail(parentEmail));
                                                setState(() => _resendCooldown = 60);
                                                _startCooldown();
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Verification email resent! 📩',
                                                      style: GoogleFonts.nunito(
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                    backgroundColor: const Color(0xFF6D28D9),
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          : null,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Privacy Footer Note
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.shield_outlined,
                                        size: 14,
                                        color: Color(0xFF6B7280),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'We protect and never sell data to 3rd-party',
                                        style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
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

          // 4. Top Floating Back Button (Placed AFTER SafeArea for top Z-index clickability)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: isTablet ? 32 : 16,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/onboarding/consent/send');
                }
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
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
        ],
      ),
    ),
    );
  }
}

