import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

class PathSelectorScreen extends StatefulWidget {
  const PathSelectorScreen({super.key});

  @override
  State<PathSelectorScreen> createState() => _PathSelectorScreenState();
}

class _PathSelectorScreenState extends State<PathSelectorScreen> {
  int? _selected;

  Future<void> _select(int index) async {
    setState(() => _selected = index);

    final cleanRole = (index == 0) ? 'TEEN' : 'PARENT';
    try {
      await ApiService.instance.dio.patch('/user/role', data: {'role': cleanRole});
    } catch (e) {
      debugPrint('[PathSelectorScreen] Failed to update role: $e');
    }

    final storage = await LocalStorageService.create();
    await storage.setUserType(index == 0 ? 'teen' : 'parent');
    await storage.setRole(cleanRole);
    await storage.setStepComplete('0.5');
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    context.go('/onboarding/name');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 700;
    final isTablet = size.width >= 600 || size.height >= 1000;
    final horizontalPadding = isTablet ? 32.0 : (size.width < 360 ? 14.0 : 20.0);
    final topSpace = isTablet
        ? (size.height * 0.20).clamp(80.0, 220.0)
        : (isCompact ? 60.0 : (size.height * 0.14).clamp(80.0, 150.0));

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

          // 4. Interactive Glassmorphic Role Card (Responsive for all mobile & tablet dimensions)
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
                                horizontal: isTablet ? 26 : (size.width < 360 ? 16 : 22),
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
                                  // 3D Star / Sparkle Badge Icon
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
                                      child: Text(
                                        '✨',
                                        style: TextStyle(fontSize: 26),
                                      ),
                                    ),
                                  ).animate().scale(
                                    duration: 500.ms,
                                    curve: Curves.elasticOut,
                                  ),

                                  const SizedBox(height: 14),

                                  // Title: Who are you? ✨
                                  Text(
                                    "Who are you? ✨",
                                    style: GoogleFonts.nunito(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF2D1557),
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // Subtitle
                                  Text(
                                    'Choose your journey path to get personalized care & support.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280),
                                      height: 1.35,
                                    ),
                                  ),

                                  const SizedBox(height: 22),

                                  // Path Cards
                                  _PathCard(
                                    imagePath: 'assets/images/role_teen.png',
                                    emoji: '🌸',
                                    title: "I'm a Girl or Young Woman",
                                    subtitle: 'Ages 10–24 • Learn, track, and blossom',
                                    selected: _selected == 0,
                                    onTap: () => _select(0),
                                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, duration: 400.ms),

                                  const SizedBox(height: 14),

                                  _PathCard(
                                    imagePath: 'assets/images/role_parent.png',
                                    emoji: '👨‍👧',
                                    title: "I'm a Parent or Guardian",
                                    subtitle: 'Set up guidance and care for my child',
                                    selected: _selected == 1,
                                    onTap: () => _select(1),
                                  ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, duration: 400.ms),

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
                  context.go('/auth/phone');
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

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.imagePath,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String imagePath, emoji, title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 360;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmall ? 12 : 16,
          vertical: isVerySmall ? 14 : 16,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFAF5FF) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF6D28D9) : const Color(0xFFE5E7EB),
            width: selected ? 2.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0xFF6D28D9).withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: selected ? 14 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image / Avatar Container
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isVerySmall ? 48 : 54,
              height: isVerySmall ? 48 : 54,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF6D28D9).withValues(alpha: 0.12)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        emoji,
                        style: TextStyle(fontSize: isVerySmall ? 22 : 26),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: isVerySmall ? 10 : 14),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: isVerySmall ? 14 : 15,
                      color: selected ? const Color(0xFF5B21B6) : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                      fontSize: isVerySmall ? 11.5 : 12.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Checkmark Radio Badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isVerySmall ? 22 : 24,
              height: isVerySmall ? 22 : 24,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFF6D28D9), Color(0xFF5B21B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? const Color(0xFF5B21B6) : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6D28D9).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: selected
                  ? Icon(Icons.check_rounded, size: isVerySmall ? 13 : 15, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

