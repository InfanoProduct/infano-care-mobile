import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';

class PeriodExperienceScreen extends StatefulWidget {
  const PeriodExperienceScreen({super.key});

  @override
  State<PeriodExperienceScreen> createState() => _PeriodExperienceScreenState();
}

class _PeriodExperienceScreenState extends State<PeriodExperienceScreen> {
  String? _selected;

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

  void _select(String status) {
    setState(() => _selected = status);
    context.read<OnboardingBloc>().add(SetPeriodStatus(status));
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.go('/onboarding/interests');
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 7,
      totalSteps: 11,
      onBack: () => context.go('/onboarding/period-comfort'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Have you had your first period yet?',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Every body develops on its own unique timeline 🌱",
              style: TextStyle(color: AppColors.textMedium, fontSize: 15),
            ),
            const SizedBox(height: 32),
            ..._options.asMap().entries.map((e) {
              final o = e.value;
              final isSelected = _selected == o.$1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => _select(o.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.purple : const Color(0xFFE9D5FF),
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColors.purple.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: isSelected ? 12 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.purple.withValues(alpha: 0.1)
                                    : const Color(0xFFFAF5FF),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(o.$2, style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.$3,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: isSelected ? AppColors.purple : AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.purple.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      o.$5,
                                      style: const TextStyle(
                                        color: AppColors.purple,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.purple : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.purple : const Color(0xFFD8B4FE),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          o.$4,
                          style: const TextStyle(color: AppColors.textMedium, fontSize: 13, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: Duration(milliseconds: e.key * 80)).fadeIn(duration: 250.ms),
              );
            }),
          ],
        ),
      ),
    );
  }
}
