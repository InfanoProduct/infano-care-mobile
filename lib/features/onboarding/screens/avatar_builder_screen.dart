import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/shared/widgets/points_burst.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';

/// Simplified SVG-layer avatar builder.
class AvatarBuilderScreen extends StatefulWidget {
  const AvatarBuilderScreen({super.key});

  @override
  State<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends State<AvatarBuilderScreen> {
  int _bodyType   = 0;
  int _skinTone   = 0;
  int _hairStyle  = 0;
  final int _hairColor  = 0;
  int _outfit     = 0;
  int _category   = 0;
  bool _showPoints = false;

  static const _categories = ['Body', 'Hair', 'Skin', 'Outfit'];
  static const _skinTones  = [0xFFFFDBAC, 0xFFF5CBA7, 0xFFD4965A, 0xFFAD6F3B, 0xFF7B4F2E, 0xFF4B2E10];
  static const _outfitEmojis = ['👕', '🩱', '👗', '🧥', '👚', '🩴'];
  static const _bodyEmojis   = ['🌸', '🌺', '🌻', '🌼', '🌷', '💐'];
  static const _hairEmojis   = ['💁', '👩', '👩‍🦱', '👩‍🦰', '👩‍🦳', '👩‍🦲'];

  Widget _buildPreview() {
    return Container(
      width: 160,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(80),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_hairEmojis[_hairStyle], style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 4),
          Text(_bodyEmojis[_bodyType], style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 4),
          Text(_outfitEmojis[_outfit], style: const TextStyle(fontSize: 28)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 9,
      totalSteps: 13,
      onBack: () => context.go('/onboarding/interests'),
      bottomBar: Stack(
        clipBehavior: Clip.none,
        children: [
          GradientButton(
            label: 'This Is Me! 💜',
            onPressed: () async {
              final bloc = context.read<OnboardingBloc>();
              bloc.add(SetAvatar({
                'bodyType': _bodyType,
                'skinTone': _skinTone,
                'hairStyle': _hairStyle,
                'hairColor': _hairColor,
                'outfit': _outfit,
              }));
              bloc.add(const SubmitAvatar());

              if (mounted) {
                setState(() => _showPoints = true);
                await bloc.stream.firstWhere((state) => !state.isLoading);
                if (context.mounted) {
                  context.go('/onboarding/journey-name');
                }
              }
            },
          ),
          if (_showPoints)
            Positioned(
              top: -50,
              right: 20,
              child: PointsBurst(
                points: 25,
                onComplete: () {
                  if (mounted) setState(() => _showPoints = false);
                },
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Build your Bloom Avatar ✨',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Center(child: _buildPreview().animate().scaleXY(begin: 0.8, duration: 500.ms, curve: Curves.easeOutBack)),
              const SizedBox(height: 24),
              // Category tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.asMap().entries.map((e) {
                    final isSelected = _category == e.key;
                    return GestureDetector(
                      onTap: () => setState(() => _category = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.purple : AppColors.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected ? AppColors.purple : const Color(0xFFE9D5FF),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          e.value,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _getCategoryItems().asMap().entries.map((e) {
                  final item = e.value;
                  final isColor = _isColor(item);
                  final isCurrent = _getCurrentIndex() == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _setCategory(e.key)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isColor ? Color(item as int) : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent ? AppColors.purple : const Color(0xFFE9D5FF),
                          width: isCurrent ? 2.5 : 1,
                        ),
                      ),
                      child: isColor ? null : Center(child: Text(item as String, style: const TextStyle(fontSize: 24))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<Object> _getCategoryItems() {
    switch (_category) {
      case 0: return _bodyEmojis;
      case 1: return _hairEmojis;
      case 2: return _skinTones.map((c) => c as Object).toList();
      case 3: return _outfitEmojis;
      default: return _bodyEmojis;
    }
  }

  bool _isColor(Object v) => v is int;

  int _getCurrentIndex() {
    switch (_category) {
      case 0: return _bodyType;
      case 1: return _hairStyle;
      case 2: return _skinTone;
      case 3: return _outfit;
      default: return 0;
    }
  }

  void _setCategory(int index) {
    switch (_category) {
      case 0: _bodyType  = index; break;
      case 1: _hairStyle = index; break;
      case 2: _skinTone  = index; break;
      case 3: _outfit    = index; break;
    }
  }
}
