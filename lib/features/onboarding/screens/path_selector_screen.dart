import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';

class PathSelectorScreen extends StatefulWidget {
  const PathSelectorScreen({super.key});

  @override
  State<PathSelectorScreen> createState() => _PathSelectorScreenState();
}

class _PathSelectorScreenState extends State<PathSelectorScreen> {
  int? _selected;

  Future<void> _select(int index) async {
    setState(() => _selected = index);
    final storage = await LocalStorageService.create();
    await storage.setUserType(index == 0 ? 'teen' : 'parent');
    await storage.setStepComplete('0.5');
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (index == 0) {
      context.go('/onboarding/name');
    } else {
      // Parent path — placeholder
      context.go('/onboarding/name');
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 1,
      totalSteps: 13,
      onBack: () => context.go('/splash'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text('Who are you?',
              style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            const Text('Choose the right path for you 💜',
              style: TextStyle(color: AppColors.textLight, fontSize: 16)),
            const SizedBox(height: 40),
            ...[
              _PathCard(
                emoji: '🌸',
                title: "I'm a Girl or Young Woman",
                subtitle: 'Ages 10–24',
                selected: _selected == 0,
                onTap: () => _select(0),
              ),
              const SizedBox(height: 16),
              _PathCard(
                emoji: '👨‍👧',
                title: "I'm a Parent or Guardian",
                subtitle: 'Set up for my daughter',
                selected: _selected == 1,
                onTap: () => _select(1),
              ),
            ].asMap().entries.map((e) =>
              e.value.animate(delay: Duration(milliseconds: 200 + e.key * 150))
                .fadeIn(duration: 300.ms).slideY(begin: 0.1, duration: 300.ms)),
          ],
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({required this.emoji, required this.title, required this.subtitle, required this.selected, required this.onTap});
  final String emoji, title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(selected ? 1.04 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.purple : const Color(0xFFE9D5FF),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: selected ? [BoxShadow(color: AppColors.purple.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))] : null,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textDark)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.purple, size: 28),
          ],
        ),
      ),
    );
  }
}
