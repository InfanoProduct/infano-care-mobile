import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

/// 4-flap sealed box. Learner taps a flap → 3D tear & unfold animation reveals content.
/// All 4 must be opened to complete the node.
class MysteryTaskBoxWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const MysteryTaskBoxWidget({
    super.key,
    required this.content,
    required this.onCompleted,
  });

  @override
  State<MysteryTaskBoxWidget> createState() => _MysteryTaskBoxWidgetState();
}

class _MysteryTaskBoxWidgetState extends State<MysteryTaskBoxWidget> {
  final Set<int> _openedFlaps = {};
  final Map<int, int?> _selectedAnswers = {};
  bool _isCompleting = false;

  List<Map<String, dynamic>> get flaps =>
      List<Map<String, dynamic>>.from(widget.content['flaps'] as List? ?? []);

  @override
  Widget build(BuildContext context) {
    final totalFlaps = flaps.length;
    final openedCount = _openedFlaps.length;
    final allOpened = openedCount >= totalFlaps && totalFlaps > 0;
    final progress = totalFlaps > 0 ? (openedCount / totalFlaps).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── GAMIFIED HEADER WITH PROGRESS BAR ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text('📦', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '$openedCount of $totalFlaps Unlocked',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDBA74)),
                      ),
                      child: Row(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(
                            '+${widget.content['coinsReward'] ?? widget.content['xpReward'] ?? 10} Coins',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF9A3412),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('🎁', style: TextStyle(fontSize: 48))
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: const Offset(0.94, 0.94), end: const Offset(1.06, 1.06), duration: 1200.ms),
                const SizedBox(height: 8),
                Text(
                  "What's in the Growth Box?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.content['instruction'] as String? ??
                      'Tap each sealed flap to tear it open and reveal the secret inside!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textMedium,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 4 FLAP CARDS WITH CREATIVE 3D UNSEAL ANIMATION ─────────────────────
          ...List.generate(flaps.length, (i) {
            final flap = flaps[i];
            final isOpen = _openedFlaps.contains(i);
            // Sticker reward (flap 4) only unlocks after first 3 are opened
            final isLocked = i == 3 && _openedFlaps.length < 3;

            return _FlapCard(
              flap: flap,
              index: i,
              isOpen: isOpen,
              isLocked: isLocked,
              selectedAnswer: _selectedAnswers[i],
              onTap: isLocked
                  ? null
                  : () => setState(() => _openedFlaps.add(i)),
              onAnswerSelected: (ans) =>
                  setState(() => _selectedAnswers[i] = ans),
            ).animate().fadeIn(delay: (i * 80).ms, duration: 300.ms).slideY(begin: 0.1);
          }),

          const SizedBox(height: 20),

          // ── COMPLETE BUTTON WITH PRIMARY BRAND STYLING ──────────────────────
          if (allOpened)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isCompleting
                    ? null
                    : () {
                        AppSoundService.instance.playPop();
                        HapticFeedback.selectionClick();
                        setState(() => _isCompleting = true);
                        widget.onCompleted();
                      },
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
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
                      if (_isCompleting) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Unlocking Discovery Chest... 🗝️',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Continue Journey • Collect 🪙 Coins',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
                      ],
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

// ── CREATIVE 3D FLAP CARD WITH TEAR & UNFOLD ANIMATION ────────────────────────

class _FlapCard extends StatefulWidget {
  final Map<String, dynamic> flap;
  final int index;
  final bool isOpen;
  final bool isLocked;
  final int? selectedAnswer;
  final VoidCallback? onTap;
  final void Function(int)? onAnswerSelected;

  const _FlapCard({
    required this.flap,
    required this.index,
    required this.isOpen,
    required this.isLocked,
    this.selectedAnswer,
    this.onTap,
    this.onAnswerSelected,
  });

  @override
  State<_FlapCard> createState() => _FlapCardState();
}

