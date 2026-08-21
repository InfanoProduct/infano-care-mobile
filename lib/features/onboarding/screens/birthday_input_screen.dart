import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';

class BirthdayInputScreen extends StatefulWidget {
  const BirthdayInputScreen({super.key});

  @override
  State<BirthdayInputScreen> createState() => _BirthdayInputScreenState();
}

class _BirthdayInputScreenState extends State<BirthdayInputScreen> {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  int _selectedMonth = 6;  // 0-based index
  int _selectedYear  = DateTime.now().year - 15;

  @override
  void initState() {
    super.initState();
    final storage = context.read<LocalStorageService>();
    if (storage.birthYear != null) {
      _selectedYear = storage.birthYear!;
      _selectedMonth = (storage.birthMonth ?? 7) - 1;
    }
  }

  int get _age {
    final now = DateTime.now();
    int age = now.year - _selectedYear;
    if (now.month - 1 < _selectedMonth) age--;
    return age;
  }

  String get _tierDescription {
    final age = _age;
    if (age < 13) return 'Junior Journey • Safe & Protected 🛡️';
    if (age <= 15) return 'Early Teen Journey • Body & Growth 🌱';
    if (age <= 18) return 'Late Teen Journey • Confidence & Wellness ✨';
    return 'Young Adult Journey • Full Care Hub 🌟';
  }

  Future<void> _proceed() async {
    final age = _age;
    if (age < 6) {
      _showTooYoungDialog();
      return;
    }

    final storage = await LocalStorageService.create();
    await storage.setBirthDate(_selectedMonth + 1, _selectedYear);
    
    if (mounted) {
      context.read<OnboardingBloc>().add(SetBirthDate(_selectedMonth + 1, _selectedYear));
      
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
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('👋 Hold on!', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Infano.Care is designed for girls aged 10 and up. Ask a parent or guardian for help!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(28, (i) => currentYear - 3 - i);

    return OnboardingScaffold(
      currentStep: 3,
      totalSteps: 11,
      onBack: () => context.go('/onboarding/name'),
      bottomBar: GradientButton(label: 'Continue', onPressed: _proceed, enabled: _age >= 6),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'When were you born? 🎂',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We use your birth month and year to personalize age-appropriate care.',
                style: TextStyle(color: AppColors.textMedium, fontSize: 15),
              ),
              const SizedBox(height: 24),
              
              // Dynamic Age Tier Badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_age yrs',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _tierDescription,
                        style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 250.ms),

              const SizedBox(height: 24),
              
              // Month + Year Pickers Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 180,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 44,
                          perspective: 0.003,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) => setState(() => _selectedMonth = i),
                          controller: FixedExtentScrollController(initialItem: _selectedMonth),
                          childDelegate: ListWheelChildListDelegate(
                            children: _months.asMap().entries.map((e) {
                              final isSelected = e.key == _selectedMonth;
                              return Center(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    fontSize: isSelected ? 18 : 15,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                    color: isSelected ? AppColors.purple : AppColors.textLight,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 120, color: const Color(0xFFE9D5FF)),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 180,
                        child: ListWheelScrollView(
                          itemExtent: 44,
                          perspective: 0.003,
                          physics: const FixedExtentScrollPhysics(),
                          controller: FixedExtentScrollController(initialItem: 12),
                          onSelectedItemChanged: (i) => setState(() => _selectedYear = years[i]),
                          children: years.map((y) {
                            final isSelected = y == _selectedYear;
                            return Center(
                              child: Text(
                                '$y',
                                style: TextStyle(
                                  fontSize: isSelected ? 20 : 15,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected ? AppColors.purple : AppColors.textLight,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.purple, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your birth date stays private and is only used to tailor your learning tier.',
                        style: TextStyle(color: AppColors.textMedium, fontSize: 12.5, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
