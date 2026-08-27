import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';

class GoalTheme {
  final Color unselectedBg;
  final Color selectedBg;
  final Color textColor;
  final Color accentColor;
  final Color shadowColor;

  const GoalTheme({
    required this.unselectedBg,
    required this.selectedBg,
    required this.textColor,
    required this.accentColor,
    required this.shadowColor,
  });
}

class GoalsSelectionScreen extends StatefulWidget {
  const GoalsSelectionScreen({super.key});

  @override
  State<GoalsSelectionScreen> createState() => _GoalsSelectionScreenState();
}

class _GoalsSelectionScreenState extends State<GoalsSelectionScreen> {
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    final blocState = context.read<OnboardingBloc>().state;
    if (blocState.goals.isNotEmpty) {
      _selected.addAll(blocState.goals);
    }
  }

  static const _goals = [
    ('body', '🌸', 'Understanding My Body'),
    ('period', '📅', 'Managing My Period'),
    ('confidence', '💪', 'Feeling More Confident'),
    ('friends', '👯', 'Making Good Friends'),
    ('career', '📚', 'School & Life Skills'),
    ('all', '✨', 'All of the Above!'),
  ];

  static const Map<String, GoalTheme> _goalThemes = {
    'body': GoalTheme(
      unselectedBg: Color(0xFFF3E8FF), // Soft Pastel Lavender
      selectedBg: Color(0xFFE9D5FF),
      textColor: Color(0xFF581C87), // Deep Lavender Text
      accentColor: Color(0xFF7E22CE),
      shadowColor: Color(0xFF9333EA),
    ),
    'period': GoalTheme(
      unselectedBg: Color(0xFFFCE7F3), // Soft Pastel Pink
      selectedBg: Color(0xFFFBCFE8),
      textColor: Color(0xFF831843), // Deep Pink Text
      accentColor: Color(0xFFBE185D),
      shadowColor: Color(0xFFDB2777),
    ),
    'confidence': GoalTheme(
      unselectedBg: Color(0xFFD1FAE5), // Soft Pastel Mint
      selectedBg: Color(0xFFA7F3D0),
      textColor: Color(0xFF064E3B), // Deep Mint Text
      accentColor: Color(0xFF047857),
      shadowColor: Color(0xFF10B981),
    ),
    'friends': GoalTheme(
      unselectedBg: Color(0xFFFFE4E6), // Soft Pastel Rose/Peach
      selectedBg: Color(0xFFFECDD3),
      textColor: Color(0xFF881337), // Deep Rose Text
      accentColor: Color(0xFFBE123C),
      shadowColor: Color(0xFFF43F5E),
    ),
    'career': GoalTheme(
      unselectedBg: Color(0xFFE0F2FE), // Soft Pastel Sky
      selectedBg: Color(0xFFBAE6FD),
      textColor: Color(0xFF0C4A6E), // Deep Sky Text
      accentColor: Color(0xFF0369A1),
      shadowColor: Color(0xFF0284C7),
    ),
    'all': GoalTheme(
      unselectedBg: Color(0xFFFEF3C7), // Soft Pastel Amber/Sun
      selectedBg: Color(0xFFFDE68A),
      textColor: Color(0xFF78350F), // Deep Amber Text
      accentColor: Color(0xFFB45309),
      shadowColor: Color(0xFFF59E0B),
    ),
  };

  void _toggle(String key) {
    setState(() {
      if (key == 'all') {
        if (_selected.length == _goals.length) {
          _selected.clear();
        } else {
          _selected.addAll(_goals.map((g) => g.$1));
        }
      } else {
        if (_selected.contains(key)) {
          _selected.remove(key);
          _selected.remove('all');
        } else {
          _selected.add(key);
          if (_goals.where((g) => g.$1 != 'all').every((g) => _selected.contains(g.$1))) {
            _selected.add('all');
          }
        }
      }
    });
  }

  void _continue() {
    if (_selected.isEmpty) return;
    context.read<OnboardingBloc>().add(SetGoals(_selected.toList()));
    context.go('/onboarding/period-comfort');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingBloc>().state;
    final isUnder13 = state.age < 13;

    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 700;
    final isVerySmall = size.width < 360;
    final isTablet = size.width >= 600 || size.height >= 1000;
    final horizontalPadding = isTablet ? 32.0 : (isVerySmall ? 14.0 : 20.0);

    final isSelectedAny = _selected.isNotEmpty;

    return Scaffold(
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

          // 4. Glassmorphic Goals Card (Positioned in Center)
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
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 480, // Responsive card width limit for tablets
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 26 : (isVerySmall ? 14 : 20),
                                vertical: isCompact ? 18 : 24,
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
                                  // 3D Thought Badge Icon
                                  Container(
                                    width: 52,
                                    height: 52,
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
                                      child: Text(
                                        '💭',
                                        style: TextStyle(fontSize: 26),
                                      ),
                                    ),
                                  ).animate().scale(
                                    duration: 500.ms,
                                    curve: Curves.elasticOut,
                                  ),

                                  const SizedBox(height: 12),

                                  // Title: What would you love help with? 💭
                                  Text(
                                    "What would you love help with? 💭",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: isVerySmall ? 18 : 20,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF2D1557),
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // Subtitle
                                  Text(
                                    "Select whatever matters to you right now — you can change these anytime.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280),
                                      height: 1.3,
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // Pastel 3D Glass Goal Cards (No Borders, Bottom Shadow, Glass Effect)
                                  GridView.count(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    childAspectRatio: isVerySmall ? 1.1 : 1.18,
                                    children: _goals.asMap().entries.map((e) {
                                      final g = e.value;
                                      final key = g.$1;
                                      final isSelected = _selected.contains(key);
                                      final theme = _goalThemes[key] ??
                                          const GoalTheme(
                                            unselectedBg: Color(0xFFF3F4F6),
                                            selectedBg: Color(0xFFE5E7EB),
                                            textColor: Color(0xFF1F2937),
                                            accentColor: Color(0xFF4B5563),
                                            shadowColor: Color(0xFF9CA3AF),
                                          );

                                      return GestureDetector(
                                        onTap: () => _toggle(key),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 220),
                                          curve: Curves.easeOutCubic,
                                          transform: isSelected
                                              ? Matrix4.translationValues(0, -3, 0)
                                              : Matrix4.identity(),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          decoration: BoxDecoration(
                                            // Glass Effect + Pastel Fill (No borders!)
                                            color: (isSelected ? theme.selectedBg : theme.unselectedBg)
                                                .withValues(alpha: isSelected ? 0.95 : 0.82),
                                            borderRadius: BorderRadius.circular(22),
                                            border: null, // Strictly NO borders as requested!
                                            boxShadow: [
                                              // 3D Bottom Shadow look & feel
                                              BoxShadow(
                                                color: theme.shadowColor.withValues(
                                                  alpha: isSelected ? 0.38 : 0.16,
                                                ),
                                                blurRadius: isSelected ? 12 : 8,
                                                spreadRadius: isSelected ? 0.5 : 0,
                                                offset: isSelected
                                                    ? const Offset(0, 7)
                                                    : const Offset(0, 4),
                                              ),
                                              // Top subtle light glass highlight
                                              BoxShadow(
                                                color: Colors.white.withValues(
                                                  alpha: isSelected ? 0.6 : 0.3,
                                                ),
                                                blurRadius: 2,
                                                offset: const Offset(0, -1),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(g.$2, style: const TextStyle(fontSize: 26)),
                                                const SizedBox(height: 5),
                                                Flexible(
                                                  child: Text(
                                                    g.$3,
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.nunito(
                                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                                      fontSize: 12.5,
                                                      color: theme.textColor,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ).animate(delay: Duration(milliseconds: e.key * 40)).fadeIn(duration: 250.ms);
                                    }).toList(),
                                  ),

                                  const SizedBox(height: 20),

                                  // Action Button with Points Burst Overlay
                                  AnimatedOpacity(
                                    opacity: isSelectedAny ? 1.0 : 0.65,
                                    duration: const Duration(milliseconds: 200),
                                    child: GestureDetector(
                                      onTap: isSelectedAny ? _continue : null,
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
                                                _selected.isEmpty
                                                    ? 'Select At Least One'
                                                    : 'Continue (${_selected.contains('all') ? 'All' : _selected.length} Selected)',
                                                style: GoogleFonts.nunito(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              if (isSelectedAny) ...[
                                                const SizedBox(width: 6),
                                                const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
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
                                          color: const Color(0xFF6B7280),
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
                  context.go(isUnder13 ? '/onboarding/consent/send' : '/onboarding/birthday');
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


