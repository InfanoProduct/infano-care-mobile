import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

/// A WhatsApp Meta AI-inspired thinking and transcribing status bubble for Gigi Chat.
class GigiThinkingBubble extends StatefulWidget {
  final bool isVoiceNote;

  const GigiThinkingBubble({
    super.key,
    this.isVoiceNote = false,
  });

  @override
  State<GigiThinkingBubble> createState() => _GigiThinkingBubbleState();
}

class _GigiThinkingBubbleState extends State<GigiThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleCtrl;
  late final Animation<double> _sparkleScale;

  @override
  void initState() {
    super.initState();
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _sparkleScale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _sparkleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sparkleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = widget.isVoiceNote
        ? 'Transcribing voice note & thinking'
        : 'Gigi is thinking';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Meta AI-style Sparkle Icon
            AnimatedBuilder(
              animation: _sparkleScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _sparkleScale.value,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.purple,
                          AppColors.purple.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            // Status Text
            Text(
              statusText,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.purple,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 4),
            // Pulsing Bouncing Dots
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ThinkingDot(delayMs: 0),
                SizedBox(width: 3),
                _ThinkingDot(delayMs: 200),
                SizedBox(width: 3),
                _ThinkingDot(delayMs: 400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingDot extends StatefulWidget {
  final int delayMs;
  const _ThinkingDot({required this.delayMs});

  @override
  State<_ThinkingDot> createState() => _ThinkingDotState();
}

class _ThinkingDotState extends State<_ThinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Transform.translate(
        offset: Offset(0, -3 * _anim.value),
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.35 + _anim.value * 0.65),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
