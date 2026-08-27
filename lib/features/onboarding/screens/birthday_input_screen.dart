import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

class BirthdayInputScreen extends StatefulWidget {
  const BirthdayInputScreen({super.key});

  @override
  State<BirthdayInputScreen> createState() => _BirthdayInputScreenState();
}

class _BirthdayInputScreenState extends State<BirthdayInputScreen> {
  static const _months = [
    'Select Month',
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  late final List<String> _years;

  int? _selectedMonthIndex; // 0 is 'Select Month'
  int? _selectedYearIndex;  // 0 is 'Select Year'

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _years = ['Select Year', ...List.generate(35, (i) => '${now.year - 6 - i}')];

    // Restore from storage if previously saved
    final storage = context.read<LocalStorageService>();
    if (storage.birthYear != null && storage.birthMonth != null) {
      final savedMonthIndex = storage.birthMonth!; // 1..12
      final savedYearStr = '${storage.birthYear!}';
      final savedYearIndex = _years.indexOf(savedYearStr);
      if (savedMonthIndex >= 1 && savedMonthIndex <= 12) {
        _selectedMonthIndex = savedMonthIndex;
      }
      if (savedYearIndex > 0) {
        _selectedYearIndex = savedYearIndex;
      }
    }
  }

  bool get _hasValidSelection =>
      _selectedMonthIndex != null &&
      _selectedMonthIndex! > 0 &&
      _selectedYearIndex != null &&
      _selectedYearIndex! > 0;

  int? get _selectedMonth => _hasValidSelection ? _selectedMonthIndex! - 1 : null; // 0..11
  int? get _selectedYear => _hasValidSelection ? int.parse(_years[_selectedYearIndex!]) : null;

  int? get _age {
    if (!_hasValidSelection) return null;
    final now = DateTime.now();
    int age = now.year - _selectedYear!;
    if (now.month - 1 < _selectedMonth!) age--;
    return age;
  }

  String get _tierDescription {
    final age = _age;
    if (age == null) return 'Scroll wheels below to select your birth month & year 🌸';
    if (age < 8) return 'Oops, Access denied until you hit age 8, bestie.';
    if (age < 13) return 'Junior Journey • Safe & Protected 🛡️';
    if (age <= 15) return 'Early Teen Journey • Body & Growth 🌱';
    if (age <= 18) return 'Late Teen Journey • Confidence & Wellness ✨';
    return 'Young Adult Journey • Full Care Hub 🌟';
  }

  bool get _isTooYoung => _age != null && _age! < 8;

  Future<void> _proceed() async {
    if (!_hasValidSelection) return;
    final age = _age!;
    if (age < 8) {
      _showTooYoungDialog();
      return;
    }

    final storage = await LocalStorageService.create();
    await storage.setBirthDate(_selectedMonth! + 1, _selectedYear!);

    if (mounted) {
      context.read<OnboardingBloc>().add(SetBirthDate(_selectedMonth! + 1, _selectedYear!));

      if (age < 13) {
        context.go('/onboarding/consent/send');
      } else {
        context.go('/onboarding/goals');
      }
    }
  }

