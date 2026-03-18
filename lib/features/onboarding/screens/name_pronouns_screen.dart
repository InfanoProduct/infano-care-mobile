import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/points_burst.dart';

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

  static const _pronouns = ['She / Her', 'She / They', 'They / Them'];

  bool get _valid => _controller.text.trim().length >= 2;

  void _onNameChanged(String value) {
    setState(() {});
    if (value.length >= 2 && !_pointsAwarded) {
      setState(() { _showPoints = true; _pointsAwarded = true; });
    }
  }

  Future<void> _continue() async {
    final storage = await LocalStorageService.create();
    await storage.setDisplayName(_controller.text.trim());
    await storage.setPronouns(_pronoun);
    await storage.setPoints(10);
    await storage.setStageComplete('1');
    if (mounted) context.go('/onboarding/birthday');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text('What should we call you? 👋',
                style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('Your first name or nickname works great!',
                style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              // Name input with points burst
              Stack(
                clipBehavior: Clip.none,
                children: [
                  TextField(
                    controller: _controller,
                    maxLength: 30,
                    onChanged: _onNameChanged,
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: 'Your first name or nickname',
                    ),
                  ),
                  if (_showPoints)
                    Positioned(
                      top: -50, right: 12,
                      child: PointsBurst(
                        points: 10,
                        onComplete: () => setState(() => _showPoints = false),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              Text('Your pronouns (optional)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: _pronouns.map((p) =>
                  GestureDetector(
                    onTap: () => setState(() => _pronoun = _pronoun == p ? null : p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: _pronoun == p ? AppGradients.brand : null,
                        color: _pronoun == p ? null : AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: _pronoun == p ? Colors.transparent : const Color(0xFFE9D5FF),
                          width: 1.5,
                        ),
                      ),
                      child: Text(p,
                        style: TextStyle(
                          color: _pronoun == p ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        )),
                    ),
                  ),
                ).toList(),
              ),
              const SizedBox(height: 8),
              Text('You can always change this later.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textLight)),
              const Spacer(),
              GradientButton(
                label: 'Continue',
                onPressed: _continue,
                enabled: _valid,
              ),
              const SizedBox(height: 32),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
}
