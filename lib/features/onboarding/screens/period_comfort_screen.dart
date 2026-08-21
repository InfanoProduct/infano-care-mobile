import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/shared/widgets/points_burst.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';

class PeriodComfortScreen extends StatefulWidget {
  const PeriodComfortScreen({super.key});

  @override
  State<PeriodComfortScreen> createState() => _PeriodComfortScreenState();
}

class _PeriodComfortScreenState extends State<PeriodComfortScreen> {
  int? _selected;
  bool _showPoints = false;

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

  void _select(int i) {
    context.read<OnboardingBloc>().add(SetPeriodComfort(i + 1));
    setState(() { _selected = i; _showPoints = true; });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        context.go('/onboarding/period-status');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 6,
      totalSteps: 11,
      onBack: () => context.go('/onboarding/goals'),
      bottomBar: _showPoints ? PointsBurst(points: 10, onComplete: () => setState(() => _showPoints = false)) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'How comfortable are you talking about periods?',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Be honest — there are no wrong answers in this safe space! 😊',
              style: TextStyle(color: AppColors.textMedium, fontSize: 15),
            ),
            const SizedBox(height: 36),
            // Emoji scale cards
            Row(
              children: _scale.asMap().entries.map((e) {
                final isSelected = _selected == e.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _select(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.purple : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.purple : const Color(0xFFE9D5FF),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppColors.purple.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.02),
                            blurRadius: isSelected ? 10 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.value.$1, style: const TextStyle(fontSize: 30)),
                          const SizedBox(height: 8),
                          Text(
                            e.value.$2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white : AppColors.textDark,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            if (_selected != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💬', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _responses[_selected!],
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, duration: 250.ms),
              const SizedBox(height: 24),
            ],
            Center(
              child: TextButton(
                onPressed: () => context.go('/onboarding/period-status'),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
