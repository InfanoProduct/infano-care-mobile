import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

class AssentTermsScreen extends StatefulWidget {
  const AssentTermsScreen({super.key});

  @override
  State<AssentTermsScreen> createState() => _AssentTermsScreenState();
}

class _AssentTermsScreenState extends State<AssentTermsScreen> {
  bool _terms = false;
  bool _privacy = false;
  bool _marketing = false;
  int? _expanded;
  bool _loading = false;

  static const _accordionItems = [
    (
      'What Infano.Care does',
      'A safe, age-appropriate platform for young girls to learn about their bodies, track their health, and build confidence — free from ads or data selling.'
    ),
    (
      'Your privacy & data safety',
      'We only collect the info needed for personalized care (name, age tier, cycle preferences). We never sell your data to third parties.'
    ),
    (
      'Expert verified content',
      'All educational articles and guides are medically reviewed by certified adolescent health educators and pediatricians.'
    ),
    (
      'You are always in control',
      'You can update preferences, export your entries, or delete your account whenever you choose.'
    ),
  ];

  bool get _canContinue => _terms && _privacy;

  Future<void> _letsBloom() async {
    if (!_canContinue || _loading) return;
    setState(() => _loading = true);
    final bloc = context.read<OnboardingBloc>();
    final storage = await LocalStorageService.create();

    await storage.setConsents(terms: _terms, privacy: _privacy, marketing: _marketing);
    bloc.add(SetConsent(_terms, _privacy, _marketing));

    final authToken = storage.authToken;
    if (authToken != null) {
      bloc.add(const SubmitProfile());
      await bloc.stream.firstWhere((state) => !state.isLoading);

      if (!mounted) return;
      if (bloc.state.errorMessage != null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bloc.state.errorMessage!),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
        return;
      }
    }

    if (mounted) {
      context.go('/onboarding/welcome');
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
                                        '📜',
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
                                    'How we take care of you 💜',
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
                                    'Our safety commitments and community standards in plain language.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: isTablet ? 14.5 : 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Accordion Information Cards
                                  ..._accordionItems.asMap().entries.map(
                                        (e) => _AccordionCard(
                                          index: e.key,
                                          title: e.value.$1,
                                          content: e.value.$2,
                                          expanded: _expanded == e.key,
                                          onTap: () => setState(
                                              () => _expanded = _expanded == e.key ? null : e.key),
                                          isTablet: isTablet,
                                        ),
                                      ),
                                  const SizedBox(height: 16),

                                  // Checkbox Consents
                                  _SolidCheckbox(
                                    value: _terms,
                                    label: "I agree to the Terms of Service",
                                    onChanged: (v) => setState(() => _terms = v ?? false),
                                  ),
                                  const SizedBox(height: 10),
                                  _SolidCheckbox(
                                    value: _privacy,
                                    label: "I agree to the Privacy Policy",
                                    onChanged: (v) => setState(() => _privacy = v ?? false),
                                  ),
                                  const SizedBox(height: 10),
                                  _SolidCheckbox(
                                    value: _marketing,
                                    label: "Send me wellness tips and updates (optional)",
                                    onChanged: (v) => setState(() => _marketing = v ?? false),
                                  ),
                                  const SizedBox(height: 24),

                                  // Proceed CTA Button ("Let's Bloom! 🌸")
                                  AnimatedOpacity(
                                    opacity: _canContinue && !_loading ? 1.0 : 0.65,
                                    duration: const Duration(milliseconds: 200),
                                    child: GestureDetector(
                                      onTap: _canContinue && !_loading ? _letsBloom : null,
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
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "Let's Bloom! 🌸",
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

                                  // Privacy Guarantee Note
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
                  context.go('/onboarding/period-status');
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

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({
    required this.index,
    required this.title,
    required this.content,
    required this.expanded,
    required this.onTap,
    required this.isTablet,
  });

  final int index;
  final String title, content;
  final bool expanded;
  final VoidCallback onTap;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: expanded ? const Color(0xFFF3E8FF) : const Color(0xFFF8F5FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: expanded ? const Color(0xFF7C3AED) : const Color(0xFFE9D5FF),
            width: expanded ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: expanded
                  ? const Color(0xFF6D28D9).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  ['📌', '🔒', '🛡️', '⚡'][index % 4],
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2D1557),
                      fontSize: isTablet ? 15.5 : 14,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF6D28D9),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 10),
              Text(
                content,
                style: GoogleFonts.nunito(
                  color: const Color(0xFF4B5563),
                  height: 1.4,
                  fontSize: isTablet ? 13.5 : 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SolidCheckbox extends StatelessWidget {
  const _SolidCheckbox({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: value ? const Color(0xFF6D28D9) : Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: value ? const Color(0xFF6D28D9) : const Color(0xFFC4B5FD),
                width: 2,
              ),
              boxShadow: value
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6D28D9).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: value ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: const Color(0xFF2D1557),
                fontSize: 13.5,
                fontWeight: value ? FontWeight.w800 : FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