class _FlapCardState extends State<_FlapCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tearController;
  late Animation<double> _flipAnimation;
  late Animation<double> _tearLineAnimation;
  late Animation<double> _scaleAnimation;
  bool _isAnimatingTear = false;

  @override
  void initState() {
    super.initState();
    _tearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _flipAnimation = Tween<double>(begin: 0.0, end: -math.pi * 0.48).animate(
      CurvedAnimation(
        parent: _tearController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _tearLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _tearController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.94), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.94, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 1.0), weight: 40),
    ]).animate(_tearController);
  }

  @override
  void dispose() {
    _tearController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isLocked || widget.isOpen || _isAnimatingTear) return;

    AppSoundService.instance.playPop();
    setState(() => _isAnimatingTear = true);

    _tearController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() => _isAnimatingTear = false);
        widget.onTap?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.isOpen
              ? AppColors.purple.withValues(alpha: 0.3)
              : widget.isLocked
                  ? Colors.grey.shade200
                  : AppColors.purple.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isOpen
                ? AppColors.purple.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 400),
          crossFadeState:
              (widget.isOpen && !_isAnimatingTear) ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: _buildSealedFlapView(),
          secondChild: _buildOpenContent(),
        ),
      ),
    );
  }

  Widget _buildSealedFlapView() {
    return GestureDetector(
      onTap: widget.isLocked ? null : _handleTap,
      child: AnimatedBuilder(
        animation: _tearController,
        builder: (context, child) {
          final scale = _scaleAnimation.value;
          final flipRad = _flipAnimation.value;
          final tearProgress = _tearLineAnimation.value;

          return Transform.scale(
            scale: scale,
            child: Stack(
              children: [
                // Sealed Flap Base Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: widget.isLocked
                        ? LinearGradient(
                            colors: [Colors.grey.shade100, Colors.grey.shade200],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Flap Badge Icon
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: widget.isLocked
                                  ? Colors.grey.shade200
                                  : AppColors.purple.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.isLocked
                                    ? Colors.grey.shade300
                                    : AppColors.purple.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                widget.isLocked
                                    ? '🔒'
                                    : (widget.index == 3 ? '🎁' : '📦'),
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: widget.isLocked
                                            ? Colors.grey.shade300
                                            : AppColors.purple
                                                .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'FLAP ${widget.index + 1}',
                                        style: GoogleFonts.nunito(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: widget.isLocked
                                              ? AppColors.textLight
                                              : AppColors.purple,
                                        ),
                                      ),
                                    ),
                                    if (!widget.isLocked) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '✂️ Tap to tear open',
                                        style: GoogleFonts.nunito(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.pink,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  widget.isLocked
                                      ? 'Open flaps 1–3 first!'
                                      : (widget.flap['title'] as String? ??
                                          _getFlapDefaultTitle(widget.index)),
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: widget.isLocked
                                        ? AppColors.textLight
                                        : AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            widget.isLocked
                                ? Icons.lock_outline
                                : Icons.touch_app_rounded,
                            color: widget.isLocked
                                ? AppColors.textLight
                                : AppColors.purple,
                            size: 22,
                          ),
                        ],
                      ),

                      // Perforated Zipper Tear Line across card
                      if (!widget.isLocked) ...[
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            return Stack(
                              children: [
                                // Dashed perforation guide line
                                Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: AppColors.purple.withValues(alpha: 0.15),
                                  ),
                                ),
                                // Animated Pink Tear Streak
                                Container(
                                  height: 2,
                                  width: width * tearProgress,
                                  decoration: BoxDecoration(
                                    color: AppColors.pink,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.pink.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                // 3D Perspective Flip Lid overlay during tear animation
                if (_isAnimatingTear)
                  Positioned.fill(
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002) // 3D Perspective depth
                        ..rotateX(flipRad),
                      alignment: Alignment.topCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE7F3).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: AppColors.pink.withValues(alpha: 0.6), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.pink.withValues(alpha: 0.2),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 6),
                              Text(
                                'UNSEALING...',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.pink,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('🎉', style: TextStyle(fontSize: 24)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getFlapDefaultTitle(int idx) {
    return switch (idx) {
      0 => 'Fact & Quick Question',
      1 => 'Mini Growth Challenge',
      2 => 'Skin & Growth Reflection',
      3 => 'Secret Sticker Reward',
      _ => 'Growth Flap',
    };
  }

  Widget _buildOpenContent() {
    final type = widget.flap['type'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'FLAP ${widget.index + 1} UNLOCKED',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          switch (type) {
            'fact_task' => _FactTaskContent(
                flap: widget.flap,
                selectedAnswer: widget.selectedAnswer,
                onAnswerSelected: widget.onAnswerSelected,
              ),
            'mini_task' => _MiniTaskContent(
                flap: widget.flap,
                selectedAnswer: widget.selectedAnswer,
                onAnswerSelected: widget.onAnswerSelected,
              ),
            'fact_reflection' => _ReflectionContent(
                flap: widget.flap,
                selectedAnswer: widget.selectedAnswer,
                onAnswerSelected: widget.onAnswerSelected,
              ),
            'sticker_reward' => _StickerContent(flap: widget.flap),
            _ => Text(widget.flap['message']?.toString() ?? '', style: GoogleFonts.nunito()),
          },
        ],
      ),
    );
  }
}

class _FactTaskContent extends StatelessWidget {
  final Map<String, dynamic> flap;
  final int? selectedAnswer;
  final void Function(int)? onAnswerSelected;
  const _FactTaskContent({required this.flap, this.selectedAnswer, this.onAnswerSelected});

  @override
  Widget build(BuildContext context) {
    final task = flap['task'] as Map<String, dynamic>?;
    final options = List<String>.from(task?['options'] as List? ?? []);
    final correctIdx = task?['correctIndex'] as int? ?? 0;
    final isAnswered = selectedAnswer != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fact Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  flap['factText'] as String? ?? '',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textDark,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Task Question
        if (task != null) ...[
          Text(
            task['question'] as String? ?? '',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),

          // Options
          ...options.asMap().entries.map((entry) {
            final idx = entry.key;
            final optionText = entry.value;
            final isSelected = selectedAnswer == idx;
            final isCorrect = idx == correctIdx;

            Color bgColor = Colors.white;
            Color borderColor = Colors.grey.shade200;
            Widget? icon;

            if (isAnswered) {
              if (isCorrect) {
                bgColor = const Color(0xFFECFDF5);
                borderColor = AppColors.success;
                icon = const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18);
              } else if (isSelected) {
                bgColor = const Color(0xFFFEF2F2);
                borderColor = AppColors.error;
                icon = const Icon(Icons.cancel_rounded, color: AppColors.error, size: 18);
              }
            }

            return GestureDetector(
              onTap: isAnswered ? null : () => onAnswerSelected?.call(idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: isSelected || (isAnswered && isCorrect) ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        optionText,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (icon != null) icon!,
                  ],
                ),
              ),
            );
          }),

          if (isAnswered && task['feedbackText'] != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFBBF24)),
              ),
              child: Row(
                children: [
                  const Text('🌸', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task['feedbackText'] as String,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF78350F),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          ],
        ],
      ],
    );
  }
}

