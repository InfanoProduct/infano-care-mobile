import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class CyclePhaseData {
  final String name;
  final double startPercent; // 0.0 to 1.0
  final double endPercent;
  final List<Color> gradient;

  CyclePhaseData({
    required this.name,
    required this.startPercent,
    required this.endPercent,
    required this.gradient,
  });
}

class CycleRingPainter extends CustomPainter {
  final List<CyclePhaseData> phases;
  final double fertileStart;
  final double fertileEnd;
  final String confidenceLevel;
  final bool isIrregular;
  final double currentProgress;
  final double dotPulseScale;
  final String currentPhase;
  final int currentDay;

  CycleRingPainter({
    required this.phases,
    required this.currentProgress,
    required this.currentPhase,
    required this.currentDay,
    this.dotPulseScale = 1.0,
    this.fertileStart = 0.0,
    this.fertileEnd = 0.0,
    this.confidenceLevel = 'medium',
    this.isIrregular = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.22; 
    final ringRadius = radius - (strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt; // Butt for seamless segments

    // 1. Draw Background Ring (Very Dark)
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = const Color(0xFF1E1B4B).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // 2. Draw Phase Arcs
    for (var phase in phases) {
      final startAngle = -pi / 2 + (phase.startPercent * 2 * pi);
      final sweepAngle = (phase.endPercent - phase.startPercent) * 2 * pi;

      final rect = Rect.fromCircle(center: center, radius: ringRadius);
      
      paint.shader = SweepGradient(
        colors: [...phase.gradient, phase.gradient.first],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(startAngle),
      ).createShader(rect);

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }

    // 3. Draw Stars in Center
    _drawStars(canvas, center, radius * 0.4);

    // 4. Center Text
    _drawCenterText(canvas, center, radius);

    // 5. Draw Progress Indicator (White Glowy Dot)
    final dotAngle = -pi / 2 + (currentProgress * 2 * pi);
    final dotPosition = Offset(
      center.dx + ringRadius * cos(dotAngle),
      center.dy + ringRadius * sin(dotAngle),
    );

    // Outer Glow
    canvas.drawCircle(
      dotPosition,
      (strokeWidth * 0.75) * dotPulseScale,
      Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Core
    canvas.drawCircle(dotPosition, (strokeWidth * 0.4), Paint()..color = Colors.white);
    
    // Border
    canvas.drawCircle(
      dotPosition,
      (strokeWidth * 0.4),
      Paint()
        ..color = Colors.orange.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawStars(Canvas canvas, Offset center, double offsetY) {
    const starEmoji = '✨';
    final textPainter = TextPainter(
      text: TextSpan(
        text: starEmoji,
        style: TextStyle(fontSize: offsetY * 0.6),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, offsetY + 20));
  }

  void _drawCenterText(Canvas canvas, Offset center, double radius) {
    // Day Text
    final dayPainter = TextPainter(
      text: TextSpan(
        text: 'Day $currentDay',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    dayPainter.paint(canvas, center - Offset(dayPainter.width / 2, 10));

    // Phase Text
    final phasePainter = TextPainter(
      text: TextSpan(
        text: currentPhase.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFFBBF24), // Golden
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    phasePainter.paint(canvas, center - Offset(phasePainter.width / 2, -20));
  }

  @override
  bool shouldRepaint(covariant CycleRingPainter oldDelegate) {
    return true;
  }
}
