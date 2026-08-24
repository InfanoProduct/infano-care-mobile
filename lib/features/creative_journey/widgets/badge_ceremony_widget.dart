import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';
import '../application/episode_path_cubit.dart';
import '../models/creative_journey_models.dart';

// ── FULL EPISODE MASTER BADGE CEREMONY ────────────────────────────────────────

class BadgeCeremonyWidget extends StatefulWidget {
  final VoidCallback onDismiss;
  final String episodeTitle;
  final CreativeEpisode? nextEpisode;
  final ValueChanged<CreativeEpisode>? onExploreNextEpisode;

  const BadgeCeremonyWidget({
    super.key,
    required this.onDismiss,
    required this.episodeTitle,
    this.nextEpisode,
    this.onExploreNextEpisode,
  });

  @override
  State<BadgeCeremonyWidget> createState() => _BadgeCeremonyWidgetState();
}

class _BadgeCeremonyWidgetState extends State<BadgeCeremonyWidget> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      AppSoundService.instance.playFanfare();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanTitle = widget.episodeTitle.replaceAll(RegExp(r'^\d+\.\s*'), '');
    final nextEp = widget.nextEpisode;
    final nextTitle = nextEp != null
        ? nextEp.title.replaceAll(RegExp(r'^\d+\.\s*'), '')
        : 'Body Image Unlocked';
    final nextDesc = nextEp?.description ??
        'Loving your unique shape, building self-confidence, and busting social media comparison traps!';
    final nextIcon = nextEp?.episodeIcon ?? '🪞';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF5F3FF), // Soft Lavender
            Color(0xFFFDF2F8), // Soft Rose
            Color(0xFFF0FDFA), // Soft Mint
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          alignment: Alignment.center,
          children: [
            // Floating Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 40,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  Color(0xFFA78BFA),
                  Color(0xFFF472B6),
                  Color(0xFF10B981),
                  Color(0xFF34D399),
                  Color(0xFF60A5FA),
                ],
              ),
            ),

            // Master Ceremony Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: nextEp == null
                    ? _buildGrandGraduationCard()
                    : _buildStandardEpisodeCard(cleanTitle, nextEp, nextTitle, nextDesc, nextIcon),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎓 UNIFIED CRISP GRAND GRADUATION CARD (Final Journey Completion)
  Widget _buildGrandGraduationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFDF2F8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.12),
            blurRadius: 32,
            spreadRadius: 3,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🏆 Grand Trophy Badge Circle
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA78BFA).withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 44)),
            ),
          )
              .animate()
              .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 300.ms),

          const SizedBox(height: 14),

          // Journey Mastered Pill Tag (Fits comfortably without overflow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.purple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '🎓 JOURNEY MASTERED (6/6)',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 12),

          Text(
            'My Changing Body Complete! 💖',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 14),

          // Gigi's Compact Graduation Message Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🌸', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gigi\'s Graduation Message:',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'You unlocked every secret about your body — from growth spurts to body confidence. Love and celebrate yourself every day!',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.textDark,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 16),

          Text(
            'Completed Milestones:',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),

          // 2-Column Balanced Grid (Never Overflows!)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: const [
                    _MilestonePill(emoji: '📈', label: '1. Body Timeline'),
                    SizedBox(height: 6),
                    _MilestonePill(emoji: '🧴', label: '3. Skin Stories'),
                    SizedBox(height: 6),
                    _MilestonePill(emoji: '👚', label: '5. Bra Basics'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: const [
                    _MilestonePill(emoji: '🦵', label: '2. Growing Pains'),
                    SizedBox(height: 6),
                    _MilestonePill(emoji: '🩸', label: '4. Period Preview'),
                    SizedBox(height: 6),
                    _MilestonePill(emoji: '🪞', label: '6. Body Image'),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 20),

          // Crisp Graduation Action Button (No Text Cutoff!)
          GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC4B5FD), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA78BFA).withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎓', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Claim Master Certificate 🎉',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4C1D95),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 750.ms),
        ],
      ),
    );
  }

  /// 🔓 STANDARD EPISODE CEREMONY CARD (For Episodes 1 to 5)
  Widget _buildStandardEpisodeCard(
    String cleanTitle,
    CreativeEpisode? nextEp,
    String nextTitle,
    String nextDesc,
    String nextIcon,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.12),
            blurRadius: 36,
            spreadRadius: 4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA78BFA).withValues(alpha: 0.25),
                  blurRadius: 28,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 48)),
            ),
          )
              .animate()
              .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 300.ms),

          const SizedBox(height: 16),

          Text(
            'Master Badge Assembled! 🏆',
            style: GoogleFonts.nunito(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

          const SizedBox(height: 4),
          Text(
            '$cleanTitle Master Badge',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.purple,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),

          // Next Episode Poster
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFBCFE8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE7F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🔓 NEXT EPISODE UNLOCKED',
                    style: GoogleFonts.nunito(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFBE185D),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(nextIcon, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Explore Next Episode: $nextTitle',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '"$nextDesc"',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: AppColors.textMedium,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 18),

          GestureDetector(
            onTap: () {
              if (nextEp != null && widget.onExploreNextEpisode != null) {
                widget.onExploreNextEpisode!(nextEp);
              } else {
                widget.onDismiss();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
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
                  Text(
                    'Explore Next Episode',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 750.ms),
        ],
      ),
    );
  }
}

// ── DISCOVERY CHEST BADGE ASSET UNBOXING SCREEN ─────────────────────────────

class DiscoveryChestScreen extends StatefulWidget {
  final ChestReward reward;
  final VoidCallback onClose;

  const DiscoveryChestScreen({
    super.key,
    required this.reward,
    required this.onClose,
  });

  @override
  State<DiscoveryChestScreen> createState() => _DiscoveryChestScreenState();
}

class _DiscoveryChestScreenState extends State<DiscoveryChestScreen> {
  bool _opened = false;

  String _getPieceEmoji(int index, ChestReward reward) {
    const defaultEmojis = ['📜', '📐', '🧭', '⭐', '🏆', '🦴', '✨', '🎁', '💎', '🪞'];
    if (index == reward.currentPieceIndex - 1) {
      return reward.assetEmoji.isNotEmpty ? reward.assetEmoji : '🧩';
    }
    if (index < defaultEmojis.length) {
      return defaultEmojis[index];
    }
    return '🧩';
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    final maxScreenHeight = MediaQuery.of(context).size.height * 0.85;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.black.withValues(alpha: 0.78),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxScreenHeight),
              child: GestureDetector(
                onTap: _opened
                    ? widget.onClose
                    : () {
                        AppSoundService.instance.playFanfare();
                        setState(() => _opened = true);
                      },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.25),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Chest emoji / Unboxed Badge Asset Icon
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, animation) => ScaleTransition(
                            scale: CurvedAnimation(
                              parent: animation,
                              curve: Curves.elasticOut,
                            ),
                            child: child,
                          ),
                          child: Container(
                            key: ValueKey(_opened),
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _opened
                                    ? [const Color(0xFFEDE9FE), const Color(0xFFFCE7F3)]
                                    : [const Color(0xFFF5F3FF), const Color(0xFFFDF2F8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.purple.withValues(alpha: 0.35),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.purple.withValues(alpha: 0.2),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _opened ? reward.assetEmoji : '🎁',
                                style: const TextStyle(fontSize: 44, decoration: TextDecoration.none),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (!_opened) ...[
                          Text(
                            'Discovery Chest!',
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to unbox your Episode Badge Asset ✨',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.purple,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.purple.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'Open Chest 🎁',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            '🧩 Badge Asset Collected!',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.purple,
                              decoration: TextDecoration.none,
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

                          const SizedBox(height: 3),
                          Text(
                            reward.assetName,
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              decoration: TextDecoration.none,
                            ),
                          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                          const SizedBox(height: 4),

                          Text(
                            reward.assetDescription,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: AppColors.textMedium,
                              height: 1.35,
                              decoration: TextDecoration.none,
                            ),
                          ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                          const SizedBox(height: 12),

                          // ── BADGE ASSEMBLY PROGRESS GRID ────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F5FF),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        reward.badgeTitle,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.nunito(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textDark,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${reward.currentPieceIndex}/${reward.totalPieces} Pieces',
                                      style: GoogleFonts.nunito(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.purple,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Assembly Slots (Compact & Responsive Wrap)
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 5,
                                  runSpacing: 5,
                                  children: List.generate(reward.totalPieces, (i) {
                                    final isUnlocked = i < reward.currentPieceIndex;
                                    final isJustCollected = i == reward.currentPieceIndex - 1;
                                    final pieceEmoji = _getPieceEmoji(i, reward);

                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: isUnlocked ? const Color(0xFFF3E8FF) : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isUnlocked
                                              ? AppColors.purple
                                              : Colors.grey.shade300,
                                          width: isUnlocked ? 1.8 : 1,
                                        ),
                                        boxShadow: isJustCollected
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.purple.withValues(alpha: 0.4),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          isUnlocked ? pieceEmoji : '${i + 1}',
                                          style: GoogleFonts.nunito(
                                            fontSize: isUnlocked ? 13 : 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: isUnlocked ? null : AppColors.textLight,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

                          const SizedBox(height: 10),

                          // Saved to Quest Module Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🛡️', style: TextStyle(fontSize: 11, decoration: TextDecoration.none)),
                                const SizedBox(width: 5),
                                Text(
                                  'Saved to Quest Module -> Badges',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.purple,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                          const SizedBox(height: 14),

                          // Default Dark Purple Continue Button
                          GestureDetector(
                            onTap: () {
                              AppSoundService.instance.playBunchOfCoinsSound();
                              widget.onClose();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.purple,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.purple.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Continue →',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MilestonePill extends StatelessWidget {
  final String emoji;
  final String label;

  const _MilestonePill({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12, decoration: TextDecoration.none)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.nunito(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 12),
        ],
      ),
    );
  }
}
