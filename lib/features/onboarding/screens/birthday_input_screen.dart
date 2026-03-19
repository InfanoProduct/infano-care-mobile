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
  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  int _selectedMonth = 6;  // 0-based index
  int _selectedYear  = DateTime.now().year - 15;

  int get _age {
    final now = DateTime.now();
    int age = now.year - _selectedYear;
    if (now.month - 1 < _selectedMonth) age--;
    return age;
  }

  Future<void> _proceed() async {
    final age = _age;
    if (age < 6) {
      _showTooYoungDialog();
      return;
    }

    // Persist to storage and update bloc
    final storage = await LocalStorageService.create();
    await storage.setBirthDate(_selectedMonth + 1, _selectedYear);
    
    if (mounted) {
      context.read<OnboardingBloc>().add(SetBirthDate(_selectedMonth + 1, _selectedYear));
      
    if (mounted) {
      context.read<OnboardingBloc>().add(SetBirthDate(_selectedMonth + 1, _selectedYear));
      await storage.setStageComplete('1');
      if (mounted) context.go('/onboarding/goals');
    }
    }
  }

  void _showTooYoungDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('👋 Hold on!'),
        content: const Text('Infano.Care is for girls aged 10 and up. Ask a parent or guardian for help!'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(28, (i) => currentYear - 3 - i);

    return OnboardingScaffold(
      currentStep: 3,
      bottomBar: GradientButton(label: 'Continue', onPressed: _proceed, enabled: _age >= 6),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text('When were you born? 🎂',
                style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('We only need your birth month and year to show you the right content.',
                style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 40),
              // Month + Year drum pickers
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 200,
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 48,
                        perspective: 0.005,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (i) => setState(() => _selectedMonth = i),
                        controller: FixedExtentScrollController(initialItem: _selectedMonth),
                        childDelegate: ListWheelChildListDelegate(
                          children: _months.asMap().entries.map((e) =>
                            Center(child: Text(e.value,
                              style: TextStyle(
                                fontSize: e.key == _selectedMonth ? 22 : 16,
                                fontWeight: e.key == _selectedMonth ? FontWeight.w800 : FontWeight.w500,
                                color: e.key == _selectedMonth ? AppColors.purple : AppColors.textLight,
                              ))),
                          ).toList(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 200,
                      child: ListWheelScrollView(
                        itemExtent: 48,
                        perspective: 0.005,
                        physics: const FixedExtentScrollPhysics(),
                        controller: FixedExtentScrollController(initialItem: 12),
                        onSelectedItemChanged: (i) => setState(() => _selectedYear = years[i]),
                        children: years.map((y) =>
                          Center(child: Text('$y',
                            style: TextStyle(
                              fontSize: y == _selectedYear ? 22 : 16,
                              fontWeight: y == _selectedYear ? FontWeight.w800 : FontWeight.w500,
                              color: y == _selectedYear ? AppColors.purple : AppColors.textLight,
                            ))),
                        ).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.purple, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text('We only use your birth year for age-appropriate content. We never share it.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMedium))),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
