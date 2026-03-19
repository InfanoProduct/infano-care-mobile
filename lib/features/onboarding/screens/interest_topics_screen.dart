import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
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
    ('puberty',    '🌺', 'Puberty & Body Changes'),
    ('period',     '🩸', 'Period Health'),
    ('nutrition',  '🥗', 'Food & Nutrition'),
    ('fitness',    '💪', 'Exercise & Fitness'),
    ('emotional',  '🧠', 'Mental Health'),
    ('skincare',   '✨', 'Skincare & Beauty'),
    ('social',     '💬', 'Healthy Friendships'),
    ('reproductive', '🔬', 'Reproductive Health'),
    ('financial',  '💸', 'Money Basics'),
    ('creativity', '🎨', 'Art & Creativity'),
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
      currentStep: 7,
      bottomBar: Stack(
        clipBehavior: Clip.none,
        children: [
          GradientButton(
            label: 'Show Me My Universe 🌟',
            onPressed: () {
              final bloc = context.read<OnboardingBloc>();
              bloc.add(SetInterestTopics(_selected.toList()));

              if (mounted) {
                setState(() => _showPoints = true);
                context.go('/onboarding/avatar');
              }
            },
            enabled: _selected.isNotEmpty,
          ),
          if (_showPoints && _selected.length >= 3)
            Positioned(
              top: -50, right: 20, 
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
              const SizedBox(height: 16),
              Text('What topics light you up? 🌟', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('Pick all that interest you!', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                children: _topics.asMap().entries.map((e) {
                  final t = e.value;
                  final isSelected = _selected.contains(t.$1);
                  return GestureDetector(
                    onTap: () => _toggle(t.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(isSelected ? 1.04 : 1.0),
                      transformAlignment: Alignment.center,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppGradients.brand : AppGradients.softCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Text(t.$2, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(t.$3,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11,
                              color: isSelected ? Colors.white : AppColors.textDark))),
                          if (isSelected) const Icon(Icons.check_circle, color: Colors.white, size: 14),
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
