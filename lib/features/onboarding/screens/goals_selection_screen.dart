import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
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
    ('career',     '📚', 'School & Career'),
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
    setState(() => _showPoints = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) context.go('/onboarding/period-comfort');
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 7,
      bottomBar: Stack(
        clipBehavior: Clip.none,
        children: [
          GradientButton(label: 'Continue', onPressed: _continue, enabled: _selected.isNotEmpty),
          if (_showPoints)
            Positioned(top: -50, right: 20, child: PointsBurst(points: 15, onComplete: () => setState(() => _showPoints = false))),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text('What would you love help with? 💭', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.4,
              children: _goals.asMap().entries.map((e) {
                final g = e.value;
                final isSelected = _selected.contains(g.$1);
                return GestureDetector(
                  onTap: () => _toggle(g.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.identity()..scale(isSelected ? 1.04 : 1.0),
                    transformAlignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppGradients.brand : AppGradients.softCard,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected ? [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(g.$2, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text(g.$3, textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                            color: isSelected ? Colors.white : AppColors.textDark)),
                        if (isSelected) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ).animate(delay: Duration(milliseconds: e.key * 60)).fadeIn(duration: 250.ms).scale(begin: const Offset(0.9, 0.9), duration: 250.ms);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