class _MiniTaskContent extends StatefulWidget {
  final Map<String, dynamic> flap;
  final int? selectedAnswer;
  final void Function(int)? onAnswerSelected;
  const _MiniTaskContent({required this.flap, this.selectedAnswer, this.onAnswerSelected});

  @override
  State<_MiniTaskContent> createState() => _MiniTaskContentState();
}

class _MiniTaskContentState extends State<_MiniTaskContent> {
  final Set<int> _selectedIndices = {};
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final options = List<Map<String, dynamic>>.from(
      (widget.flap['options'] as List? ?? []).map((o) => Map<String, dynamic>.from(o as Map)),
    );
    final correctIndices = List<int>.from(widget.flap['correctIndices'] as List? ?? [0, 1, 2]);
    final targetCount = correctIndices.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.flap['prompt'] as String? ?? '',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _submitted
              ? '✨ Selection complete!'
              : 'Tap to select $targetCount items (${_selectedIndices.length}/$targetCount picked)',
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _submitted ? AppColors.success : AppColors.purple,
          ),
        ),
        const SizedBox(height: 12),
        ...options.asMap().entries.map((entry) {
          final idx = entry.key;
          final opt = entry.value;
          final isPicked = _selectedIndices.contains(idx);
          final isCorrect = correctIndices.contains(idx);

          Color bgColor = Colors.white;
          Color borderColor = Colors.grey.shade200;
          Widget icon = Icon(
            isPicked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            color: isPicked ? AppColors.purple : Colors.grey.shade400,
            size: 20,
          );

          if (_submitted) {
            if (isPicked && isCorrect) {
              bgColor = const Color(0xFFECFDF5);
              borderColor = AppColors.success;
              icon = const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20);
            } else if (isPicked && !isCorrect) {
              bgColor = const Color(0xFFFEF2F2);
              borderColor = AppColors.error;
              icon = const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20);
            } else if (!isPicked && isCorrect) {
              borderColor = AppColors.success.withValues(alpha: 0.5);
              icon = Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.success.withValues(alpha: 0.6), size: 20);
            }
          } else if (isPicked) {
            bgColor = const Color(0xFFF5F3FF);
            borderColor = AppColors.purple;
          }

          return GestureDetector(
            onTap: _submitted
                ? null
                : () {
                    AppSoundService.instance.playPop();
                    setState(() {
                      if (isPicked) {
                        _selectedIndices.remove(idx);
                      } else {
                        _selectedIndices.add(idx);
                      }
                      if (_selectedIndices.length == targetCount) {
                        _submitted = true;
                        AppSoundService.instance.playCorrect();
                        widget.onAnswerSelected?.call(1);
                      }
                    });
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: isPicked || (_submitted && isCorrect) ? 1.8 : 1,
                ),
                boxShadow: isPicked && !_submitted
                    ? [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Text(opt['emoji'] as String? ?? '✨', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      opt['label'] as String? ?? '',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  icon,
                ],
              ),
            ),
          );
        }),
        if (_submitted && widget.flap['feedbackText'] != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Text('🧬', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.flap['feedbackText'] as String,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
        ],
      ],
    );
  }
}

