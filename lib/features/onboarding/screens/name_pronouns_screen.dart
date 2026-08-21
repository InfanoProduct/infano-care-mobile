import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/points_burst.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:provider/provider.dart';

class NamePronounsScreen extends StatefulWidget {
  const NamePronounsScreen({super.key});

  @override
  State<NamePronounsScreen> createState() => _NamePronounsScreenState();
}

class _NamePronounsScreenState extends State<NamePronounsScreen> {
  final _controller = TextEditingController();
  String? _pronoun;
  bool _showPoints = false;
  bool _pointsAwarded = false;

  @override
  void initState() {
    super.initState();
    final storage = context.read<LocalStorageService>();
    if (storage.displayName != null && storage.displayName!.isNotEmpty) {
      _controller.text = storage.displayName!;
      _pointsAwarded = true;
    }
    _pronoun = storage.pronouns;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _pronouns = ['She / Her', 'She / They', 'They / Them', 'Prefer not to say'];

  bool get _valid => _controller.text.trim().length >= 2;

  void _onNameChanged(String value) {
    setState(() {});
    if (value.trim().length >= 2 && !_pointsAwarded) {
      if (mounted) setState(() { _showPoints = true; _pointsAwarded = true; });
    }
  }

  Future<void> _continue() async {
    final storage = await LocalStorageService.create();
    await storage.setDisplayName(_controller.text.trim());
    await storage.setPronouns(_pronoun);
    await storage.setPoints(10);
    if (mounted) context.go('/onboarding/birthday');
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 2,
      totalSteps: 11,
      onBack: () {
        final storage = context.read<LocalStorageService>();
        final role = storage.role;
        if (role != null) {
          context.go('/splash');
        } else {
          context.go('/onboarding/path');
        }
      },
      bottomBar: GradientButton(
        label: 'Continue',
        onPressed: _continue,
        enabled: _valid,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'What should we call you? 👋',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your first name or favorite nickname works great!',
                style: TextStyle(color: AppColors.textMedium, fontSize: 15),
              ),
              const SizedBox(height: 32),
              // Name input with points burst
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLength: 30,
                      onChanged: _onNameChanged,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'e.g. Maya or Alex',
                        hintStyle: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.normal),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.purple),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE9D5FF), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE9D5FF), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.purple, width: 2),
                        ),
                      ),
                    ),
                  ),
                  if (_showPoints)
                    Positioned(
                      top: -50,
                      right: 12,
                      child: PointsBurst(
                        points: 10,
                        onComplete: () {
                          if (mounted) setState(() => _showPoints = false);
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Your pronouns (optional)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _pronouns.map((p) {
                  final isSelected = _pronoun == p;
                  return GestureDetector(
                    onTap: () => setState(() => _pronoun = isSelected ? null : p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.purple : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.purple : const Color(0xFFE9D5FF),
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.purple.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'You can always update this later in your profile.',
                style: TextStyle(color: AppColors.textLight, fontSize: 13),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
        ),
      ),
    );
  }
}
