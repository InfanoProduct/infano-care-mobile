import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

/// ScenarioChoiceWidget — "What Would You Say?"
/// Users step into Nadia's shoes and choose how to respond to their friend
/// Meera going through her first period. Multi-scenario branching with
/// Gigi's warm feedback after each choice.
class ScenarioChoiceWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const ScenarioChoiceWidget({super.key, required this.content, required this.onCompleted});

  @override
  State<ScenarioChoiceWidget> createState() => _ScenarioChoiceWidgetState();
}

class _ScenarioChoiceWidgetState extends State<ScenarioChoiceWidget> {
  int _currentIndex = 0;
  int? _selectedChoice;
  bool _revealed = false;
  bool _isCompleting = false;

  List<Map<String, dynamic>> get _scenarios =>
      List<Map<String, dynamic>>.from(widget.content['scenarios'] as List? ?? []);

  Map<String, dynamic> get _current => _scenarios[_currentIndex];

  List<Map<String, dynamic>> get _choices =>
      List<Map<String, dynamic>>.from(_current['choices'] as List? ?? []);

  void _onChoiceTap(int idx) {
    if (_revealed) return;
    AppSoundService.instance.playPop();
    setState(() {
      _selectedChoice = idx;
      _revealed = true;
    });
  }

  void _onNext() {
    if (_currentIndex < _scenarios.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedChoice = null;
        _revealed = false;
      });
    } else {
      AppSoundService.instance.playCorrect();
      setState(() => _isCompleting = true);
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scenarios = _scenarios;
    if (scenarios.isEmpty) {
      return Center(child: Text('No scenarios available.', style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textMedium)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFCE7F3), Color(0xFFFDF2F8)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFBCFE8)),
            ),
            child: Row(
              children: [
                const Text('💬', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.content['title'] as String? ?? 'What Would You Say?',
                        style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF9D174D)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.content['instruction'] as String? ?? 'Choose how you\'d respond to your friend.',
                        style: GoogleFonts.nunito(fontSize: 12.5, color: AppColors.textMedium, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Progress
          Row(
            children: List.generate(scenarios.length, (i) {
              Color color = const Color(0xFFE5E7EB);
              if (i < _currentIndex) color = const Color(0xFF10B981);
              if (i == _currentIndex) color = const Color(0xFFDB2777);
              return Expanded(
                child: AnimatedContainer(
                  duration: 300.ms,
                  height: 5,
                  margin: EdgeInsets.only(right: i < scenarios.length - 1 ? 5 : 0),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: i <= _currentIndex
                        ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 5),
          Text(
            'Moment ${_currentIndex + 1} of ${scenarios.length}',
            style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),

          // Scenario card with slide animation between scenarios
          AnimatedSwitcher(
            duration: 400.ms,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey<int>(_currentIndex),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScenarioCard(),
                  const SizedBox(height: 16),
                  _buildChoices(),
                  if (_revealed) ...[
                    const SizedBox(height: 16),
                    _buildFeedback(),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _isCompleting ? null : _onNext,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDB2777).withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          _currentIndex < scenarios.length - 1 ? 'Next Moment →' : '✨ Finish Activity',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard() {
    final rolePrompt = _current['rolePrompt'] as String? ?? 'You are Nadia. What do you say?';
    final situation = _current['situation'] as String? ?? '';
    final situationEmoji = _current['situationEmoji'] as String? ?? '📖';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              rolePrompt,
              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF7C3AED), letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(situationEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  situation,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your response:',
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textMedium),
        ),
        const SizedBox(height: 10),
        ..._choices.asMap().entries.map((entry) {
          final idx = entry.key;
          final choice = entry.value;
          final choiceText = choice['text'] as String? ?? '';
          final isBest = (choice['isBest'] as bool?) ?? false;
          final isSelected = _selectedChoice == idx;

          Color bgColor = Colors.white;
          Color borderColor = const Color(0xFFE5E7EB);
          Widget? badge;

          if (_revealed) {
            if (isBest) {
              bgColor = const Color(0xFFECFDF5);
              borderColor = const Color(0xFF10B981);
              badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, color: Color(0xFF059669), size: 12),
                  const SizedBox(width: 3),
                  Text('Best', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF047857))),
                ]),
              );
            } else if (isSelected && !isBest) {
              bgColor = const Color(0xFFFEF9C3);
              borderColor = const Color(0xFFFBBF24);
            }
          } else if (isSelected) {
            bgColor = const Color(0xFFFCE7F3);
            borderColor = const Color(0xFFDB2777);
          }

          return GestureDetector(
            onTap: () => _onChoiceTap(idx),
            child: AnimatedContainer(
              duration: 250.ms,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + idx), // A, B, C
                        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900, color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      choiceText,
                      style: GoogleFonts.nunito(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark, height: 1.4),
                    ),
                  ),
                  if (badge != null) ...[const SizedBox(width: 8), badge],
                ],
              ),
            ),
          ).animate().fadeIn(delay: (idx * 80).ms, duration: 300.ms).slideX(begin: 0.05);
        }),
      ],
    );
  }

  Widget _buildFeedback() {
    final selected = _selectedChoice;
    if (selected == null) return const SizedBox.shrink();

    final choice = _choices[selected];
    final isBest = (choice['isBest'] as bool?) ?? (choice['isCorrect'] as bool?) ?? false;
    final gigiResponse = (choice['gigiResponse'] as String?) ??
        (choice['gigiSays'] as String?) ??
        (choice['feedback'] as String?) ??
        (choice['gigiInsight'] as String?) ??
        (choice['explanation'] as String?) ??
        (_current['gigiResponse'] as String?) ??
        (_current['gigiSays'] as String?) ??
        (_current['feedback'] as String?) ??
        'Gigi loves that you took time to reflect on this response! 💖';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBest ? const Color(0xFFECFDF5) : const Color(0xFFFDF2F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBest ? const Color(0xFF10B981) : const Color(0xFFF472B6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isBest ? const Color(0xFF10B981) : const Color(0xFFF472B6)).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Text('🌸', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Gigi Says:',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isBest ? const Color(0xFF047857) : const Color(0xFFBE185D),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isBest ? const Color(0xFFD1FAE5) : const Color(0xFFFCE7F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isBest ? '🌟 Wise Choice' : '💖 Helpful Reflection',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isBest ? const Color(0xFF047857) : const Color(0xFFBE185D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  gigiResponse,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isBest ? const Color(0xFF064E3B) : const Color(0xFF881337),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08);
  }
}