  void _showTooYoungDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🌟 Almost There!'),
        content: const Text(
          'Infano.Care is specially designed for girls aged 8 and up. Ask a parent to explore our resource center with you!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
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
          // 1. 3D Background Illustration
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

          // 3. Interactive Glassmorphic Birthday Card
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
                          maxWidth: 480,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(height: topSpace),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 26 : (isVerySmall ? 16 : 22),
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
                                  // 3D Cake Icon Badge
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
                                        '🎂',
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
                                    'When is your birthday? 🎈',
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
                                    "We use your birth month and year to personalize age-appropriate care.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280),
                                      height: 1.3,
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // Live Dynamic Age Tier Badge Card (Updates live as wheels scroll!)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isTooYoung
                                          ? const Color(0xFFFEF2F2)
                                          : const Color(0xFFFDF2F8),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _isTooYoung
                                            ? const Color(0xFFFECACA)
                                            : const Color(0xFFFBCFE8),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isTooYoung
                                                  ? const Color(0xFFEF4444)
                                                  : const Color(0xFFDB2777))
                                              .withValues(alpha: 0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            gradient: _isTooYoung
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color(0xFFEF4444),
                                                      Color(0xFFDC2626),
                                                    ],
                                                  )
                                                : const LinearGradient(
                                                    colors: [
                                                      Color(0xFF6D28D9),
                                                      Color(0xFF5B21B6),
                                                    ],
                                                  ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            _hasValidSelection ? '${_age!} yrs' : '🎂',
                                            style: GoogleFonts.nunito(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _tierDescription,
                                            style: GoogleFonts.nunito(
                                              color: _isTooYoung
                                                  ? const Color(0xFFDC2626)
                                                  : const Color(0xFF5B21B6),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().fadeIn(duration: 300.ms),

                                  const SizedBox(height: 16),

                                  // Inline Month + Year Wheel Pickers (Live update results directly on page!)
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                                    ),
                                    child: Row(
                                      children: [
                                        // Month Wheel
                                        Expanded(
                                          flex: 3,
                                          child: SizedBox(
                                            height: 150,
                                            child: ListWheelScrollView.useDelegate(
                                              itemExtent: 42,
                                              perspective: 0.003,
                                              physics: const FixedExtentScrollPhysics(),
                                              controller: FixedExtentScrollController(
                                                initialItem: _selectedMonthIndex ?? 0,
                                              ),
                                              onSelectedItemChanged: (i) {
                                                setState(() => _selectedMonthIndex = i);
                                              },
                                              childDelegate: ListWheelChildListDelegate(
                                                children: _months.asMap().entries.map((e) {
                                                  final isSelected = e.key == _selectedMonthIndex;
                                                  final isPlaceholder = e.key == 0;
                                                  return Center(
                                                    child: Text(
                                                      e.value,
                                                      style: GoogleFonts.nunito(
                                                        fontSize: isSelected ? (isPlaceholder ? 15 : 17) : 14,
                                                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                                        color: isSelected
                                                            ? (isPlaceholder ? const Color(0xFF9CA3AF) : const Color(0xFF6D28D9))
                                                            : const Color(0xFF9CA3AF),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ),

                                        Container(width: 1, height: 100, color: const Color(0xFFE5E7EB)),

                                        // Year Wheel
                                        Expanded(
                                          flex: 2,
                                          child: SizedBox(
                                            height: 150,
                                            child: ListWheelScrollView.useDelegate(
                                              itemExtent: 42,
                                              perspective: 0.003,
                                              physics: const FixedExtentScrollPhysics(),
                                              controller: FixedExtentScrollController(
                                                initialItem: _selectedYearIndex ?? 0,
                                              ),
                                              onSelectedItemChanged: (i) {
                                                setState(() => _selectedYearIndex = i);
                                              },
                                              childDelegate: ListWheelChildListDelegate(
                                                children: _years.asMap().entries.map((e) {
                                                  final isSelected = e.key == _selectedYearIndex;
                                                  final isPlaceholder = e.key == 0;
                                                  return Center(
                                                    child: Text(
                                                      e.value,
                                                      style: GoogleFonts.nunito(
                                                        fontSize: isSelected ? (isPlaceholder ? 14.5 : 18.5) : 14,
                                                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                                        color: isSelected
                                                            ? (isPlaceholder ? const Color(0xFF9CA3AF) : const Color(0xFF6D28D9))
                                                            : const Color(0xFF9CA3AF),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Continue Action Button (Standardized Phone/OTP CTA style)
                                  AnimatedOpacity(
                                    opacity: _hasValidSelection && !_isTooYoung ? 1.0 : 0.65,
                                    duration: const Duration(milliseconds: 200),
                                    child: GestureDetector(
                                      onTap: _hasValidSelection && !_isTooYoung ? _proceed : null,
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
                                                'Next',
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
                  context.go('/onboarding/name');
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
