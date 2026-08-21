import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/shared/widgets/points_burst.dart';

class GoalsSelectionScreen extends StatefulWidget {
  const GoalsSelectionScreen({super.key});

  @override
  State<GoalsSelectionScreen> createState() => _GoalsSelectionScreenState();
}

class _GoalsSelectionScreenState extends State<GoalsSelectionScreen> {
  final Set<String> _selected = {};
  bool _showPoints = false;

  static const _goals = [
    ('body',       '🌸', 'Understanding My Body'),
    ('period',     '📅', 'Managing My Period'),
    ('confidence', '💪', 'Feeling More Confident'),
    ('friends',    '👯', 'Making Good Friends'),
    ('career',     '📚', 'School & Life Skills'),
    ('all',        '✨', 'All of the Above!'),
  ];

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
    context.read<OnboardingBloc>().add(SetGoals(_selected.toList()));
    if (mounted) setState(() => _showPoints = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) context.go('/onboarding/period-comfort');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingBloc>().state;
    final isUnder13 = state.age < 13;

    return OnboardingScaffold(
      currentStep: 5,
      totalSteps: 11,
      onBack: () => context.go(isUnder13 ? '/onboarding/consent/send' : '/onboarding/birthday'),
      bottomBar: Stack(
        clipBehavior: Clip.none,
        children: [
          GradientButton(
            label: _selected.isEmpty
                ? 'Select At Least One'
                : 'Continue (${_selected.contains('all') ? 'All' : _selected.length} Selected)',
            onPressed: _continue,
            enabled: _selected.isNotEmpty,
          ),
          if (_showPoints)
            Positioned(
              top: -50,
              right: 20,
              child: PointsBurst(
                points: 15,
                onComplete: () {
                  if (mounted) setState(() => _showPoints = false);
                },
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'What would you love help with? 💭',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select whatever matters to you right now — you can change these anytime.',
                style: TextStyle(color: AppColors.textMedium, fontSize: 15),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.3,
                children: _goals.asMap().entries.map((e) {
                  final g = e.value;
                  final isSelected = _selected.contains(g.$1);
                  return GestureDetector(
                    onTap: () => _toggle(g.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.purple : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppColors.purple : const Color(0xFFE9D5FF),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppColors.purple.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.02),
                            blurRadius: isSelected ? 12 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(g.$2, style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 8),
                          Text(
                            g.$3,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isSelected ? Colors.white : AppColors.textDark,
                              height: 1.2,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 4),
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                          ],
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: e.key * 50)).fadeIn(duration: 200.ms);
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
