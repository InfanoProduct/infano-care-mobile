import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A rich animated background for journey/episode screens featuring:
/// - Living sky gradient with smooth animated drifting clouds
/// - Floating sparkles, stars, and drifting leaves
/// - Live animated mascot / scooter traveling along the backdrop
/// - Ambient glow and parallax atmospheric depth
class AnimatedWorldBackgroundWidget extends StatefulWidget {
  final Widget child;
  final bool showMascotVehicle;

  const AnimatedWorldBackgroundWidget({
    super.key,
    required this.child,
    this.showMascotVehicle = true,
  });

  @override
  State<AnimatedWorldBackgroundWidget> createState() =>
      _AnimatedWorldBackgroundWidgetState();
}

class _AnimatedWorldBackgroundWidgetState
    extends State<AnimatedWorldBackgroundWidget>
    with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late AnimationController _floatController;
  late AnimationController _vehicleController;

  @override
  void initState() {
    super.initState();

    // 1. Drifting clouds controller (horizontal loops over 25 seconds)
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    // 2. Gentle bobbing/floating controller (sine oscillation for sparkles/leaves)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // 3. Scooter / mascot vehicle motion controller (horizontal cruise)
    _vehicleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _floatController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── 1. Base Gradient Atmosphere ─────────────────────────────────────
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF3E8FF), // Pastel Soft Purple
                  Color(0xFFFCE7F3), // Soft Pink
                  Color(0xFFEFF6FF), // Soft Sky Blue
                  Color(0xFFF8F5FF), // Soft Cream
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // ── 2. Live Drifting Clouds Layer ─────────────────────────────────────
        AnimatedBuilder(
          animation: _cloudController,
          builder: (context, child) {
            final screenWidth = MediaQuery.of(context).size.width;
            final progress = _cloudController.value;

            return Stack(
              children: [
                // Top Cloud 1 (moving left to right)
                Positioned(
                  top: 40,
                  left: (progress * (screenWidth + 200)) - 150,
                  child: const _CloudWidget(width: 140, opacity: 0.55),
                ),
                // Top Cloud 2 (offset)
                Positioned(
                  top: 110,
                  left: (((progress + 0.5) % 1.0) * (screenWidth + 220)) - 160,
                  child: const _CloudWidget(width: 170, opacity: 0.45),
                ),
                // Mid Cloud 3 (moving slower near top-mid)
                Positioned(
                  top: 240,
                  left: (((progress + 0.25) % 1.0) * (screenWidth + 180)) - 140,
                  child: const _CloudWidget(width: 120, opacity: 0.35),
                ),
                // Lower Background Cloud
                Positioned(
                  top: 420,
                  left: (((progress + 0.75) % 1.0) * (screenWidth + 240)) - 180,
                  child: const _CloudWidget(width: 160, opacity: 0.30),
                ),
              ],
            );
          },
        ),

        // ── 3. Live Floating Sparkles & Ambient Particle Layer ────────────────
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final floatVal = math.sin(_floatController.value * math.pi);
            final offsetY = floatVal * 10;

            return Stack(
              children: [
                // Floating Sparkle Left
                Positioned(
                  top: 160 + offsetY,
                  left: 24,
                  child: const _SparkleWidget(emoji: '✨', size: 18, opacity: 0.7),
                ),
                // Floating Star Right
                Positioned(
                  top: 280 - offsetY,
                  right: 28,
                  child: const _SparkleWidget(emoji: '⭐', size: 16, opacity: 0.6),
                ),
                // Floating Leaf / Flower Mid
                Positioned(
                  top: 480 + offsetY * 0.8,
                  left: 36,
                  child: const _SparkleWidget(emoji: '🌸', size: 20, opacity: 0.65),
                ),
                // Floating Balloon / Heart
                Positioned(
                  top: 620 - offsetY * 0.7,
                  right: 32,
                  child: const _SparkleWidget(emoji: '🎈', size: 22, opacity: 0.75),
                ),
              ],
            );
          },
        ),

        // ── 4. Live Mascot / Vehicle Cruise Banner (at bottom ambient space) ──
        if (widget.showMascotVehicle)
          AnimatedBuilder(
            animation: _vehicleController,
            builder: (context, child) {
              final screenWidth = MediaQuery.of(context).size.width;
              final posX = (_vehicleController.value * (screenWidth + 160)) - 100;
              final bounce = math.sin(_vehicleController.value * math.pi * 12) * 3;

              return Positioned(
                bottom: 20 + bounce,
                left: posX,
                child: Opacity(
                  opacity: 0.85,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🛴', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 4),
                        Text('🐱', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 2),
                        Text('💨', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

        // ── 5. Main Screen Content (CustomScrollView with Nodes & Scenery) ──
        widget.child,
      ],
    );
  }
}

// ── Cloud Graphic Widget ───────────────────────────────────────────────────────

class _CloudWidget extends StatelessWidget {
  final double width;
  final double opacity;

  const _CloudWidget({
    required this.width,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final height = width * 0.45;

    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: 16,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: const Color(0xFFDDD6FE).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Cloud Puff 1
            Positioned(
              top: -height * 0.35,
              left: width * 0.2,
              child: Container(
                width: width * 0.45,
                height: width * 0.45,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Cloud Puff 2
            Positioned(
              top: -height * 0.2,
              left: width * 0.45,
              child: Container(
                width: width * 0.35,
                height: width * 0.35,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating Sparkle/Star Widget ──────────────────────────────────────────────

class _SparkleWidget extends StatelessWidget {
  final String emoji;
  final double size;
  final double opacity;

  const _SparkleWidget({
    required this.emoji,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Text(
        emoji,
        style: TextStyle(fontSize: size),
      ),
    );
  }
}

/// Animated Windmill Graphic Widget with spinning blades
class AnimatedWindmillWidget extends StatefulWidget {
  final double height;
  const AnimatedWindmillWidget({super.key, this.height = 70});

  @override
  State<AnimatedWindmillWidget> createState() => _AnimatedWindmillWidgetState();
}

class _AnimatedWindmillWidgetState extends State<AnimatedWindmillWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.height * 0.8,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Windmill Tower Base
          Container(
            width: widget.height * 0.24,
            height: widget.height * 0.65,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF3E8FF), Color(0xFFDDD6FE)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(color: const Color(0xFFA78BFA), width: 1.5),
            ),
          ),
          // Spinning Blades
          Positioned(
            top: 2,
            child: RotationTransition(
              turns: _spinController,
              child: SizedBox(
                width: widget.height * 0.6,
                height: widget.height * 0.6,
                child: CustomPaint(
                  painter: _WindmillBladesPainter(),
                ),
              ),
            ),
          ),
          // Center Knob
          Positioned(
            top: widget.height * 0.28,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WindmillBladesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bladePaint = Paint()
      ..color = const Color(0xFFC4B5FD)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const numBlades = 4;
    final bladeLength = size.width * 0.45;
    final bladeWidth = size.width * 0.12;

    for (int i = 0; i < numBlades; i++) {
      final angle = (i * math.pi / 2);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(-bladeWidth / 2, -bladeLength * 0.7)
        ..lineTo(0, -bladeLength)
        ..lineTo(bladeWidth / 2, -bladeLength * 0.7)
        ..close();

      canvas.drawPath(path, bladePaint);
      canvas.drawPath(path, borderPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pastel Building Scenery Card (House, School, Library, Cafe, Clock Tower)
class SceneryBuildingWidget extends StatelessWidget {
  final String title;
  final String emoji;
  final Color bgGradientStart;
  final Color bgGradientEnd;
  final Color borderColor;
  final String detailText;

  const SceneryBuildingWidget({
    super.key,
    required this.title,
    required this.emoji,
    required this.bgGradientStart,
    required this.bgGradientEnd,
    required this.borderColor,
    required this.detailText,
  });

  factory SceneryBuildingWidget.home() => const SceneryBuildingWidget(
        title: 'Starter Cottage',
        emoji: '🏡',
        bgGradientStart: Color(0xFFFEF3C7),
        bgGradientEnd: Color(0xFFFDE68A),
        borderColor: Color(0xFFFBBF24),
        detailText: 'Journey begins!',
      );

  factory SceneryBuildingWidget.library() => const SceneryBuildingWidget(
        title: 'Discovery Hub',
        emoji: '🏫',
        bgGradientStart: Color(0xFFEDE9FE),
        bgGradientEnd: Color(0xFFDDD6FE),
        borderColor: Color(0xFFA78BFA),
        detailText: 'Knowledge clues',
      );

  factory SceneryBuildingWidget.windmill() => const SceneryBuildingWidget(
        title: 'Breeze Mill',
        emoji: '🌾',
        bgGradientStart: Color(0xFFE0F2FE),
        bgGradientEnd: Color(0xFFBAE6FD),
        borderColor: Color(0xFF38BDF8),
        detailText: 'Fresh ideas',
      );

  factory SceneryBuildingWidget.park() => const SceneryBuildingWidget(
        title: 'Bloom Park',
        emoji: '🌳',
        bgGradientStart: Color(0xFFD1FAE5),
        bgGradientEnd: Color(0xFFA7F3D0),
        borderColor: Color(0xFF34D399),
        detailText: 'Grow & flourish',
      );

  factory SceneryBuildingWidget.fountain() => const SceneryBuildingWidget(
        title: 'Glow Fountain',
        emoji: '⛲',
        bgGradientStart: Color(0xFFE0F2FE),
        bgGradientEnd: Color(0xFF7DD3FC),
        borderColor: Color(0xFF0284C7),
        detailText: 'Pure inspiration',
      );

  factory SceneryBuildingWidget.observatory() => const SceneryBuildingWidget(
        title: 'Star Dome',
        emoji: '🔭',
        bgGradientStart: Color(0xFFE0E7FF),
        bgGradientEnd: Color(0xFFC7D2FE),
        borderColor: Color(0xFF6366F1),
        detailText: 'Explore facts',
      );

  factory SceneryBuildingWidget.greenhouse() => const SceneryBuildingWidget(
        title: 'Care Garden',
        emoji: '🪴',
        bgGradientStart: Color(0xFFDCFCE7),
        bgGradientEnd: Color(0xFF86EFAC),
        borderColor: Color(0xFF22C55E),
        detailText: 'Nourish self',
      );

  factory SceneryBuildingWidget.puzzleStudio() => const SceneryBuildingWidget(
        title: 'Puzzle Studio',
        emoji: '🧩',
        bgGradientStart: Color(0xFFFFEDD5),
        bgGradientEnd: Color(0xFFFED7AA),
        borderColor: Color(0xFFF97316),
        detailText: 'Connect clues',
      );

  factory SceneryBuildingWidget.harmonyPlaza() => const SceneryBuildingWidget(
        title: 'Harmony Plaza',
        emoji: '🎪',
        bgGradientStart: Color(0xFFFCE7F3),
        bgGradientEnd: Color(0xFFFBCFE8),
        borderColor: Color(0xFFEC4899),
        detailText: 'Celebrate wins',
      );

  factory SceneryBuildingWidget.tower() => const SceneryBuildingWidget(
        title: 'Crown Peak',
        emoji: '👑',
        bgGradientStart: Color(0xFFFEF3C7),
        bgGradientEnd: Color(0xFFF59E0B),
        borderColor: Color(0xFFD97706),
        detailText: 'Master badge',
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 115),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgGradientStart, bgGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1B4B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  detailText,
                  style: TextStyle(
                    fontSize: 8.0,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
