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
  final String confidenceLevel; // 'none', 'low', 'medium', 'high'
  final bool isIrregular;
  final double currentProgress;
  final double dotPulseScale;

  CycleRingPainter({
    required this.phases,
    required this.currentProgress,
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
    final strokeWidth = radius * 0.18; // Slightly thinner for more elegance
    final ringRadius = radius - (strokeWidth / 2) - 10;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 1. Draw Background Ring (Subtle Track)
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = AppColors.purple.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // 2. Draw Phase Arcs with Premium Gradients
    for (var phase in phases) {
      final startAngle = -pi / 2 + (phase.startPercent * 2 * pi);
      final sweepAngle = (phase.endPercent - phase.startPercent) * 2 * pi;

      final rect = Rect.fromCircle(center: center, radius: ringRadius);
      
      paint.shader = SweepGradient(
        colors: [...phase.gradient, phase.gradient.first],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(startAngle),
      ).createShader(rect);

      // Add a slight shadow under the phase arc for depth
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }

    // 3. Draw Fertile Window "Glow" (Outer Arc)
    if (fertileEnd > fertileStart) {
      // Map confidence to opacity
      final double configOpacity = switch (confidenceLevel.toLowerCase()) {
        'high' => 1.0,
        'medium' => 0.6,
        'low' => 0.3,
        _ => 0.0,
      };

      if (configOpacity > 0) {
        final fRadius = ringRadius + (strokeWidth * 0.7);
        
        // Irregular Mode: Wider, more blurred arc
        final fStrokeWidth = isIrregular ? strokeWidth * 0.6 : strokeWidth * 0.35;
        final fBlur = isIrregular ? strokeWidth * 0.6 : strokeWidth * 0.3;
        
        final startAngle = -pi / 2 + (fertileStart * 2 * pi);
        final sweepAngle = (fertileEnd - fertileStart) * 2 * pi;

        final fPaint = Paint()
          ..color = const Color(0xFFFBBF24).withOpacity(configOpacity * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = fStrokeWidth
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, fBlur);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: fRadius),
          startAngle,
          sweepAngle,
          false,
          fPaint,
        );

        // Core of the fertile window
        final fCorePaint = Paint()
          ..color = const Color(0xFFFBBF24).withOpacity(configOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isIrregular ? 1.5 : 2.5
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: fRadius),
          startAngle,
          sweepAngle,
          false,
          fCorePaint,
        );
      }
    }

    // 4. Draw Current Day Indicator (The Bubble)
    final dotAngle = -pi / 2 + (currentProgress * 2 * pi);
    final dotPosition = Offset(
      center.dx + ringRadius * cos(dotAngle),
      center.dy + ringRadius * sin(dotAngle),
    );

    // Outer Glow
    canvas.drawCircle(
      dotPosition,
      (strokeWidth * 0.7) * dotPulseScale,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // White Core
    canvas.drawCircle(
      dotPosition,
      (strokeWidth * 0.45),
      Paint()..color = Colors.white,
    );
    
    // Border for definition
    canvas.drawCircle(
      dotPosition,
      (strokeWidth * 0.45),
      Paint()
        ..color = AppColors.purple.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant CycleRingPainter oldDelegate) {
    return oldDelegate.currentProgress != currentProgress ||
        oldDelegate.dotPulseScale != dotPulseScale ||
        oldDelegate.phases != phases ||
        oldDelegate.fertileStart != fertileStart ||
        oldDelegate.fertileEnd != fertileEnd ||
        oldDelegate.confidenceLevel != confidenceLevel ||
        oldDelegate.isIrregular != isIrregular;
  }
}
