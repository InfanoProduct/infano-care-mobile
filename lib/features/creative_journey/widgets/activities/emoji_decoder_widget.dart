import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

/// EmojiDecoderWidget — "Timeline Decoder Wheel"
/// Interactive 3D Spinning Wheel where users spin the wheel to land on each segment and reveal questions!
class EmojiDecoderWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const EmojiDecoderWidget({super.key, required this.content, required this.onCompleted});

  @override
  State<EmojiDecoderWidget> createState() => _EmojiDecoderWidgetState();
}

class _EmojiDecoderWidgetState extends State<EmojiDecoderWidget>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String? _selectedEmoji;
  bool _revealed = false;
  bool _isCompleting = false;
  bool _hasSpun = false;
  bool _isSpinning = false;

  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  double _baseRotation = 0.0;
  double _currentRotation = 0.0;
  double _targetRotation = 0.0;

  List<Map<String, dynamic>> get _scenarios =>
      List<Map<String, dynamic>>.from(widget.content['scenarios'] as List? ?? []);

  Map<String, dynamic> get _current => _scenarios[_currentIndex];

  static const List<Color> _wheelColors = [
    Color(0xFFFCE7F3), // Soft Pink
    Color(0xFFEDE9FE), // Soft Purple
    Color(0xFFDBEAFE), // Soft Blue
    Color(0xFFFFF7ED), // Soft Peach
    Color(0xFFD1FAE5), // Soft Mint
    Color(0xFFFFE4E6), // Soft Rose
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.decelerate,
    )..addListener(() {
        setState(() {
          _currentRotation = _baseRotation + (_spinAnimation.value * (_targetRotation - _baseRotation));
        });
      });

    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        AppSoundService.instance.playCorrect();
        HapticFeedback.heavyImpact();
        setState(() {
          _baseRotation = _currentRotation;
          _isSpinning = false;
          _hasSpun = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning) return;
    AppSoundService.instance.playPop();
    HapticFeedback.mediumImpact();

    final n = max(_scenarios.length, 1);
    final k = _currentIndex % n;

    // Exact angle required to position segment k center under top pointer (at 12 o'clock / -pi/2):
    // Segment k spans from [k*2pi/N - pi/2] to [(k+1)*2pi/N - pi/2]
    // Segment k center = k*2pi/N - pi/2 + pi/N = (2k + 1)*pi/N - pi/2
    // Rotating by theta clockwise moves center to: (2k + 1)*pi/N - pi/2 + theta = 3pi/2 (or -pi/2)
    // theta = 2pi - (2k + 1)*pi/N
    final targetSegmentAngle = (2 * pi) - ((2 * k + 1) * pi / n);

    // Calculate incremental delta rotation required from current wheel position plus 4 full spins
    final currentMod = _baseRotation % (2 * pi);
    double delta = targetSegmentAngle - currentMod;
    if (delta <= 0) delta += (2 * pi);

    // 4 full 360-degree rotations (8 * pi) + exact alignment delta
    _targetRotation = _baseRotation + (8 * pi) + delta;

    setState(() {
      _isSpinning = true;
      _hasSpun = false;
    });

    _spinController.forward(from: 0.0);
  }

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
        _hasSpun = false;
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
      return Center(
        child: Text(
          'No scenarios available.',
          style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textMedium),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFDBA74)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('🎡', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.content['title'] as String? ?? 'Timeline Decoder Wheel 🎭',
                        style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF9A3412)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.content['instruction'] as String? ?? 'Spin the wheel to land on each segment and reveal questions!',
                        style: GoogleFonts.nunito(fontSize: 12.5, color: AppColors.textMedium, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Progress indicator
          Row(
            children: List.generate(scenarios.length, (i) {
              Color color = const Color(0xFFE5E7EB);
              if (i < _currentIndex) color = const Color(0xFF8B5CF6);
              if (i == _currentIndex) color = const Color(0xFFA78BFA);
              return Expanded(
                child: AnimatedContainer(
                  duration: 300.ms,
                  height: 6,
                  margin: EdgeInsets.only(right: i < scenarios.length - 1 ? 5 : 0),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: i <= _currentIndex
                        ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            'Question ${_currentIndex + 1} of ${scenarios.length}',
            style: GoogleFonts.nunito(fontSize: 11.5, color: AppColors.textLight, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),

          // ── INTERACTIVE SPINNING WHEEL WIDGET (Matching exact segments!) ────
          _buildWheelSection(scenarios),

          const SizedBox(height: 24),

          // ── UNLOCKED QUESTION CARD & OPTIONS (Reveals after landing!) ────────
          if (_hasSpun) ...[
            AnimatedSwitcher(
              duration: 400.ms,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: Column(
                  children: [
                    _buildSceneCard(),
                    const SizedBox(height: 18),
                    _buildEmojiGrid(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Gigi Feedback
            if (_revealed) ...[
              _buildFeedback(),
              const SizedBox(height: 24),
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
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentIndex < scenarios.length - 1 ? 'Spin for Question ${_currentIndex + 2} →' : 'Continue Journey • Collect 🪙 Coins',
                        style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentIndex < scenarios.length - 1 ? Icons.autorenew_rounded : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            ],
          ],
        ],
      ),
    );
  }

  // ── SPIN WHEEL SECTION (Exact Segments) ──────────────────────────────────────
  Widget _buildWheelSection(List<Map<String, dynamic>> scenarios) {
    final emojis = scenarios.map((s) => s['sceneEmoji'] as String? ?? '📖').toList();

    return Column(
      children: [
        SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Golden Ring Rim Shadow
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3E8FF), Color(0xFFDDD6FE), Color(0xFFC4B5FD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA78BFA).withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),

              // Rotating Wheel
              Transform.rotate(
                angle: _currentRotation,
                child: SizedBox(
                  width: 224,
                  height: 224,
                  child: CustomPaint(
                    painter: _SpinWheelPainter(
                      emojis: emojis,
                      colors: _wheelColors,
                    ),
                  ),
                ),
              ),

              // Center SPIN Button Badge
              GestureDetector(
                onTap: _isSpinning ? null : _spinWheel,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                    ),
                    border: Border.all(color: const Color(0xFFFDBA74), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isSpinning
                          ? 'SPINNING...'
                          : (_hasSpun ? 'SPIN AGAIN 🎡' : 'TAP TO\nSPIN 🎡'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF9A3412),
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ),

              // Top Pointer Ticker (📍 Arrow pointing down into wheel segment)
              Positioned(
                top: 2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Action Prompt below Wheel
        if (!_hasSpun && !_isSpinning)
          GestureDetector(
            onTap: _spinWheel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Spin for Question ${_currentIndex + 1}!',
                    style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.97, 0.97), end: const Offset(1.03, 1.03), duration: 1000.ms),
      ],
    );
  }

  // ── SCENE CARD ───────────────────────────────────────────────────────────────
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
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.08),
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
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  character,
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF9A3412)),
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

  // ── EMOJI GRID ───────────────────────────────────────────────────────────────
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
          borderColor = const Color(0xFFF97316);
          bgColor = const Color(0xFFFFF7ED);
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

  // ── GIGI FEEDBACK CARD ───────────────────────────────────────────────────────
  Widget _buildFeedback() {
    final correct = _current['correctEmoji'] as String? ?? '';
    final isRight = _selectedEmoji == correct;
    final gigiResponse = _current['gigiResponse'] as String? ?? '';
    final wrongResponse = _current['wrongResponse'] as String? ?? gigiResponse;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRight ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRight ? const Color(0xFF34D399) : const Color(0xFFFDBA74),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isRight ? '🌸' : '💡', style: const TextStyle(fontSize: 22)),
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
                    color: isRight ? const Color(0xFF065F46) : const Color(0xFF9A3412),
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
                    style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF9A3412)),
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

// ── CUSTOM PAINTER FOR SPINNING WHEEL SECTORS ─────────────────────────────────
class _SpinWheelPainter extends CustomPainter {
  final List<String> emojis;
  final List<Color> colors;

  _SpinWheelPainter({required this.emojis, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final n = max(emojis.length, 1);
    final sweepAngle = (2 * pi) / n;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 3.0;

    for (int i = 0; i < n; i++) {
      final startAngle = (i * sweepAngle) - (pi / 2);
      paint.color = colors[i % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Render Emojis in Sector Centers
      final textAngle = startAngle + (sweepAngle / 2);
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(text: emojis[i], style: const TextStyle(fontSize: 26)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - (textPainter.width / 2), textY - (textPainter.height / 2)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpinWheelPainter oldDelegate) => true;
}
