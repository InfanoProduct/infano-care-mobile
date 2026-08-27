import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:provider/provider.dart';

class NamePronounsScreen extends StatefulWidget {
  const NamePronounsScreen({super.key});

  @override
  State<NamePronounsScreen> createState() => _NamePronounsScreenState();
}

class _NamePronounsScreenState extends State<NamePronounsScreen> {
  final _controller = TextEditingController();
  String? _pronoun;

  @override
  void initState() {
    super.initState();
    final storage = context.read<LocalStorageService>();
    if (storage.displayName != null && storage.displayName!.isNotEmpty) {
      _controller.text = storage.displayName!;
    }
    _pronoun = storage.pronouns;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _pronouns = ['She / Her', 'She / They', 'They / Them', 'Prefer not to say'];

  bool get _valid => _controller.text.trim().length >= 2;

  void _onNameChanged(String value) {
    setState(() {});
  }

  Future<void> _continue() async {
    if (!_valid) return;
    final storage = await LocalStorageService.create();
    await storage.setDisplayName(_controller.text.trim());
    await storage.setPronouns(_pronoun);
    if (mounted) context.go('/onboarding/birthday');
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

          // 2. Soft Gradient Overlay for depth & focus
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

          // 4. Glassmorphic Card (Positioned at bottom so character girl Gigi's face is fully visible!)
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
                                horizontal: isTablet ? 28 : (isVerySmall ? 16 : 22),
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
                              // 3D Wave Badge Icon
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
                                    '👋',
                                    style: TextStyle(fontSize: 26),
                                  ),
                                ),
                              ).animate().scale(
                                duration: 500.ms,
                                curve: Curves.elasticOut,
                              ),

                              const SizedBox(height: 14),

                              // Title: What should we call you? 👋
                              Text(
                                "What should we call you? 👋",
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
                                "Your first name or favorite nickname works great!",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B7280),
                                  height: 1.3,
                                ),
                              ),

                              const SizedBox(height: 22),

                              // Name Input Field with Points Burst
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDF2F8), // Soft Light Pink background
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFFBCFE8), // Gentle pink border
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFDB2777).withValues(alpha: 0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: _controller,
                                      maxLength: 30,
                                      onChanged: _onNameChanged,
                                      style: GoogleFonts.nunito(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF111827),
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        hintText: 'e.g. Maya or Alex',
                                        hintStyle: GoogleFonts.nunito(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF9CA3AF),
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.person_outline_rounded,
                                          color: Color(0xFF6D28D9),
                                          size: 20,
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                 ],
                               ),

                              const SizedBox(height: 20),

                              // Pronouns Section Header
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Your pronouns (optional)',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Pronouns Selection Chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.start,
                                children: _pronouns.map((p) {
                                  final isSelected = _pronoun == p;
                                  return GestureDetector(
                                    onTap: () => setState(() => _pronoun = isSelected ? null : p),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isVerySmall ? 12 : 14,
                                        vertical: isVerySmall ? 8 : 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF6D28D9),
                                                  Color(0xFF5B21B6),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        color: isSelected ? null : const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF5B21B6)
                                              : const Color(0xFFE5E7EB),
                                          width: isSelected ? 2 : 1.2,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF6D28D9).withValues(alpha: 0.22),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        p,
                                        style: GoogleFonts.nunito(
                                          color: isSelected ? Colors.white : const Color(0xFF374151),
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          fontSize: isVerySmall ? 12 : 13,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 12),

                              Text(
                                'You can always update this later in your profile.',
                                style: GoogleFonts.nunito(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 22),

                              // Continue Action Button (Gradient)
                              AnimatedOpacity(
                                opacity: _valid ? 1.0 : 0.65,
                                duration: const Duration(milliseconds: 200),
                                child: GestureDetector(
                                  onTap: _valid ? _continue : null,
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
                                            'Continue',
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
        ],
      ),
    );
  }
}

