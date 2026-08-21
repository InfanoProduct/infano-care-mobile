import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/shared/widgets/points_burst.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';

class InterestTopicsScreen extends StatefulWidget {
  const InterestTopicsScreen({super.key});

  @override
  State<InterestTopicsScreen> createState() => _InterestTopicsScreenState();
}

class _InterestTopicsScreenState extends State<InterestTopicsScreen> {
  final Set<String> _selected = {};
  bool _showPoints = false;

  static const _topics = [
    ('puberty',      '🌺', 'Puberty & Body Changes'),
    ('period',       '🩸', 'Period Health'),
    ('nutrition',    '🥗', 'Food & Nutrition'),
    ('fitness',      '💪', 'Exercise & Fitness'),
    ('emotional',    '🧠', 'Mental Health'),
    ('skincare',     '✨', 'Skincare & Glow'),
    ('social',       '💬', 'Healthy Friendships'),
    ('reproductive', '🔬', 'Reproductive Health'),
    ('financial',    '💸', 'Money & Life Skills'),
    ('creativity',   '🎨', 'Creativity & Arts'),
  ];

  void _toggle(String key) {
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else {
        _selected.add(key);
        if (_selected.length == 3) {
          if (mounted) setState(() => _showPoints = true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 8,
      totalSteps: 11,
      onBack: () => context.go('/onboarding/period-status'),
      bottomBar: Stack(
        clipBehavior: Clip.none,
        children: [
          GradientButton(
            label: _selected.isEmpty
                ? 'Pick Your Interests'
                : 'Explore My Universe (${_selected.length}) 🌟',
            onPressed: () async {
              final bloc = context.read<OnboardingBloc>();
              bloc.add(SetInterestTopics(_selected.toList()));
              bloc.add(const SubmitPersonalization());

              if (mounted) {
                setState(() => _showPoints = true);
                await bloc.stream.firstWhere((state) => !state.isLoading);
                if (context.mounted) {
                  context.go('/onboarding/terms');
                }
              }
            },
            enabled: _selected.isNotEmpty,
          ),
          if (_showPoints && _selected.length >= 3)
            Positioned(
              top: -50,
              right: 20,
              child: PointsBurst(
                points: 20,
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
                'What topics light you up? 🌟',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pick everything that interests you — we customize your feed!',
                style: TextStyle(color: AppColors.textMedium, fontSize: 15),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.7,
                children: _topics.asMap().entries.map((e) {
                  final t = e.value;
                  final isSelected = _selected.contains(t.$1);
                  return GestureDetector(
                    onTap: () => _toggle(t.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                ? AppColors.purple.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.02),
                            blurRadius: isSelected ? 8 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(t.$2, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.$3,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: isSelected ? Colors.white : AppColors.textDark,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: e.key * 40)).fadeIn(duration: 180.ms);
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
