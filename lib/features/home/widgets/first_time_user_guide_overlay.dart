import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

class FirstTimeUserGuideOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final String userName;
  final GlobalKey? headerKey;
  final GlobalKey? trackerKey;
  final GlobalKey? journeyKey;
  final GlobalKey? bottomNavKey;

  const FirstTimeUserGuideOverlay({
    super.key,
    required this.onComplete,
    required this.userName,
    this.headerKey,
    this.trackerKey,
    this.journeyKey,
    this.bottomNavKey,
  });

  @override
  State<FirstTimeUserGuideOverlay> createState() =>
      _FirstTimeUserGuideOverlayState();
}

class _FirstTimeUserGuideOverlayState extends State<FirstTimeUserGuideOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late ConfettiController _confettiController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Rect? _getRectFromKey(GlobalKey? key) {
    if (key == null) return null;
    final context = key.currentContext;
    if (context == null) return null;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize && renderBox.attached) {
      final position = renderBox.localToGlobal(Offset.zero);
      return Rect.fromLTWH(
        position.dx,
        position.dy,
        renderBox.size.width,
        renderBox.size.height,
      );
    }
    return null;
  }

  List<Map<String, dynamic>> _getSteps(Size size) {
    final screenWidth = size.width;
    final screenHeight = size.height;
    final padding = screenWidth < 360 ? 14.0 : 18.0;

    // Measure live key rects if available
    final headerRect = _getRectFromKey(widget.headerKey);
    final trackerRect = _getRectFromKey(widget.trackerKey);
    final journeyRect = _getRectFromKey(widget.journeyKey);
    final bottomNavRect = _getRectFromKey(widget.bottomNavKey);

    return [
      // Step 1: Top Welcome Header
      {
        'emoji': '🌸',
        'title':
            'Welcome to Your Space, ${widget.userName.isNotEmpty ? widget.userName : 'Bestie'}!',
        'badge': 'DAILY DASHBOARD',
        'description':
            'This is your personal hub! Check in daily for positive encouragement, streak rewards, and main character energy.',
        'targetRect': headerRect ?? Rect.fromLTWH(0, 0, screenWidth, 260),
        'tooltipTop': (headerRect != null) ? headerRect.bottom + 10.0 : 270.0,
        'arrowAlignment': Alignment.topCenter,
      },
      // Step 2: Menstrual Tracker Snapshot Card
      {
        'emoji': '🩸',
        'title': 'Track Your Cycle & Body',
        'badge': 'CYCLE PREDICTIONS',
        'description':
            'Easily log your period dates, symptoms, and moods here to receive smart AI cycle predictions tailored for you.',
        'targetRect': trackerRect ??
            Rect.fromLTWH(
              padding,
              405,
              screenWidth - (padding * 2),
              175,
            ),
        'tooltipTop': (trackerRect != null)
            ? (trackerRect.top - 230).clamp(60.0, screenHeight - 340.0)
            : 105.0,
        'arrowAlignment': Alignment.bottomCenter,
      },
      // Step 3: Creative Learning Journey Map Card
      {
        'emoji': '📚',
        'title': 'Learn & Bloom with Gigi',
        'badge': 'CREATIVE JOURNEY',
        'description':
            'Embark on interactive body-education episodes! Test your knowledge, earn XP points, and level up with Gigi.',
        'targetRect': journeyRect ??
            Rect.fromLTWH(
              padding,
              600,
              screenWidth - (padding * 2),
              170,
            ),
        'tooltipTop': (journeyRect != null)
            ? (journeyRect.top - 230).clamp(100.0, screenHeight - 340.0)
            : 260.0,
        'arrowAlignment': Alignment.bottomCenter,
      },
      // Step 4: Bottom Navigation Bar
      {
        'emoji': '🌟',
        'title': 'Explore All Modules',
        'badge': 'NAVIGATION HUB',
        'description':
            'Switch seamlessly between Learn Hub, Cycle Tracker, Safe Community Circles, and Peer Support anytime from the bottom bar.',
        'targetRect': bottomNavRect ??
            Rect.fromLTWH(
              0,
              screenHeight - 88,
              screenWidth,
              88,
            ),
        'tooltipTop': (bottomNavRect != null)
            ? bottomNavRect.top - 235.0
            : screenHeight - 340.0,
        'arrowAlignment': Alignment.bottomCenter,
      },
    ];
  }

  void _nextStep(int stepCount) {
    if (_currentStep < stepCount - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _confettiController.play();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          widget.onComplete();
        }
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final steps = _getSteps(size);
    final stepData = steps[_currentStep];
    final targetRect = stepData['targetRect'] as Rect;
    final isLastStep = _currentStep == steps.length - 1;
    final tooltipTop = stepData['tooltipTop'] as double;
    final arrowAlignment = stepData['arrowAlignment'] as Alignment;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 1. Full Screen Spotlight Cutout Overlay with animated glowing ring
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: SpotlightCutoutPainter(
                    targetRect: targetRect,
                    pulseValue: _pulseController.value,
                    borderRadius:
                        _currentStep == 0 || _currentStep == 3 ? 0 : 22,
                  ),
                );
              },
            ),
          ),

          // 2. Confetti Explosion Widget
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF8B5CF6),
                Color(0xFFEC4899),
                Color(0xFFF43F5E),
                Color(0xFF10B981),
                Color(0xFFF59E0B),
                Colors.white,
              ],
              numberOfParticles: 45,
              gravity: 0.15,
            ),
          ),

          // 3. Target-Anchored Tooltip Speech Bubble
          Positioned(
            top: tooltipTop.clamp(20.0, size.height - 320.0),
            left: 20,
            right: 20,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0)
                        .animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_currentStep),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Arrow pointing UP at spotlight cutout
                    if (arrowAlignment == Alignment.topCenter)
                      CustomPaint(
                        size: const Size(20, 10),
                        painter: TriangleArrowPainter(
                          isPointingUp: true,
                          color: const Color(0xFF291544),
                          borderColor: const Color(0xFFA78BFA),
                        ),
                      ),

                    // Speech Bubble Card Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF291544),
                            Color(0xFF190B2E),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFA78BFA).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF7C3AED).withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge Header & Skip Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFA78BFA)
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  stepData['badge']!,
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFDDD6FE),
                                    letterSpacing: 0.8,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: widget.onComplete,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Skip Tour',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white70,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Gigi Mascot & Title
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFF6D28D9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    stepData['emoji']!,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  stepData['title']!,
                                  style: GoogleFonts.nunito(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.2,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Description
                          Text(
                            stepData['description']!,
                            style: GoogleFonts.nunito(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE9D5FF),
                              height: 1.4,
                              decoration: TextDecoration.none,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Step Dots & Action Buttons
                          Row(
                            children: [
                              // Progress Dots Indicator
                              Row(
                                children: List.generate(steps.length, (index) {
                                  final isActive = index == _currentStep;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.only(right: 6),
                                    width: isActive ? 18 : 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFFA78BFA)
                                          : Colors.white24,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                              ),

                              const Spacer(),

                              // Back Button
                              if (_currentStep > 0) ...[
                                IconButton(
                                  onPressed: _prevStep,
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],

                              // Next / Finish Button
                              GestureDetector(
                                onTap: () => _nextStep(steps.length),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF8B5CF6),
                                        Color(0xFF6D28D9),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6D28D9)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isLastStep ? 'Finish Tour 🎉' : 'Next',
                                        style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        isLastStep
                                            ? Icons.check_circle_rounded
                                            : Icons.arrow_forward_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Arrow pointing DOWN at spotlight cutout
                    if (arrowAlignment == Alignment.bottomCenter)
                      CustomPaint(
                        size: const Size(20, 10),
                        painter: TriangleArrowPainter(
                          isPointingUp: false,
                          color: const Color(0xFF190B2E),
                          borderColor: const Color(0xFFA78BFA),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter that darkens full screen and cuts out the active target rectangle with glowing ring
class SpotlightCutoutPainter extends CustomPainter {
  final Rect targetRect;
  final double pulseValue;
  final double borderRadius;

  SpotlightCutoutPainter({
    required this.targetRect,
    required this.pulseValue,
    this.borderRadius = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final layerRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Save layer for blend mode clearing
    canvas.saveLayer(layerRect, Paint());

    // 1. Dark semi-transparent background overlay
    final bgPaint = Paint()..color = const Color(0xDD0B061A);
    canvas.drawRect(layerRect, bgPaint);

    // 2. Cutout Target Hole (BlendMode.clear)
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    final RRect targetRRect = RRect.fromRectAndRadius(
      targetRect,
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(targetRRect, clearPaint);

    canvas.restore();

    // 3. Draw Glowing Neon Border Ring around target cutout
    final glowColor = Color.lerp(
      const Color(0xFFA78BFA),
      const Color(0xFFF472B6),
      pulseValue,
    )!;

    final strokePaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 + (pulseValue * 1.5);

    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.35 + (pulseValue * 0.25))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 + (pulseValue * 3.0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawRRect(targetRRect, glowPaint);
    canvas.drawRRect(targetRRect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant SpotlightCutoutPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// Triangle arrow pointer for speech bubble tooltips
class TriangleArrowPainter extends CustomPainter {
  final bool isPointingUp;
  final Color color;
  final Color borderColor;

  TriangleArrowPainter({
    required this.isPointingUp,
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (isPointingUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();

    final fillPaint = Paint()..color = color;
    final strokePaint = Paint()
      ..color = borderColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant TriangleArrowPainter oldDelegate) => false;
}
