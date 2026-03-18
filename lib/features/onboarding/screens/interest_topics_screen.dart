import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/shared/widgets/points_burst.dart';

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
        if (_selected.length == 3) setState(() => _showPoints = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 10,
      bottomBar: Stack(
        clipBehavior: Clip.none,
        children: [
          GradientButton(
            label: 'Show Me My Universe 🌟',
            onPressed: () {
              setState(() => _showPoints = true);
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) context.go('/onboarding/avatar');
              });
            },
            enabled: _selected.isNotEmpty,
          ),
          if (_showPoints && _selected.length >= 3)
            Positioned(top: -50, right: 20, child: PointsBurst(points: 20, onComplete: () => setState(() => _showPoints = false))),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text('What topics light you up? 🌟', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text('Pick all that interest you — we\'ll personalise your feed!', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: _topics.asMap().entries.map((e) {
                  final t = e.value;
                  final isSelected = _selected.contains(t.$1);
                  return GestureDetector(
                    onTap: () => _toggle(t.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(isSelected ? 1.04 : 1.0),
                      transformAlignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppGradients.brand : AppGradients.softCard,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(t.$2, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(t.$3,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12,
                              color: isSelected ? Colors.white : AppColors.textDark))),
                          if (isSelected) const Icon(Icons.check_circle, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: e.key * 50)).fadeIn(duration: 200.ms);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
