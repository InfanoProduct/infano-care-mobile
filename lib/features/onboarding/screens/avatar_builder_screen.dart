import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/shared/widgets/points_burst.dart';

/// Simplified SVG-layer avatar builder.
/// Replace the emoji placeholders with illustrated SVG layers when assets are available.
class AvatarBuilderScreen extends StatefulWidget {
  const AvatarBuilderScreen({super.key});

  @override
  State<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends State<AvatarBuilderScreen> {
  int _bodyType   = 0;
  int _skinTone   = 0;
  int _hairStyle  = 0;
  int _hairColor  = 0;
  int _outfit     = 0;
  int _category   = 0;
  bool _showPoints = false;

  static const _categories = ['Body', 'Hair', 'Skin', 'Outfit'];
  static const _skinTones  = [0xFFFFDBAC, 0xFFF5CBA7, 0xFFD4965A, 0xFFAD6F3B, 0xFF7B4F2E, 0xFF4B2E10];
  static const _hairColors = [0xFF3B1F0A, 0xFF7B4F2E, 0xFFF6C522, 0xFFFF4D4D, 0xFFAD6FD9, 0xFF000000];
  static const _outfitEmojis = ['👕', '🩱', '👗', '🧥', '👚', '🩴'];
  static const _bodyEmojis   = ['🌸', '🌺', '🌻', '🌼', '🌷', '💐'];
  static const _hairEmojis   = ['💁', '👩', '👩‍🦱', '👩‍🦰', '👩‍🦳', '👩‍🦲'];

  Widget _buildPreview() {
    return Container(
      width: 160, height: 220,
      decoration: BoxDecoration(
        gradient: AppGradients.softCard,
        borderRadius: BorderRadius.circular(80),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_hairEmojis[_hairStyle], style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 4),
          Text(_bodyEmojis[_bodyType], style: const TextStyle(fontSize: 48)),
          Text(_outfitEmojis[_outfit], style: const TextStyle(fontSize: 28)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 11,
      bottomBar: Stack(
        clipBehavior: Clip.none,
        children: [
          GradientButton(
            label: 'This Is Me! 💜',
            onPressed: () {
              setState(() => _showPoints = true);
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) context.go('/onboarding/journey-name');
              });
            },
          ),
          if (_showPoints)
            Positioned(top: -50, right: 20, child: PointsBurst(points: 25, onComplete: () => setState(() => _showPoints = false))),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text('Build your Bloom Avatar ✨', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            // Preview
            Center(child: _buildPreview().animate().scaleXY(begin: 0.8, duration: 500.ms, curve: Curves.elasticOut)),
            const SizedBox(height: 24),
            // Category tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.asMap().entries.map((e) =>
                  GestureDetector(
                    onTap: () => setState(() => _category = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: _category == e.key ? AppGradients.brand : null,
                        color: _category == e.key ? null : AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(e.value, style: TextStyle(color: _category == e.key ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ).toList(),
              ),
            ),
            const SizedBox(height: 20),
            // Swatch grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: _getCategoryItems().asMap().entries.map((e) =>
                  GestureDetector(
                    onTap: () => setState(() => _setCategory(e.key)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isColor(e.value) ? Color(e.value as int) : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getCurrentIndex() == e.key ? AppColors.purple : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: _isColor(e.value) ? null : Center(child: Text(e.value as String, style: const TextStyle(fontSize: 24))),
                    ),
                  ),
                ).toList(),
              ),
            ),
          ],
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
