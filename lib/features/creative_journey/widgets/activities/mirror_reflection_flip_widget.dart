import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

/// MirrorReflectionFlipWidget — "The Mirror Perspective Shifter"
///
/// Brand-New Activity Type 1 for Episode 6:
/// Users flip critical mirror thoughts into empowering body-gratitude & reality-check perspectives!
/// Features 3D flip card animation, mirror shine particle effects, sound feedback, and progress tracking.
class MirrorReflectionFlipWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const MirrorReflectionFlipWidget({
    super.key,
    required this.content,
    required this.onCompleted,
  });

  @override
  State<MirrorReflectionFlipWidget> createState() => _MirrorReflectionFlipWidgetState();
}

class _MirrorReflectionFlipWidgetState extends State<MirrorReflectionFlipWidget>
    with TickerProviderStateMixin {
  late final ConfettiController _confettiCtrl;
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;
  late final AnimationController _sparkleCtrl;

  late final List<_MirrorCardData> _cards;
  final Set<int> _flippedIndices = {};
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _showResults = false;
  bool _isCompleting = false;

  List<Map<String, dynamic>> get _rawCards =>
      List<Map<String, dynamic>>.from(widget.content['cards'] as List? ?? []);

  bool get _allFlipped => _flippedIndices.length >= _cards.length;
  _MirrorCardData get _currentCard => _cards[_currentIndex];

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 4));

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutBack),
    );

    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _cards = _rawCards.map(_MirrorCardData.fromMap).toList();
    if (_cards.isEmpty) {
      _cards.addAll(_defaultFallbackCards);
    }
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _flipCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  void _flipMirror() {
    if (_flipCtrl.isAnimating) return;

    if (!_isFlipped) {
      AppSoundService.instance.playCorrect();
      HapticFeedback.mediumImpact();
      _flipCtrl.forward().then((_) {
        setState(() {
          _isFlipped = true;
          _flippedIndices.add(_currentIndex);
        });

        if (_allFlipped) {
          Future.delayed(const Duration(milliseconds: 650), () {
            AppSoundService.instance.playFanfare();
            _confettiCtrl.play();
            setState(() => _showResults = true);
          });
        }
      });
    } else {
      AppSoundService.instance.playPop();
      HapticFeedback.lightImpact();
      _flipCtrl.reverse().then((_) {
        setState(() => _isFlipped = false);
      });
    }
  }

  void _nextCard() {
    if (_currentIndex + 1 < _cards.length) {
      AppSoundService.instance.playPop();
      _flipCtrl.reset();
      setState(() {
        _currentIndex++;
        _isFlipped = _flippedIndices.contains(_currentIndex);
        if (_isFlipped) _flipCtrl.value = 1.0;
      });
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      AppSoundService.instance.playPop();
      _flipCtrl.reset();
      setState(() {
        _currentIndex--;
        _isFlipped = _flippedIndices.contains(_currentIndex);
        if (_isFlipped) _flipCtrl.value = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) return _buildResultsScreen();

    return Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildCardStepperDots(),
                const SizedBox(height: 18),
                _buildVanityMagicMirror(),
                const SizedBox(height: 20),
                _buildActionControls(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 40,
            gravity: 0.22,
            colors: const [
              Color(0xFF7C3AED), Color(0xFFEC4899),
              Color(0xFF10B981), Color(0xFF60A5FA), Color(0xFFA78BFA),
            ],
          ),
        ),
      ],
    );
  }

  // ── 🎨 HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🪞', style: TextStyle(fontSize: 34))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.15, duration: 1300.ms, curve: Curves.easeInOut),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.content['title'] as String? ?? 'The Mirror Perspective Shifter',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.content['instruction'] as String? ??
                      'Tap or swipe the magic mirror to flip critical thoughts into empowering reality checks!',
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    color: AppColors.textMedium,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08);
  }

  // ── 📊 STEPPER DOTS ───────────────────────────────────────────────────────
  Widget _buildCardStepperDots() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_cards.length, (i) {
              final isSelected = i == _currentIndex;
              final isFlipped = _flippedIndices.contains(i);

              return GestureDetector(
                onTap: () {
                  if (i != _currentIndex) {
                    AppSoundService.instance.playPop();
                    _flipCtrl.reset();
                    setState(() {
                      _currentIndex = i;
                      _isFlipped = isFlipped;
                      if (_isFlipped) _flipCtrl.value = 1.0;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isSelected ? 28 : 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: isFlipped
                        ? const Color(0xFF10B981)
                        : (isSelected ? AppColors.purple : AppColors.purple.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isFlipped && isSelected
                      ? const Center(
                          child: Icon(Icons.check, size: 9, color: Colors.white),
                        )
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${_flippedIndices.length} of ${_cards.length} Shifting Perspectives ✨',
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: AppColors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 🪞 VANITY MAGIC MIRROR 3D WIDGET ──────────────────────────────────────
  Widget _buildVanityMagicMirror() {
    return GestureDetector(
      onTap: _flipMirror,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100) {
            _nextCard();
          } else if (details.primaryVelocity! > 100) {
            _prevCard();
          }
        }
      },
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (context, child) {
          final angle = _flipAnim.value * math.pi;
          final isFront = angle < math.pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // Realistic perspective depth
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFront
                ? _buildMirrorFrame(isFront: true)
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildMirrorFrame(isFront: false),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildMirrorFrame({required bool isFront}) {
    final card = _currentCard;

    return AnimatedBuilder(
      animation: _sparkleCtrl,
      builder: (context, child) {
        final auraGlow = 0.12 + _sparkleCtrl.value * 0.16;

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 310),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isFront
                  ? [const Color(0xFFFDF2F8), const Color(0xFFFCE7F3)] // Soft Pastel Rose
                  : [const Color(0xFFF0FDFA), const Color(0xFFE0F2FE)], // Soft Pastel Mint & Blue
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(80),
              topRight: Radius.circular(80),
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            border: Border.all(
              color: isFront ? const Color(0xFFF472B6) : const Color(0xFF10B981),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isFront ? const Color(0xFFF472B6) : const Color(0xFF10B981))
                    .withValues(alpha: auraGlow),
                blurRadius: 26,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Glass sheen reflection diagonal stripe
              Positioned(
                top: 0,
                right: 20,
                width: 80,
                height: 300,
                child: Transform.rotate(
                  angle: 0.35,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Mirror Content Container
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top Pill Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFront ? const Color(0xFFFCE7F3) : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isFront
                              ? const Color(0xFFF472B6).withValues(alpha: 0.5)
                              : const Color(0xFF10B981).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isFront ? '🪞 INSECURITY THOUGHT' : '✨ PERSPECTIVE SHIFT',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isFront ? const Color(0xFFBE185D) : const Color(0xFF047857),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Emoji Avatar Container
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isFront ? const Color(0xFFF472B6) : const Color(0xFF10B981))
                                .withValues(alpha: 0.2),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isFront ? card.thoughtEmoji : card.perspectiveEmoji,
                          style: const TextStyle(fontSize: 42),
                        ),
                      ),
                    )
                        .animate(key: ValueKey('${isFront}_${card.id}'))
                        .scale(duration: 350.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 16),

                    // Statement Text Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isFront
                              ? const Color(0xFFF472B6).withValues(alpha: 0.25)
                              : const Color(0xFF10B981).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        isFront ? card.thoughtText : card.perspectiveText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: isFront ? const Color(0xFF9F1239) : const Color(0xFF065F46),
                          height: 1.45,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Flip Prompt Hint Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 16,
                          color: isFront ? const Color(0xFFBE185D) : const Color(0xFF047857),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isFront
                                ? 'Tap or swipe mirror to shift perspective! 🔄'
                                : 'Tap mirror to flip back 🔄',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isFront ? const Color(0xFFBE185D) : const Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 🕹️ ACTION CONTROLS ───────────────────────────────────────────────────
  Widget _buildActionControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous Card Button
        IconButton.filledTonal(
          onPressed: _currentIndex > 0 ? _prevCard : null,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.purple.withValues(alpha: 0.1),
            foregroundColor: AppColors.purple,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 8),

        // Primary Flip Button (Dark Purple)
        Expanded(
          child: GestureDetector(
            onTap: _flipMirror,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.purple,
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
                  const Text('🪞', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _isFlipped ? 'Shifted! ✨' : 'Shift Perspective 🔄',
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Next Card Button
        IconButton.filledTonal(
          onPressed: _currentIndex + 1 < _cards.length ? _nextCard : null,
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.purple.withValues(alpha: 0.1),
            foregroundColor: AppColors.purple,
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  // ── 🏆 RESULTS SUMMARY SCREEN ─────────────────────────────────────────────
  Widget _buildResultsScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Celebration Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('🪞', style: TextStyle(fontSize: 56))
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 12),
                Text(
                  'Perspective Shift Complete! ✨',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.content['completionMessage'] as String? ??
                      'You learned to reframe critical mirror thoughts into body gratitude and realistic self-compassion!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          // Shifted Perspectives List
          ..._cards.asMap().entries.map((e) {
            final c = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(c.perspectiveEmoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.perspectiveText,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                ],
              ),
            ).animate().fadeIn(delay: (e.key * 75).ms, duration: 300.ms);
          }),

          const SizedBox(height: 20),

          // CTA Continue Button
          GestureDetector(
            onTap: () {
              if (!_isCompleting) {
                setState(() => _isCompleting = true);
                widget.onCompleted();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Collect 🪙 Coins & Continue!',
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 350.ms),
        ],
      ),
    );
  }
}

class _MirrorCardData {
  final String id;
  final String thoughtEmoji;
  final String thoughtText;
  final String perspectiveEmoji;
  final String perspectiveText;

  _MirrorCardData({
    required this.id,
    required this.thoughtEmoji,
    required this.thoughtText,
    required this.perspectiveEmoji,
    required this.perspectiveText,
  });

  factory _MirrorCardData.fromMap(Map<String, dynamic> m) => _MirrorCardData(
        id: m['id'] as String? ?? '',
        thoughtEmoji: m['thoughtEmoji'] as String? ?? '😟',
        thoughtText: m['thoughtText'] as String? ?? m['thought'] as String? ?? '',
        perspectiveEmoji: m['perspectiveEmoji'] as String? ?? '✨',
        perspectiveText: m['perspectiveText'] as String? ?? m['perspective'] as String? ?? '',
      );
}

final List<_MirrorCardData> _defaultFallbackCards = [
  _MirrorCardData(
    id: "mc1",
    thoughtEmoji: "😟",
    thoughtText: "\"Why do my jeans feel tighter than they did a few months ago?\"",
    perspectiveEmoji: "✨",
    perspectiveText: "My bones and body are growing on schedule — tighter clothes mean my body is building its healthy adult structure!",
  ),
  _MirrorCardData(
    id: "mc2",
    thoughtEmoji: "🔍",
    thoughtText: "\"I don't look like the flawless girls on my social media feed.\"",
    perspectiveEmoji: "🌸",
    perspectiveText: "Feeds are edited highlight reels! Real bodies have texture, curves, and unique shapes — and that's perfectly normal.",
  ),
  _MirrorCardData(
    id: "mc3",
    thoughtEmoji: "😔",
    thoughtText: "\"I wish I could change how my body looks right now.\"",
    perspectiveEmoji: "💖",
    perspectiveText: "My body carries me through life, lets me laugh, paint, run, and hug. I choose body gratitude over mirror inspection!",
  ),
];
