import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

/// EmojiDecoderWidget — "Meera's Panic Decoder"
/// Users see a story scene card and tap which emoji best captures the character's feeling.
/// After each answer, Gigi gives a warm, validating response.
class EmojiDecoderWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const EmojiDecoderWidget({super.key, required this.content, required this.onCompleted});

  @override
  State<EmojiDecoderWidget> createState() => _EmojiDecoderWidgetState();
}

class _EmojiDecoderWidgetState extends State<EmojiDecoderWidget> {
  int _currentIndex = 0;
  String? _selectedEmoji;
  bool _revealed = false;
  bool _isCompleting = false;

  List<Map<String, dynamic>> get _scenarios =>
      List<Map<String, dynamic>>.from(widget.content['scenarios'] as List? ?? []);

  Map<String, dynamic> get _current => _scenarios[_currentIndex];

  void _onEmojiTap(String emoji) {
    if (_revealed) return;
    AppSoundService.instance.playPop();
    setState(() {
      _selectedEmoji = emoji;
      _revealed = true;
    });
  }

  void _onNext() {
    if (_currentIndex < _scenarios.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedEmoji = null;
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFBCFE8)),
            ),
            child: Row(
              children: [
                const Text('🎭', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.content['title'] as String? ?? 'Panic Decoder',
                        style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF9D174D)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.content['instruction'] as String? ?? 'Tap the emoji that best matches the feeling!',
                        style: GoogleFonts.nunito(fontSize: 12.5, color: AppColors.textMedium, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Progress bar
          Row(
            children: List.generate(scenarios.length, (i) {
              Color color = const Color(0xFFE5E7EB);
              if (i < _currentIndex) color = const Color(0xFFDB2777);
              if (i == _currentIndex) color = const Color(0xFFEC4899);
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
            'Scene ${_currentIndex + 1} of ${scenarios.length}',
            style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),

          // Scene Card
          AnimatedSwitcher(
            duration: 350.ms,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey<int>(_currentIndex),
              child: _buildSceneCard(),
            ),
          ),
          const SizedBox(height: 18),

          // Emoji Options
          _buildEmojiGrid(),

          // Gigi Feedback
          if (_revealed) ...[
            const SizedBox(height: 16),
            _buildFeedback(),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _isCompleting
                  ? null
                  : () {
                      AppSoundService.instance.playPop();
                      HapticFeedback.selectionClick();
                      _onNext();
                    },
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentIndex < scenarios.length - 1 ? 'Next Scene →' : 'Continue Journey • Collect XP ⭐',
                      style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    if (_currentIndex < scenarios.length - 1) ...[
                      const SizedBox(width: 6),
                    ] else ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          ],
        ],
      ),
    );
  }

  Widget _buildSceneCard() {
    final character = _current['character'] as String? ?? 'Character';
    final scene = _current['scene'] as String? ?? '';
    final sceneEmoji = _current['sceneEmoji'] as String? ?? '📖';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFBCFE8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDB2777).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(sceneEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  character,
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF9D174D)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '"$scene"',
            style: GoogleFonts.nunito(fontSize: 14.5, color: AppColors.textDark, height: 1.6, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 14),
          Text(
            'How was she feeling in this moment?',
            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiGrid() {
    final options = List<String>.from(_current['options'] as List? ?? []);
    final correct = _current['correctEmoji'] as String? ?? '';

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: options.map((emoji) {
        bool isSelected = _selectedEmoji == emoji;
        bool isCorrect = emoji == correct;
        Color borderColor = const Color(0xFFE5E7EB);
        Color bgColor = Colors.white;

        if (_revealed) {
          if (isCorrect) {
            borderColor = const Color(0xFF10B981);
            bgColor = const Color(0xFFECFDF5);
          } else if (isSelected && !isCorrect) {
            borderColor = const Color(0xFFEF4444);
            bgColor = const Color(0xFFFEF2F2);
          }
        } else if (isSelected) {
          borderColor = const Color(0xFFDB2777);
          bgColor = const Color(0xFFFCE7F3);
        }

        return GestureDetector(
          onTap: () => _onEmojiTap(emoji),
          child: AnimatedContainer(
            duration: 250.ms,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: isSelected
                  ? [BoxShadow(color: borderColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: isSelected ? 28 : 24),
                  ),
                ),
                if (_revealed && isCorrect)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (options.indexOf(emoji) * 50).ms, duration: 300.ms).scale(begin: const Offset(0.85, 0.85));
      }).toList(),
    );
  }

  Widget _buildFeedback() {
    final correct = _current['correctEmoji'] as String? ?? '';
    final isRight = _selectedEmoji == correct;
    final gigiResponse = _current['gigiResponse'] as String? ?? '';
    final wrongResponse = _current['wrongResponse'] as String? ?? gigiResponse;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRight ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRight ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isRight ? '🌸' : '💛', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRight ? 'Gigi agrees!' : 'Gigi says:',
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: isRight ? const Color(0xFF065F46) : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRight ? gigiResponse : wrongResponse,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isRight ? const Color(0xFF065F46) : const Color(0xFF78350F),
                    height: 1.45,
                  ),
                ),
                if (!isRight) ...[
                  const SizedBox(height: 8),
                  Text(
                    'The feeling was $correct — and that\'s perfectly valid.',
                    style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08);
  }
}
