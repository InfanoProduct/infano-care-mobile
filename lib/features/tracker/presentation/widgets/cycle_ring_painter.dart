import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class CyclePhaseData {
  final String id; // menstrual, follicular, ovulation, luteal
  final String name;
  final double startPercent; // 0.0 to 1.0
  final double endPercent;
  final List<Color> gradient;

  CyclePhaseData({
    required this.id,
    required this.name,
    required this.startPercent,
    required this.endPercent,
    required this.gradient,
  });
}

class CycleRingPainter extends CustomPainter {
  final List<CyclePhaseData> phases;
  final String trackerMode; // active, watching_waiting, irregular_support
  final String confidenceLevel; // none, getting_started, building, confident, high, irregular
  final double currentProgress; // 0.0 to 1.0 (current day / avgCycleLength)
  final List<double>? historicalSegments; // Actual logged period days as percentages [start, end, start, end...]
  final bool showFertility;
  final int? currentDay;
  final String phaseEmoji;
  final String phaseName;
  final double coefficientOfVar;

  CycleRingPainter({
    required this.phases,
    required this.trackerMode,
    required this.confidenceLevel,
    required this.currentProgress,
    this.historicalSegments,
    this.showFertility = false,
    this.currentDay,
    required this.phaseEmoji,
    required this.phaseName,
    this.coefficientOfVar = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final Offset center = Offset(s / 2, s / 2);
    
    // Core dimensions from PRD
    final double ringOuterR = s * 0.46;
    final double ringInnerR = s * 0.36;
    final double ringThickness = ringOuterR - ringInnerR;
    final double ringCenterR = (ringOuterR + ringInnerR) / 2;
    
    final double tickR = s * 0.48;
    final double predOuterR = s * 0.49;

    // --- 1. Draw Background Ring ---
    canvas.drawCircle(
      center,
      ringCenterR,
      Paint()
        ..color = const Color(0xFFFAF5FF) // Light lavender background
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringThickness,
    );

    if (trackerMode == 'watching_waiting') {
      _drawWatchingWaitingRing(canvas, center, ringCenterR, ringThickness, s);
    } else {
      _drawActiveRing(canvas, center, ringCenterR, ringThickness, s);
      _drawPredictionArc(canvas, center, predOuterR, s);
      _drawHistoricalSegments(canvas, center, ringCenterR, ringThickness);
      _drawCurrentDayDot(canvas, center, ringCenterR, ringThickness);
    }

    // --- 2. Draw Ticks ---
    _drawTicks(canvas, center, tickR, s);

    // --- 3. Draw Center Disc ---
    _drawCenterDisc(canvas, center, ringInnerR);
  }

  void _drawActiveRing(Canvas canvas, Offset center, double radius, double thickness, double size) {
    for (var phase in phases) {
      final double startAngle = -pi / 2 + (phase.startPercent * 2 * pi);
      final double sweepAngle = (phase.endPercent - phase.startPercent) * 2 * pi;
      
      if (sweepAngle <= 0) continue;

      final rect = Rect.fromCircle(center: center, radius: radius);
      
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.butt
        ..shader = SweepGradient(
          colors: phase.gradient,
          stops: const [0.0, 1.0],
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          transform: GradientRotation(startAngle),
        ).createShader(rect);

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  void _drawWatchingWaitingRing(Canvas canvas, Offset center, double radius, double thickness, double size) {
    final paint = Paint()
      ..color = const Color(0xFF0D9488).withOpacity(0.3) // Teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Manual dashed circle
    const int dashCount = 60;
    const double dashAngle = (2 * pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
       if (i % 2 == 0) {
         canvas.drawArc(
           Rect.fromCircle(center: center, radius: radius), 
           i * dashAngle, 
           dashAngle, 
           false, 
           paint
         );
       }
    }
  }

  void _drawPredictionArc(Canvas canvas, Offset center, double radius, double size) {
    if (trackerMode == 'watching_waiting') return;

    double opacity = 0.25;
    bool isDashed = true;
    Color color = AppColors.pink;

    switch (confidenceLevel) {
      case 'none': opacity = 0; break;
      case 'getting_started': opacity = 0.25; isDashed = true; break;
      case 'building': opacity = 0.5; isDashed = true; break;
      case 'confident': opacity = 0.75; isDashed = false; break;
      case 'high': opacity = 0.95; isDashed = false; break;
      case 'irregular': 
        opacity = 0.4; 
        isDashed = false; 
        color = Colors.amber; // Amber for irregular
        break;
    }

    if (opacity == 0) return;

    final startAngle = -pi / 2 + (currentProgress * 2 * pi) + 0.1;
    final sweepAngle = 0.5;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackerMode == 'irregular_support' ? 8 : 4
      ..strokeCap = StrokeCap.round;

    if (isDashed) {
      // Simple dash effect for the small arc
      const int steps = 5;
      final stepAngle = sweepAngle / steps;
      for (int i = 0; i < steps; i++) {
        if (i % 2 == 0) {
          canvas.drawArc(rect, startAngle + (i * stepAngle), stepAngle, false, paint);
        }
      }
    } else {
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  void _drawHistoricalSegments(Canvas canvas, Offset center, double radius, double thickness) {
    if (historicalSegments == null || historicalSegments!.isEmpty) return;

    final paint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt;

    for (int i = 0; i < historicalSegments!.length; i += 2) {
      final start = historicalSegments![i];
      final end = historicalSegments![i+1];
      final startAngle = -pi / 2 + (start * 2 * pi);
      final sweepAngle = (end - start) * 2 * pi;
      
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
    }
  }

  void _drawCurrentDayDot(Canvas canvas, Offset center, double radius, double thickness) {
    final double angle = -pi / 2 + (currentProgress * 2 * pi);
    final outerOffset = Offset(center.dx + (radius + thickness/2) * cos(angle), center.dy + (radius + thickness/2) * sin(angle));

    canvas.drawCircle(outerOffset, 6, Paint()..color = Colors.white);
    canvas.drawCircle(
      outerOffset, 
      6, 
      Paint()
        ..color = AppColors.pink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
    );
  }

  void _drawTicks(Canvas canvas, Offset center, double radius, double size) {
    final paint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;

    for (int i = 0; i < 28; i++) {
      final angle = -pi / 2 + (i / 28 * 2 * pi);
      final inner = Offset(center.dx + (radius - 4) * cos(angle), center.dy + (radius - 4) * sin(angle));
      final outer = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      canvas.drawLine(inner, outer, paint);
    }
  }

  void _drawCenterDisc(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center, 
      radius, 
      Paint()
        ..color = Colors.black.withOpacity(0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
    );
    
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);

    final emojiPainter = TextPainter(
      text: TextSpan(text: phaseEmoji, style: const TextStyle(fontSize: 32)),
      textDirection: TextDirection.ltr,
    )..layout();
    emojiPainter.paint(canvas, center - Offset(emojiPainter.width / 2, 45));

    final phasePainter = TextPainter(
      text: TextSpan(
        text: phaseName,
        style: GoogleFonts.nunito(
          fontSize: 16, 
          fontWeight: FontWeight.w800, 
          color: AppColors.textDark,
          letterSpacing: 0.5
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    phasePainter.paint(canvas, center - Offset(phasePainter.width / 2, 0));

    final dayPainter = TextPainter(
      text: TextSpan(
        text: trackerMode == 'watching_waiting' ? 'Your cycle is preparing' : 'Day $currentDay of 28',
        style: GoogleFonts.nunito(
          fontSize: 12, 
          fontWeight: FontWeight.w600, 
          color: AppColors.textMedium
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    dayPainter.paint(canvas, center - Offset(dayPainter.width / 2, -22));
    
    if (trackerMode == 'irregular_support') {
      final cvPainter = TextPainter(
        text: TextSpan(
          text: 'Variability: ${coefficientOfVar.toStringAsFixed(1)}%',
          style: GoogleFonts.nunito(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      cvPainter.paint(canvas, center - Offset(cvPainter.width / 2, -40));
    }
  }

  @override
  bool shouldRepaint(covariant CycleRingPainter oldDelegate) => true;
}
