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
  final double currentProgress; // 0.0 to 1.0 (current day in cycle)
  final double dotPulseScale; // 1.0 to 1.2
  final double predictionStart; // 0.0 to 1.0 (optional)
  final double predictionEnd; // 0.0 to 1.0 (optional)
  final double predictionOpacity; // 0.0 to 1.0

  CycleRingPainter({
    required this.phases,
    required this.currentProgress,
    this.dotPulseScale = 1.0,
    this.predictionStart = 0.0,
    this.predictionEnd = 0.0,
    this.predictionOpacity = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.2;
    final ringRadius = radius - (strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 1. Draw Background Ring (Very light gray or theme background)
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = AppColors.purple.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // 2. Draw Phase Arcs
    for (var phase in phases) {
      final startAngle = -pi / 2 + (phase.startPercent * 2 * pi);
      final sweepAngle = (phase.endPercent - phase.startPercent) * 2 * pi;

      final rect = Rect.fromCircle(center: center, radius: ringRadius);
      
      paint.shader = LinearGradient(
        colors: phase.gradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }

    // 3. Draw Prediction Arc (Outer)
    if (predictionOpacity > 0 && predictionEnd > predictionStart) {
      final pRadius = ringRadius + (strokeWidth * 0.6);
      final pStrokeWidth = strokeWidth * 0.4;
      final startAngle = -pi / 2 + (predictionStart * 2 * pi);
      final sweepAngle = (predictionEnd - predictionStart) * 2 * pi;

      final pPaint = Paint()
        ..color = AppColors.pink.withOpacity(predictionOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = pStrokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: pRadius),
        startAngle,
        sweepAngle,
        false,
        pPaint,
      );
    }

    // 4. Draw Current Day Dot
    final dotAngle = -pi / 2 + (currentProgress * 2 * pi);
    final dotPosition = Offset(
      center.dx + ringRadius * cos(dotAngle),
      center.dy + ringRadius * sin(dotAngle),
    );

    // Glow
    canvas.drawCircle(
      dotPosition,
      (strokeWidth * 0.6) * dotPulseScale,
      Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Core Dot
    canvas.drawCircle(
      dotPosition,
      (strokeWidth * 0.4),
      Paint()..color = Colors.white,
    );
    
    // Border for contrast
    canvas.drawCircle(
      dotPosition,
      (strokeWidth * 0.4),
      Paint()
        ..color = AppColors.purple.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CycleRingPainter oldDelegate) {
    return oldDelegate.currentProgress != currentProgress ||
        oldDelegate.dotPulseScale != dotPulseScale ||
        oldDelegate.phases != phases ||
        oldDelegate.predictionStart != predictionStart ||
        oldDelegate.predictionEnd != predictionEnd ||
        oldDelegate.predictionOpacity != predictionOpacity;
  }
}
