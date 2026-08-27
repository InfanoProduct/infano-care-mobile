import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';

class PastelCardTheme {
  final Color unselectedBg;
  final Color selectedBg;
  final Color textColor;
  final Color accentColor;
  final Color shadowColor;

  const PastelCardTheme({
    required this.unselectedBg,
    required this.selectedBg,
    required this.textColor,
    required this.accentColor,
    required this.shadowColor,
  });
}

class PeriodExperienceScreen extends StatefulWidget {
  const PeriodExperienceScreen({super.key});

  @override
  State<PeriodExperienceScreen> createState() => _PeriodExperienceScreenState();
}

class _PeriodExperienceScreenState extends State<PeriodExperienceScreen> {
  String? _selected; // Default: null (No option selected by default!)

  static const _options = [
    (
      'active',
      '🌸',
      "Yes, I have!",
      "Sets up your smart cycle predictions and phase logging.",
      "Tracker Enabled ✨"
    ),
    (
      'waiting',
      '🌱',
      "Not yet, but I'm curious!",
      "We'll teach you what to expect and prep body readiness.",
      "Educational Prep Mode"
    ),
    (
      'unsure',
      '🤔',
      "I'm not sure...",
      "We'll provide gentle guidance to help you recognize signs.",
      "Guidance Mode"
    ),
  ];

  static const Map<String, PastelCardTheme> _themes = {
    'active': PastelCardTheme(
      unselectedBg: Color(0xFFFFF0F5), // Soft Pastel Blush Pink
      selectedBg: Color(0xFFFCE7F3),   // Rich Pastel Pink
      textColor: Color(0xFF831843),    // Deep Pink Text
      accentColor: Color(0xFFBE185D),  // Vibrant Pink Accent
      shadowColor: Color(0xFFDB2777),  // 3D Pink Shadow
    ),
    'waiting': PastelCardTheme(
      unselectedBg: Color(0xFFECFDF5), // Soft Pastel Mint
      selectedBg: Color(0xFFD1FAE5),   // Rich Pastel Mint
      textColor: Color(0xFF064E3B),    // Deep Mint Text
      accentColor: Color(0xFF047857),  // Vibrant Mint Accent
      shadowColor: Color(0xFF10B981),  // 3D Mint Shadow
    ),
    'unsure': PastelCardTheme(
      unselectedBg: Color(0xFFF0F9FF), // Soft Pastel Sky
      selectedBg: Color(0xFFE0F2FE),   // Rich Pastel Sky
      textColor: Color(0xFF0C4A6E),    // Deep Sky Text
      accentColor: Color(0xFF0369A1),  // Vibrant Sky Accent
      shadowColor: Color(0xFF0284C7),  // 3D Sky Shadow
    ),
  };

  @override
  void initState() {
    super.initState();
    // Intentionally no default selection so user makes an explicit choice!
    _selected = null;
  }

  void _select(String status) {
    setState(() => _selected = status);
    context.read<OnboardingBloc>().add(SetPeriodStatus(status));
  }

