import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';

class PathSelectorScreen extends StatefulWidget {
  const PathSelectorScreen({super.key});

  @override
  State<PathSelectorScreen> createState() => _PathSelectorScreenState();
}

class _PathSelectorScreenState extends State<PathSelectorScreen> {
  int? _selected;

  Future<void> _select(int index) async {
    setState(() => _selected = index);

    final cleanRole = (index == 0) ? 'TEEN' : 'PARENT';
    try {
      await ApiService.instance.dio.patch('/user/role', data: {'role': cleanRole});
    } catch (e) {
      debugPrint('[PathSelectorScreen] Failed to update role: $e');
    }

    final storage = await LocalStorageService.create();
    await storage.setUserType(index == 0 ? 'teen' : 'parent');
    await storage.setRole(cleanRole);
    await storage.setStepComplete('0.5');
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    context.go('/onboarding/name');
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 1,
      totalSteps: 11,
      onBack: () => context.go('/splash'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Who are you? ✨',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your journey path to get personalized support.',
                style: TextStyle(color: AppColors.textMedium, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 32),
              ...[
                _PathCard(
                  emoji: '🌸',
                  title: "I'm a Girl or Young Woman",
                  subtitle: 'Ages 10–24 • Learn, track, and blossom',
                  selected: _selected == 0,
                  onTap: () => _select(0),
                ),
                const SizedBox(height: 16),
                _PathCard(
                  emoji: '👨‍👧',
                  title: "I'm a Parent or Guardian",
                  subtitle: 'Set up guidance and care for my child',
                  selected: _selected == 1,
                  onTap: () => _select(1),
                ),
              ].asMap().entries.map(
                    (e) => e.value
                        .animate(delay: Duration(milliseconds: 150 + e.key * 100))
                        .fadeIn(duration: 250.ms)
                        .slideY(begin: 0.08, duration: 250.ms),
                  ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String emoji, title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.purple : const Color(0xFFE9D5FF),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? AppColors.purple.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.03),
              blurRadius: selected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: selected ? AppColors.purple.withValues(alpha: 0.1) : const Color(0xFFFAF5FF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: selected ? AppColors.purple : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textMedium, fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? AppColors.purple : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.purple : const Color(0xFFD8B4FE),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
