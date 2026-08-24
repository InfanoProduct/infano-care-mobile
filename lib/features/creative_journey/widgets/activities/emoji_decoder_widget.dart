import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

/// EmojiDecoderWidget — "Rule Secret Decoder Wheel"
/// Interactive 3D Spinning Wheel where users spin the wheel to land on each sector (Rule 1, Rule 2, Rule 3, Rule 4),
/// unlock secrets, and collect coins!
class EmojiDecoderWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const EmojiDecoderWidget({
    super.key,
    required this.content,
    required this.onCompleted,
  });

  @override
  State<EmojiDecoderWidget> createState() => _EmojiDecoderWidgetState();
}

class _EmojiDecoderWidgetState extends State<EmojiDecoderWidget>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final Set<int> _unlockedIndices = {};
  String? _selectedOption;
  bool _answered = false;
  bool _isSpinning = false;
  bool _hasSpun = false;

  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  double _baseRotation = 0.0;
  double _currentRotation = 0.0;
  double _targetRotation = 0.0;

  List<Map<String, dynamic>> get _scenarios => List<Map<String, dynamic>>.from(
    widget.content['scenarios'] as List? ?? [],
  );

  Map<String, dynamic> get _current =>
      _scenarios.isNotEmpty ? _scenarios[_currentIndex] : {};

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
      duration: const Duration(milliseconds: 2600),
    );

    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.decelerate,
    )..addListener(() {
      setState(() {
        _currentRotation =
            _baseRotation +
            (_spinAnimation.value * (_targetRotation - _baseRotation));
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
          _unlockedIndices.add(_currentIndex);
        });
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  int _getNextTargetIndex() {
    final n = max(_scenarios.length, 1);
    for (int i = 0; i < n; i++) {
      int idx = (_currentIndex + i) % n;
      if (!_unlockedIndices.contains(idx)) {
        return idx;
      }
    }
    return (_currentIndex + 1) % n;
  }

  void _spinWheel() {
    if (_isSpinning) return;
    AppSoundService.instance.playPop();
    HapticFeedback.mediumImpact();

    final n = max(_scenarios.length, 1);
    final targetIndex = _hasSpun ? _getNextTargetIndex() : 0;

    // Angle required to position segment k center under top pointer (at 12 o'clock / -pi/2):
    // Segment k spans from [k*2pi/N - pi/2] to [(k+1)*2pi/N - pi/2]
    // Segment k center = k*2pi/N - pi/2 + pi/N = (2k + 1)*pi/N - pi/2
    // Rotating by theta clockwise moves center to: (2k + 1)*pi/N - pi/2 + theta = 3pi/2 (or -pi/2)
    // theta = 2pi - (2k + 1)*pi/N
    final targetSegmentAngle = (2 * pi) - ((2 * targetIndex + 1) * pi / n);

    final currentMod = _baseRotation % (2 * pi);
    double delta = targetSegmentAngle - currentMod;
    if (delta <= 0) delta += (2 * pi);

    // 4 full 360-degree spins (8 * pi) + alignment delta
    _targetRotation = _baseRotation + (8 * pi) + delta;

    setState(() {
      _currentIndex = targetIndex;
      _isSpinning = true;
      _hasSpun = false;
      _selectedOption = null;
      _answered = false;
    });

    _spinController.forward(from: 0.0);
  }

  void _onOptionTap(String option) {
    if (_answered) return;
    AppSoundService.instance.playPop();
    setState(() {
      _selectedOption = option;
      _answered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scenarios = _scenarios;
    if (scenarios.isEmpty) {
      return Center(
        child: Text(
          'No rules available.',
          style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textMedium),
        ),
      );
    }

    final totalRules = scenarios.length;
    final allUnlocked = _unlockedIndices.length >= totalRules;

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
                        widget.content['title'] as String? ??
                            'Secret Decoder Wheel 🎭',
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF9A3412),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.content['instruction'] as String? ??
                            'Spin the wheel to land on each sector and unlock all 4 secret rules!',
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          color: AppColors.textMedium,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rule Unlocked Progress Tracker
          Row(
            children: List.generate(totalRules, (i) {
              bool isUnlocked = _unlockedIndices.contains(i);
              bool isCurrent = i == _currentIndex && _hasSpun;

              Color color = const Color(0xFFE5E7EB);
              if (isUnlocked) color = const Color(0xFF10B981);
              if (isCurrent) color = const Color(0xFF8B5CF6);

              return Expanded(
                child: AnimatedContainer(
                  duration: 300.ms,
                  height: 8,
                  margin: EdgeInsets.only(right: i < totalRules - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow:
                        isUnlocked || isCurrent
                            ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ]
                            : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            '${_unlockedIndices.length} of $totalRules Rules Unlocked 🔑',
            style: GoogleFonts.nunito(
              fontSize: 11.5,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),

          // ── INTERACTIVE SPINNING WHEEL (Rule 1, Rule 2, Rule 3, Rule 4) ────────
          _buildWheelSection(scenarios),

          const SizedBox(height: 24),

          // ── SECRET REVEALED CARD BELOW WHEEL ───────────────────────────────────
          if (_hasSpun) ...[
            AnimatedSwitcher(
              duration: 400.ms,
              transitionBuilder:
                  (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: Column(
                  children: [
                    _buildSecretRuleCard(),
                    const SizedBox(height: 16),

                    // Interactive Question (if provided)
                    if (_current['question'] != null) ...[
                      _buildQuestionSection(),
                      const SizedBox(height: 16),
                    ],

                    // Gigi's Tip / Secret Explanation
                    _buildGigiTipCard(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // CTA Button: "Spin Again for Next Rule" OR "Collect 🪙 Coins"
            GestureDetector(
              onTap: () {
                if (allUnlocked) {
                  AppSoundService.instance.playBunchOfCoinsSound();
                  widget.onCompleted();
                } else {
                  _spinWheel();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        allUnlocked
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : [
                              const Color(0xFF8B5CF6),
                              const Color(0xFF6D28D9),
                            ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (allUnlocked
                              ? const Color(0xFF10B981)
                              : AppColors.purple)
                          .withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      allUnlocked
                          ? 'All 4 Rules Unlocked! Collect 🪙 Coins'
                          : 'Spin for Rule ${_getNextTargetIndex() + 1} 🎡',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      allUnlocked
                          ? Icons.stars_rounded
                          : Icons.autorenew_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          ],
        ],
      ),
    );
  }

  // ── SPIN WHEEL SECTION (Rules 1-4 with Icons) ──────────────────────────────
  Widget _buildWheelSection(List<Map<String, dynamic>> scenarios) {
    final emojis = scenarios.map((s) => s['emoji'] as String? ?? '📖').toList();
    final ruleLabels =
        scenarios.asMap().entries.map((e) {
          final rNum = e.value['ruleNumber'] ?? (e.key + 1);
          return 'Rule $rNum';
        }).toList();

    return Column(
      children: [
        SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ring Glow
              Container(
                width: 242,
                height: 242,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF3E8FF),
                      Color(0xFFDDD6FE),
                      Color(0xFFC4B5FD),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA78BFA).withValues(alpha: 0.3),
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
                  width: 226,
                  height: 226,
                  child: CustomPaint(
                    painter: _SpinWheelPainter(
                      emojis: emojis,
                      ruleLabels: ruleLabels,
                      colors: _wheelColors,
                    ),
                  ),
                ),
              ),

              // Center SPIN Button Badge
              GestureDetector(
                onTap: _isSpinning ? null : _spinWheel,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFDBA74),
                      width: 3.5,
                    ),
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

              // Top Pointer Ticker (📍 Arrow pointing down into wheel sector)
              Positioned(
                top: 2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
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
                        'Spin for Rule ${_currentIndex + 1}!',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.97, 0.97),
                end: const Offset(1.03, 1.03),
                duration: 1000.ms,
              ),
      ],
    );
  }

  // ── SECRET RULE CARD ────────────────────────────────────────────────────────
  Widget _buildSecretRuleCard() {
    final emoji = _current['emoji'] as String? ?? '🔑';
    final rNum = _current['ruleNumber'] ?? (_currentIndex + 1);
    final title = _current['title'] as String? ?? 'Rule $rNum Secret';
    final description = _current['description'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.1),
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
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  '🔑 Secret Rule $rNum Unlocked!',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF9A3412),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                color: AppColors.textDark,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── INTERACTIVE QUESTION SECTION ────────────────────────────────────────────
  Widget _buildQuestionSection() {
    final question = _current['question'] as String? ?? '';
    final options = List<String>.from(_current['emojiOptions'] as List? ?? []);
    final correct =
        _current['correctEmoji'] as String? ??
        (options.isNotEmpty ? options.first : '');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('❓', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                options.map((opt) {
                  bool isSelected = _selectedOption == opt;
                  bool isCorrect = opt == correct;

                  Color border = const Color(0xFFE5E7EB);
                  Color bg = Colors.white;

                  if (_answered) {
                    if (isCorrect) {
                      border = const Color(0xFF10B981);
                      bg = const Color(0xFFECFDF5);
                    } else if (isSelected && !isCorrect) {
                      border = const Color(0xFFEF4444);
                      bg = const Color(0xFFFEF2F2);
                    }
                  }

                  return GestureDetector(
                    onTap: () => _onOptionTap(opt),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            opt,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (_answered && isCorrect) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // ── GIGI TIP CARD ───────────────────────────────────────────────────────────
  Widget _buildGigiTipCard() {
    final explanation = _current['explanation'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF34D399), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌸', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gigi\'s Secret Tip:',
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF065F46),
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

// ── CUSTOM PAINTER FOR SPINNING WHEEL SECTORS (Rule 1, Rule 2, Rule 3, Rule 4) ─
class _SpinWheelPainter extends CustomPainter {
  final List<String> emojis;
  final List<String> ruleLabels;
  final List<Color> colors;

  _SpinWheelPainter({
    required this.emojis,
    required this.ruleLabels,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final n = max(emojis.length, 1);
    final sweepAngle = (2 * pi) / n;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: 0.95)
          ..strokeWidth = 3.0;

    for (int i = 0; i < n; i++) {
      final startAngle = (i * sweepAngle) - (pi / 2);
      paint.color = colors[i % colors.length];

      // Draw sector arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw sector border line
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Render Emoji + Rule Text (e.g. "📐\nRule 1") inside sector center
      final textAngle = startAngle + (sweepAngle / 2);
      final textRadius = radius * 0.62;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);

      final emojiStr = emojis[i];
      final ruleStr = ruleLabels[i];

      final textSpan = TextSpan(
        children: [
          TextSpan(text: '$emojiStr\n', style: const TextStyle(fontSize: 22)),
          TextSpan(
            text: ruleStr,
            style: GoogleFonts.nunito(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF78350F),
              height: 1.1,
            ),
          ),
        ],
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          textX - (textPainter.width / 2),
          textY - (textPainter.height / 2),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpinWheelPainter oldDelegate) => true;
}