  void _proceed() {
    if (_selected == null) return;
    context.read<OnboardingBloc>().add(SetPeriodStatus(_selected!));
    if (_selected == 'active') {
      context.go('/onboarding/tracker/date');
    } else {
      context.go('/onboarding/terms');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 700;
    final isVerySmall = size.width < 360;
    final isTablet = size.width >= 600 || size.height >= 1000;
    final horizontalPadding = isTablet ? 32.0 : (isVerySmall ? 14.0 : 20.0);
    final topSpace = isTablet
        ? (size.height * 0.18).clamp(70.0, 200.0)
        : (isCompact ? 50.0 : (size.height * 0.12).clamp(60.0, 130.0));

    return Scaffold(
      body: Stack(
        children: [
          // 1. 3D Background Illustration (Character visible at top)
          Positioned.fill(
            child: Image.asset(
              'assets/images/phone_entry_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // 2. Soft Gradient Overlay
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

          // 3. Main Responsive Glassmorphic Card Content
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
                          maxWidth: 520, // Tablet responsive width constraint
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(height: topSpace),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 26 : (isVerySmall ? 14 : 20),
                                vertical: isCompact ? 20 : 26,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.93),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4C1D95).withValues(alpha: 0.22),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 3D Header Badge Icon Container
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
                                          color: const Color(0xFF6D28D9).withValues(alpha: 0.16),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '🌱',
                                        style: TextStyle(fontSize: 26),
                                      ),
                                    ),
                                  ).animate().scale(
                                        duration: 500.ms,
                                        curve: Curves.elasticOut,
                                      ),
                                  const SizedBox(height: 14),

                                  // Header Title
                                  Text(
                                    'Have you had your first period yet?',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: isTablet ? 24 : (isVerySmall ? 18 : 21),
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF2D1557),
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Subtitle
                                  Text(
                                    'Every body develops on its own unique timeline 🌱',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: isTablet ? 14.5 : 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Pastel Glassy Option Cards with 3D Bottom Shadow & No Border
                                  ..._options.asMap().entries.map((e) {
                                    final o = e.value;
                                    final key = o.$1;
                                    final isSelected = _selected == key;
                                    final theme = _themes[key] ??
                                        const PastelCardTheme(
                                          unselectedBg: Color(0xFFFFF0F5),
                                          selectedBg: Color(0xFFFCE7F3),
                                          textColor: Color(0xFF831843),
                                          accentColor: Color(0xFFBE185D),
                                          shadowColor: Color(0xFFDB2777),
                                        );

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: GestureDetector(
                                        onTap: () => _select(key),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 220),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isCompact ? 16 : 18,
                                            vertical: isCompact ? 14 : 18,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? theme.selectedBg
                                                : theme.unselectedBg,
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(
                                              color: Colors.transparent, // No border!
                                              width: 0,
                                            ),
                                            boxShadow: [
                                              // Glassy top subtle sheen highlight
                                              BoxShadow(
                                                color: Colors.white.withValues(alpha: 0.8),
                                                blurRadius: 2,
                                                offset: const Offset(0, -2),
                                              ),
                                              // 3D Bottom Shadow
                                              BoxShadow(
                                                color: isSelected
                                                    ? theme.shadowColor
                                                        .withValues(alpha: 0.32)
                                                    : theme.shadowColor
                                                        .withValues(alpha: 0.12),
                                                blurRadius: isSelected ? 16 : 8,
                                                offset: Offset(0, isSelected ? 7 : 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  // 3D Icon Circle
                                                  Container(
                                                    width: isCompact ? 42 : 46,
                                                    height: isCompact ? 42 : 46,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: theme.shadowColor
                                                              .withValues(alpha: 0.18),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 3),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        o.$2,
                                                        style: TextStyle(
                                                          fontSize: isCompact ? 21 : 23,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          o.$3,
                                                          style: GoogleFonts.nunito(
                                                            fontWeight: FontWeight.w900,
                                                            fontSize: isTablet
                                                                ? 16.5
                                                                : (isVerySmall ? 14 : 15.5),
                                                            color: theme.textColor,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 9,
                                                            vertical: 3,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white
                                                                .withValues(alpha: 0.7),
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                          child: Text(
                                                            o.$5,
                                                            style: GoogleFonts.nunito(
                                                              color: theme.textColor,
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w800,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Radio Indicator
                                                  AnimatedContainer(
                                                    duration: const Duration(milliseconds: 180),
                                                    width: 26,
                                                    height: 26,
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? theme.accentColor
                                                          : Colors.transparent,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? theme.accentColor
                                                            : theme.accentColor
                                                                .withValues(alpha: 0.35),
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: isSelected
                                                        ? const Icon(
                                                            Icons.check_rounded,
                                                            size: 16,
                                                            color: Colors.white,
                                                          )
                                                        : null,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                o.$4,
                                                style: GoogleFonts.nunito(
                                                  color: theme.textColor.withValues(alpha: 0.85),
                                                  fontSize: isTablet ? 13.5 : 12.5,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 16),

                                  // Proceed CTA Button
                                  AnimatedOpacity(
                                    opacity: _selected != null ? 1.0 : 0.65,
                                    duration: const Duration(milliseconds: 200),
                                    child: GestureDetector(
                                      onTap: _selected != null ? _proceed : null,
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
                                              color: const Color(0xFF5B21B6).withValues(alpha: 0.35),
                                              blurRadius: 14,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Proceed',
                                                style: GoogleFonts.nunito(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                  context.go('/onboarding/period-comfort');
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
    );
  }
}
