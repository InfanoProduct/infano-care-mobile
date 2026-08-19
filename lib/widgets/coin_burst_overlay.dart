import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

/// Interactive gaming-style Flying Coin Burst Overlay.
/// Spawns a fountain of coins that erupt outwards and then fly into the top coin counter badge.
class CoinBurstOverlay {
  static void show(
    BuildContext context, {
    Offset? startOffset,
    Offset? targetOffset,
    int coinsEarned = 10,
    VoidCallback? onComplete,
  }) {
    final overlayState = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    // Default start position: bottom center or button location
    final start = startOffset ?? Offset(screenSize.width / 2, screenSize.height * 0.7);

    // Default target position: top right (where top App Bar CoinBadge is located)
    final target = targetOffset ?? Offset(screenSize.width - 65, mediaQuery.padding.top + 32);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _CoinBurstWidget(
        startOffset: start,
        targetOffset: target,
        coinsEarned: coinsEarned,
        onDismiss: () {
          entry.remove();
          onComplete?.call();
        },
      ),
    );

    overlayState.insert(entry);
    AppSoundService.instance.playBunchOfCoinsSound();
  }
}

class _CoinBurstWidget extends StatefulWidget {
  final Offset startOffset;
  final Offset targetOffset;
  final int coinsEarned;
  final VoidCallback onDismiss;

  const _CoinBurstWidget({
    required this.startOffset,
    required this.targetOffset,
    required this.coinsEarned,
    required this.onDismiss,
  });

  @override
  State<_CoinBurstWidget> createState() => _CoinBurstWidgetState();
}

class _CoinBurstWidgetState extends State<_CoinBurstWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_CoinParticle> _particles = [];
  final Random _random = Random();
  bool _showBanner = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Spawn 10 to 14 shiny coin particles
    const particleCount = 12;
    for (int i = 0; i < particleCount; i++) {
      final angle = (i * (2 * pi / particleCount)) + (_random.nextDouble() * 0.4 - 0.2);
      final radius = 50.0 + _random.nextDouble() * 60.0;
      final burstVector = Offset(cos(angle) * radius, sin(angle) * radius - 30);
      
      _particles.add(
        _CoinParticle(
          burstVector: burstVector,
          rotation: _random.nextDouble() * 2 * pi,
          size: 24.0 + _random.nextDouble() * 8.0,
          delayRatio: (i % 4) * 0.05,
          controlPoint: Offset(
            widget.startOffset.dx + (widget.targetOffset.dx - widget.startOffset.dx) * 0.3 + (_random.nextDouble() * 80 - 40),
            widget.startOffset.dy - 120 - (_random.nextDouble() * 60),
          ),
        ),
      );
    }

    _controller.forward().then((_) {
      widget.onDismiss();
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showBanner = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _calculateBezier(Offset p0, Offset p1, Offset p2, double t) {
    final double u = 1 - t;
    final double tt = t * t;
    final double uu = u * u;

    final double x = uu * p0.dx + 2 * u * t * p1.dx + tt * p2.dx;
    final double y = uu * p0.dy + 2 * u * t * p1.dy + tt * p2.dy;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;

        return Stack(
          children: [
            // Center Floating Toast Banner (+Coins Earned!)
            if (_showBanner)
              Positioned(
                top: widget.startOffset.dy - 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFFDBA74), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF97316).withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            '+${widget.coinsEarned} COINS!',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF9A3412),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Render Flying Coin Particles
            ..._particles.map((particle) {
              final adjustedProgress = ((progress - particle.delayRatio) / (1.0 - particle.delayRatio)).clamp(0.0, 1.0);
              if (adjustedProgress <= 0) return const SizedBox.shrink();

              late Offset currentPosition;
              double scale = 1.0;
              double opacity = 1.0;

              if (adjustedProgress < 0.25) {
                // Phase 1: Explosion Burst out from starting point
                final burstProgress = adjustedProgress / 0.25;
                final easeBurst = Curves.easeOutCubic.transform(burstProgress);
                currentPosition = widget.startOffset + particle.burstVector * easeBurst;
                scale = 0.5 + (0.7 * easeBurst);
              } else {
                // Phase 2: Curved trajectory fly to top coin target
                final flyProgress = (adjustedProgress - 0.25) / 0.75;
                final easeFly = Curves.easeInOutCubic.transform(flyProgress);

                final burstPeakPos = widget.startOffset + particle.burstVector;
                currentPosition = _calculateBezier(
                  burstPeakPos,
                  particle.controlPoint,
                  widget.targetOffset,
                  easeFly,
                );

                // Shrink and fade out right before hitting the target
                if (flyProgress > 0.85) {
                  final fadeProgress = (flyProgress - 0.85) / 0.15;
                  scale = 1.2 * (1.0 - fadeProgress);
                  opacity = 1.0 - fadeProgress;
                } else {
                  scale = 1.2;
                }
              }

              return Positioned(
                left: currentPosition.dx - (particle.size / 2),
                top: currentPosition.dy - (particle.size / 2),
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: particle.rotation * adjustedProgress,
                    child: Transform.scale(
                      scale: scale,
                      child: Text(
                        '🪙',
                        style: TextStyle(fontSize: particle.size),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _CoinParticle {
  final Offset burstVector;
  final double rotation;
  final double size;
  final double delayRatio;
  final Offset controlPoint;

  _CoinParticle({
    required this.burstVector,
    required this.rotation,
    required this.size,
    required this.delayRatio,
    required this.controlPoint,
  });
}
