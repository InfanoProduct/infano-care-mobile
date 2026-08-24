import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

/// BodyAppreciationJarWidget — "My Body's Superpower Jar"
///
/// Brand-New Activity Type 3 for Episode 6:
/// Users collect appreciation gems into a glowing glass jar — celebrating what their body
/// DOES every single day (walking, breathing, laughing, drawing, hugging).
/// Features animated gem drops, sound effects, sparkling particle bursts, and completion banner.
class BodyAppreciationJarWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const BodyAppreciationJarWidget({
    super.key,
    required this.content,
    required this.onCompleted,
  });

  @override
  State<BodyAppreciationJarWidget> createState() => _BodyAppreciationJarWidgetState();
}

class _BodyAppreciationJarWidgetState extends State<BodyAppreciationJarWidget>
    with TickerProviderStateMixin {
  late final ConfettiController _confettiCtrl;
  late final AnimationController _sparkleCtrl;
  late final AnimationController _lidCtrl;

  late final List<_BodySuperpowerGem> _gems;
  final Set<String> _collectedGemIds = {};
  bool _isJarHovered = false;
  bool _showResults = false;
  bool _isCompleting = false;

  static const List<List<Color>> _gemPastelGradients = [
    [Color(0xFFF3E8FF), Color(0xFFEDE9FE)], // Pastel Purple / Lavender
    [Color(0xFFFCE7F3), Color(0xFFFDF2F8)], // Pastel Rose / Pink
    [Color(0xFFE0F2FE), Color(0xFFF0F9FF)], // Soft Pastel Sky Blue
    [Color(0xFFCCFBF1), Color(0xFFF0FDFA)], // Soft Pastel Mint
  ];

  int get _maxCapacity => (widget.content['maxCapacity'] as int?) ?? 4;

  List<Map<String, dynamic>> get _rawGems =>
      List<Map<String, dynamic>>.from(
        widget.content['gems'] as List? ?? widget.content['slips'] as List? ?? [],
      );

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 4));
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _lidCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _gems = (_rawGems.map(_BodySuperpowerGem.fromMap).toList())..shuffle();
    if (_gems.isEmpty) {
      _gems.addAll(List.from(_defaultFallbackGems)..shuffle());
    }
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _sparkleCtrl.dispose();
    _lidCtrl.dispose();
    super.dispose();
  }

  void _collectGem(_BodySuperpowerGem gem) {
    if (_collectedGemIds.contains(gem.id)) return;
    if (_collectedGemIds.length >= _maxCapacity) return;

    if (!gem.isCorrect) {
      AppSoundService.instance.playIncorrect();
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🙅‍♀️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  gem.rejectionHint ??
                      'Oops! Negative habits don\'t belong in your Appreciation Jar! Choose a positive body gem instead ✨',
                  style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    AppSoundService.instance.playGemDrop();
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();

    // Trigger lid pop animation
    _lidCtrl.forward(from: 0).then((_) => _lidCtrl.reverse());

    setState(() {
      _collectedGemIds.add(gem.id);
      _isJarHovered = false;
    });

    if (_collectedGemIds.length >= _maxCapacity) {
      Future.delayed(const Duration(milliseconds: 650), () {
        AppSoundService.instance.playBunchOfCoinsSound();
        _confettiCtrl.play();
        setState(() => _showResults = true);
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
                _buildJarProgressMeter(),
                const SizedBox(height: 18),
                _buildInteractiveGlassJar(),
                const SizedBox(height: 22),
                _buildGemsSelectorArea(),
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
          const Text('🫙', style: TextStyle(fontSize: 34))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.15, duration: 1200.ms, curve: Curves.easeInOut),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.content['title'] as String? ?? 'My Body\'s Superpower Jar',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.content['instruction'] as String? ??
                      'Drag, flick or tap each superpower gem to drop it into your body gratitude jar!',
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

  Widget _buildJarProgressMeter() {
    final pct = _maxCapacity == 0 ? 0.0 : (_collectedGemIds.length / _maxCapacity).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${_collectedGemIds.length} / $_maxCapacity Gems 💎',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveGlassJar() {
    final collectedList = _gems.where((g) => _collectedGemIds.contains(g.id)).toList();

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isJarHovered = true);
        _lidCtrl.forward();
        return true;
      },
      onLeave: (_) {
        setState(() => _isJarHovered = false);
        _lidCtrl.reverse();
      },
      onAcceptWithDetails: (details) {
        final gem = _gems.firstWhere((g) => g.id == details.data, orElse: () => _gems.first);
        _collectGem(gem);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedBuilder(
          animation: _sparkleCtrl,
          builder: (context, child) {
            final auraGlow = 0.12 + _sparkleCtrl.value * 0.15;
            final isHovered = candidateData.isNotEmpty || _isJarHovered;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 270,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isHovered
                      ? [const Color(0xFFEDE9FE), const Color(0xFFFCE7F3)]
                      : [const Color(0xFFF8F5FF), const Color(0xFFFDF2F8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: isHovered ? AppColors.purple : AppColors.purple.withValues(alpha: 0.35),
                  width: isHovered ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: isHovered ? 0.35 : auraGlow),
                    blurRadius: isHovered ? 30 : 20,
                    spreadRadius: isHovered ? 4 : 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. ANIMATED CORK LID
                  AnimatedBuilder(
                    animation: _lidCtrl,
                    builder: (context, child) {
                      final lidOffsetY = -10.0 * _lidCtrl.value;
                      final lidAngle = 0.08 * _lidCtrl.value;
                      return Transform.translate(
                        offset: Offset(0, lidOffsetY),
                        child: Transform.rotate(
                          angle: lidAngle,
                          child: Container(
                            width: 110,
                            height: 18,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFDDD6FE), Color(0xFFC4B5FD)],
                              ),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.purple.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '🌸 CORK LID 🌸',
                                style: GoogleFonts.nunito(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.purple,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // 2. GLASS JAR INNER CHAMBER
                  Container(
                    constraints: const BoxConstraints(minHeight: 160),
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
                    ),
                    child: collectedList.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🫙', style: TextStyle(fontSize: 40))
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .scaleXY(begin: 1.0, end: 1.1, duration: 1000.ms),
                              const SizedBox(height: 8),
                              Text(
                                'Jar is empty!\nDrag or tap gems below to fill ✨',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: collectedList.asMap().entries.map((e) {
                              final g = e.value;
                              final gradient =
                                  _gemPastelGradients[e.key % _gemPastelGradients.length];

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: gradient),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.purple.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(g.emoji, style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 5),
                                    Text(
                                      g.shortLabel,
                                      style: GoogleFonts.nunito(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  .animate(key: ValueKey('injar_${g.id}'))
                                  .scale(duration: 350.ms, curve: Curves.elasticOut)
                                  .fadeIn(duration: 200.ms);
                            }).toList(),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGemsSelectorArea() {
    final uncollected = _gems.where((g) => !_collectedGemIds.contains(g.id)).toList();

    if (uncollected.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            Text(
              'All Superpower Gems Collected!',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF047857),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).scale(curve: Curves.elasticOut);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Superpower Gems (${uncollected.length} remaining):',
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            Text(
              'Drag or Tap 👆',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Column(
          children: uncollected.asMap().entries.map((e) {
            final gem = e.value;
            final gradient = _gemPastelGradients[e.key % _gemPastelGradients.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Draggable<String>(
                data: gem.id,
                onDragStarted: () => AppSoundService.instance.playPop(),
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 320,
                    child: _buildGemCard(gem, gradient, isDragging: true),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: _buildGemCard(gem, gradient),
                ),
                child: GestureDetector(
                  onTap: () => _collectGem(gem),
                  child: _buildGemCard(gem, gradient),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGemCard(_BodySuperpowerGem gem, List<Color> gradient, {bool isDragging = false}) {
    return Container(
      key: ValueKey('gem_${gem.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDragging ? AppColors.purple : AppColors.purple.withValues(alpha: 0.25),
          width: isDragging ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: isDragging ? 0.22 : 0.08),
            blurRadius: isDragging ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.12),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Text(gem.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gem.shortLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  gem.actionText,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMedium,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.purple,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 2),
                Text(
                  'JAR',
                  style: GoogleFonts.nunito(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey('gem_wrap_${gem.id}')).fadeIn(duration: 250.ms);
  }

  Widget _buildResultsScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                const Text('🫙', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 10),
                Text(
                  'Gratitude Jar Full!',
                  style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.content['completionMessage'] as String? ?? 'Your body is not something to constantly inspect. It\'s the home that carries you through life!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(fontSize: 13.5, color: AppColors.textMedium, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ..._gems.where((g) => _collectedGemIds.contains(g.id)).map((g) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Text(g.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    g.actionText,
                    style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark),
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
              ],
            ),
          )),

          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (!_isCompleting) {
                AppSoundService.instance.playBunchOfCoinsSound();
                setState(() => _isCompleting = true);
                widget.onCompleted();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6D28D9).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    'Collect 🪙 Coins & Continue!',
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodySuperpowerGem {
  final String id;
  final String emoji;
  final String shortLabel;
  final String actionText;
  final bool isCorrect;
  final String? rejectionHint;

  _BodySuperpowerGem({
    required this.id,
    required this.emoji,
    required this.shortLabel,
    required this.actionText,
    this.isCorrect = true,
    this.rejectionHint,
  });

  factory _BodySuperpowerGem.fromMap(Map<String, dynamic> m) => _BodySuperpowerGem(
        id: m['id'] as String? ?? '',
        emoji: m['emoji'] as String? ?? '🌸',
        shortLabel: m['shortLabel'] as String? ?? m['category'] as String? ?? m['title'] as String? ?? 'Body Appreciation',
        actionText: m['actionText'] as String? ?? m['text'] as String? ?? m['shortLabel'] as String? ?? '',
        isCorrect: (m['isCorrect'] as bool?) ?? !(m['isBluff'] as bool? ?? false),
        rejectionHint: m['rejectionHint'] as String? ?? m['distractorNote'] as String? ?? m['hint'] as String?,
      );
}

final List<_BodySuperpowerGem> _defaultFallbackGems = [
  _BodySuperpowerGem(
    id: "g1",
    emoji: "🦵",
    shortLabel: "Walking & Exploring",
    actionText: "My legs carry me everywhere I want to explore",
  ),
  _BodySuperpowerGem(
    id: "g2",
    emoji: "🎨",
    shortLabel: "Creating & Drawing",
    actionText: "My hands let me sketch, write, and create art",
  ),
  _BodySuperpowerGem(
    id: "g3",
    emoji: "🫁",
    shortLabel: "Breathing Deeply",
    actionText: "My lungs keep me energized without me even thinking",
  ),
  _BodySuperpowerGem(
    id: "g4",
    emoji: "🤗",
    shortLabel: "Hugging Friends",
    actionText: "My arms give comforting hugs to the people I love",
  ),
  _BodySuperpowerGem(
    id: "g5",
    emoji: "😊",
    shortLabel: "Smiling & Laughing",
    actionText: "My face shares joy and laughter with my family",
  ),
];
