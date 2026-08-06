import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class QuestCelebrationOverlay extends StatefulWidget {
  final String title;
  final int points;
  final bool isLevelUp;
  final VoidCallback onDismiss;

  const QuestCelebrationOverlay({
    super.key,
    required this.title,
    required this.points,
    this.isLevelUp = false,
    required this.onDismiss,
  });

  @override
  State<QuestCelebrationOverlay> createState() => _QuestCelebrationOverlayState();
}

class _QuestCelebrationOverlayState extends State<QuestCelebrationOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.7),
      body: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [AppColors.purple, AppColors.pink, AppColors.bloom, Colors.white],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.network(
                widget.isLevelUp 
                  ? 'https://assets5.lottiefiles.com/packages/lf20_tou969ly.json' // Trophy/Level up
                  : 'https://assets3.lottiefiles.com/packages/lf20_vu77bx9c.json', // Checkmark/Celebration
                height: 200,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Icon(
                    widget.isLevelUp ? Icons.military_tech_rounded : Icons.check_circle_outline_rounded,
                    color: AppColors.bloom,
                    size: 100,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isLevelUp ? 'BLOOM LEVEL UP!' : 'QUEST COMPLETE!',
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.bloom,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: AppColors.bloom, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      '+${widget.points} Points',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.48,
            child: Text(
              '+${widget.points}',
              style: GoogleFonts.nunito(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: AppColors.bloom,
                shadows: [
                  const Shadow(
                    blurRadius: 15.0,
                    color: Colors.black54,
                    offset: Offset(0.0, 5.0),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.8, end: -0.8, duration: 2000.ms, curve: Curves.easeOut)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2000.ms, curve: Curves.elasticOut)
            .fadeOut(delay: 1200.ms, duration: 800.ms),
          ),
        ],
      ),
    );
  }
}
