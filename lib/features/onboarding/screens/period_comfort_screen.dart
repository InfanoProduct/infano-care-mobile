import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';

class PeriodComfortScreen extends StatefulWidget {
  const PeriodComfortScreen({super.key});

  @override
  State<PeriodComfortScreen> createState() => _PeriodComfortScreenState();
}

class _PeriodComfortScreenState extends State<PeriodComfortScreen> {
  int? _selected;

  static const _scale = [
    ('😬', 'Pretty\nhesitant'),
    ('😕', 'A bit\nunsure'),
    ('😐', 'Getting\nused to it'),
    ('🙂', 'Comfortable'),
    ('😄', 'Super\nconfident!'),
  ];

  static const _responses = [
    "That is 100% normal! We'll go at your pace and make everything simple. 💜",
    "Completely okay — we break things down step-by-step so you feel secure. 🌸",
    "Great starting point! You're already taking positive steps. ✨",
    "Awesome! You're in a great space to build healthy habits. 💜",
    "Amazing openness! You're ready to bloom into your best self. 🌟",
  ];

  @override
  void initState() {
    super.initState();
    final blocState = context.read<OnboardingBloc>().state;
    if (blocState.periodComfortScore > 0) {
      _selected = (blocState.periodComfortScore - 1).clamp(0, _scale.length - 1);
    }
  }

  void _select(int i) {
    setState(() {
      _selected = i;
    });
    context.read<OnboardingBloc>().add(SetPeriodComfort(i + 1));
  }

  void _proceed() {
    if (_selected == null) return;
    context.go('/onboarding/period-status');
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
                                  // 3D Period Drop Badge Icon (Replaced Step 5 of 10)
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
                                        '💧',
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
                                    'How comfortable are you talking about periods?',
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
                                    'Be honest — there are no wrong answers in this safe space! 😊',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: isTablet ? 14.5 : 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Emoji Scale Option Cards
                                  Row(
                                    children: _scale.asMap().entries.map((e) {
                                      final isSelected = _selected == e.key;
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () => _select(e.key),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            margin: const EdgeInsets.symmetric(horizontal: 2),
                                            padding: EdgeInsets.symmetric(
                                              vertical: isCompact ? 10 : 14,
                                              horizontal: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: isSelected
                                                  ? const LinearGradient(
                                                      colors: [
                                                        Color(0xFF7C3AED),
                                                        Color(0xFF5B21B6),
                                                      ],
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                    )
                                                  : null,
                                              color: isSelected ? null : const Color(0xFFF8F5FF),
                                              borderRadius: BorderRadius.circular(18),
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFF7C3AED)
                                                    : const Color(0xFFE9D5FF),
                                                width: isSelected ? 2.0 : 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isSelected
                                                      ? const Color(0xFF6D28D9).withValues(alpha: 0.35)
                                                      : Colors.black.withValues(alpha: 0.03),
                                                  blurRadius: isSelected ? 12 : 4,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  e.value.$1,
                                                  style: TextStyle(
                                                    fontSize: isTablet ? 30 : (isVerySmall ? 22 : 26),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      e.value.$2,
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.nunito(
                                                        fontSize: 10.5,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : const Color(0xFF334155),
                                                        fontWeight: isSelected
                                                            ? FontWeight.w900
                                                            : FontWeight.w700,
                                                        height: 1.2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 20),

                                  // Dynamic Response Message Card
                                  if (_selected != null) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3E8FF),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFDDD6FE),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6D28D9).withValues(alpha: 0.08),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('💬', style: TextStyle(fontSize: 22)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _responses[_selected!],
                                              style: GoogleFonts.nunito(
                                                color: const Color(0xFF4C1D95),
                                                fontSize: isTablet ? 14.5 : 13.5,
                                                fontWeight: FontWeight.w800,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, duration: 250.ms),
                                    const SizedBox(height: 20),

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
                                    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.15, duration: 250.ms),
                                    const SizedBox(height: 16),
                                  ],

                                  // Skip Button
                                  TextButton(
                                    onPressed: () => context.go('/onboarding/period-status'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Skip for now',
                                      style: GoogleFonts.nunito(
                                        color: const Color(0xFF8B5CF6),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
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

          // 4. Top Floating Back Button (Placed AFTER ScrollView in Stack for top Z-index clickability)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: isTablet ? 32 : 16,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/onboarding/goals');
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