class _ReflectionContent extends StatelessWidget {
  final Map<String, dynamic> flap;
  final int? selectedAnswer;
  final void Function(int)? onAnswerSelected;
  const _ReflectionContent({required this.flap, this.selectedAnswer, this.onAnswerSelected});

  @override
  Widget build(BuildContext context) {
    final emojiOptions = List<String>.from(flap['emojiOptions'] as List? ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2F8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.pink.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔬', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  flap['factText'] as String? ?? '',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textDark,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          flap['reflectionPrompt'] as String? ?? '',
          style: GoogleFonts.nunito(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: emojiOptions.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final isPicked = selectedAnswer == idx;

            return Expanded(
              child: GestureDetector(
                onTap: () => onAnswerSelected?.call(idx),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isPicked ? const Color(0xFFFCE7F3) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPicked ? AppColors.pink : Colors.grey.shade200,
                      width: isPicked ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    opt,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isPicked ? AppColors.pink : AppColors.textDark,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (selectedAnswer != null && flap['feedbackText'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Text('💚', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    flap['feedbackText'] as String,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
        ],
      ],
    );
  }
}

class _StickerContent extends StatelessWidget {
  final Map<String, dynamic> flap;
  const _StickerContent({required this.flap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFBBF24)),
      ),
      child: Column(
        children: [
          Text(
            flap['stickerEmoji'] as String? ?? '🧬✨',
            style: const TextStyle(fontSize: 48),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 8),
          Text(
            flap['message'] as String? ?? 'You unlocked the secret sticker!',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF78350F),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
