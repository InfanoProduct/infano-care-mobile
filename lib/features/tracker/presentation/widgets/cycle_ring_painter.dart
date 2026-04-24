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
  final int totalCycleDays; // New field to replace hardcoded 28
  final String confidenceLevel; // none, getting_started, building, confident, high, irregular
  final double currentProgress; // 0.0 to 1.0 (current day / avgCycleLength)
  final List<double>? historicalSegments; // Actual logged period days as percentages [start, end, start, end...]
  final bool showFertility;
  final int? currentDay;
  final double? selectedDaySmooth; // Double for smooth movement
  final bool isDragging; // New field for active state
  final Color? innerColor; // New field for phase-based background
  final double waveValue; // New field for wave animation progress
  final String? formattedDate; // New field for date display
  final int? dayInPhase; // New field for phase-relative day
  final String phaseEmoji;
  final String phaseName;
  final String? nextPhaseName;
  final int? daysUntilNextPhase;
  final double coefficientOfVar;

  CycleRingPainter({
    required this.phases,
    required this.trackerMode,
    required this.totalCycleDays,
    required this.confidenceLevel,
    required this.currentProgress,
    this.historicalSegments,
    this.showFertility = false,
    this.currentDay,
    this.selectedDaySmooth,
    this.isDragging = false,
    this.innerColor,
    this.waveValue = 0.0,
    this.formattedDate,
    this.dayInPhase,
    required this.phaseEmoji,
    required this.phaseName,
    this.nextPhaseName,
    this.daysUntilNextPhase,
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
        ..color = const Color(0xFFF5F4F7) // New requested background color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringThickness,
    );

    if (trackerMode == 'watching_waiting') {
      _drawWatchingWaitingRing(canvas, center, ringCenterR, ringThickness, s);
    } else {
      _drawActiveRing(canvas, center, ringCenterR, ringThickness, s);
      _drawPredictionArc(canvas, center, predOuterR, s);
      _drawHistoricalSegments(canvas, center, ringCenterR, ringThickness);
      
      // Draw the "Current Day" marker (smaller, maybe just a tick or outline)
      if (currentDay != null) {
        _drawDayMarker(canvas, center, ringCenterR, ringThickness, currentDay!.toDouble(), isCurrent: true);
      }
      
      // Draw the "Selected Day" interactive indicator
      if (selectedDaySmooth != null) {
        _drawDayMarker(canvas, center, ringCenterR, ringThickness, selectedDaySmooth!, isCurrent: false, isActive: isDragging);
      }
    }

    // --- 2. Draw Ticks and Numbers ---
    _drawTicksAndNumbers(canvas, center, tickR, ringCenterR, s);

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

  void _drawDayMarker(Canvas canvas, Offset center, double radius, double thickness, double day, {required bool isCurrent, bool isActive = false}) {
    final double progress = (day - 1) / totalCycleDays.toDouble();
    final double angle = -pi / 2 + (progress * 2 * pi);
    final outerOffset = Offset(center.dx + (radius + thickness/2) * cos(angle), center.dy + (radius + thickness/2) * sin(angle));

    if (isCurrent) {
      // Draw a subtle "Today" ring
      canvas.drawCircle(
        outerOffset, 
        thickness / 2 + 4, 
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
      );
    } else {
      // Draw the main active indicator (the one that moves)
      final indicatorRadius = isActive ? 14.0 : 10.0;
      
      if (isActive) {
        // Draw a glow effect
        canvas.drawCircle(
          outerOffset, 
          indicatorRadius + 6, 
          Paint()
            ..color = AppColors.pink.withOpacity(0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        );
      }

      canvas.drawCircle(outerOffset, indicatorRadius, Paint()..color = Colors.white);
      canvas.drawCircle(
        outerOffset, 
        indicatorRadius, 
        Paint()
          ..color = AppColors.pink
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 4 : 3
      );
      
      // Add a little inner dot
      canvas.drawCircle(outerOffset, isActive ? 6 : 4, Paint()..color = AppColors.pink);
    }
  }

  void _drawTicksAndNumbers(Canvas canvas, Offset center, double radius, double ringCenterRadius, double size) {
    final tickPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;

    for (int i = 0; i < totalCycleDays; i++) {
      final angle = -pi / 2 + (i / totalCycleDays * 2 * pi);
      
      // Draw Ticks (Keep them subtle)
      final inner = Offset(center.dx + (radius - 4) * cos(angle), center.dy + (radius - 4) * sin(angle));
      final outer = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      canvas.drawLine(inner, outer, tickPaint);

      // Draw Numbers (Draw ALL days directly ON the ring segments)
      final textOffset = Offset(center.dx + ringCenterRadius * cos(angle), center.dy + ringCenterRadius * sin(angle));
      
      final isMajor = (i == 0 || (i + 1) % 5 == 0 || i == totalCycleDays - 1);
      
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: GoogleFonts.nunito(
            fontSize: isMajor ? 12 : 9,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      tp.paint(canvas, textOffset - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawCenterDisc(Canvas canvas, Offset center, double radius) {
    // Add a glowing shadow based on the current phase color
    if (innerColor != null) {
      canvas.drawCircle(
        center, 
        radius + 5, 
        Paint()
          ..color = innerColor!.withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
      );
    }
    
    // Draw the main background of the center disc
    // Use a very light version of the phase color or white
    canvas.drawCircle(
      center, 
      radius, 
      Paint()..color = innerColor?.withOpacity(0.05) ?? Colors.white
    );
    
    // Inner white disc for content
    canvas.drawCircle(center, radius * 0.95, Paint()..color = Colors.white);

    // --- Draw the Wave ---
    final displayDay = selectedDaySmooth?.round() ?? currentDay ?? 1;
    final fillLevel = (displayDay / totalCycleDays).clamp(0.0, 1.0);
    
    _drawWaves(canvas, center, radius * 0.95, fillLevel);

    _drawWaves(canvas, center, radius * 0.95, fillLevel);

    // --- 1. Draw Date (Top) ---
    if (formattedDate != null) {
      final dateParts = formattedDate!.split(' ');
      final dayStr = dateParts[0];
      final monthStr = dateParts.length > 1 ? dateParts[1].toLowerCase() : '';

      final dayPainter = TextPainter(
        text: TextSpan(
          text: dayStr,
          style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w300, color: AppColors.textDark),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      dayPainter.paint(canvas, center - Offset(dayPainter.width / 2, 75));

      final monthPainter = TextPainter(
        text: TextSpan(
          text: monthStr,
          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textMedium),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      monthPainter.paint(canvas, center - Offset(monthPainter.width / 2, 45));
    }

    // --- 2. Draw Phase Day (Middle) ---
    final displayPhaseName = phaseName == 'Menstrual' ? 'Period' : phaseName;
    final dayInPhasePainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$displayPhaseName day ',
            style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          TextSpan(
            text: '${dayInPhase ?? 1}',
            style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    dayInPhasePainter.paint(canvas, center - Offset(dayInPhasePainter.width / 2, 5));

    // --- 3. Draw pregnancy chance ---
    final chancePainter = TextPainter(
      text: TextSpan(
        text: 'Low chance of getting pregnant',
        style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMedium),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    chancePainter.paint(canvas, center - Offset(chancePainter.width / 2, -25));

    // --- 4. Draw next phase info (Bottom) ---
    if (nextPhaseName != null && daysUntilNextPhase != null) {
      final nextPhaseText = daysUntilNextPhase == 0 
          ? 'Phase change today!' 
          : '$daysUntilNextPhase ${daysUntilNextPhase == 1 ? 'day' : 'days'} until ${nextPhaseName![0].toUpperCase()}${nextPhaseName!.substring(1)}';
      
      final nextPhasePainter = TextPainter(
        text: TextSpan(
          text: nextPhaseText,
          style: GoogleFonts.nunito(
            fontSize: 10, 
            fontWeight: FontWeight.w700, 
            color: const Color(0xFFD946EF),
            letterSpacing: 0.2
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      nextPhasePainter.paint(canvas, center - Offset(nextPhasePainter.width / 2, -50));
    }
  }

  void _drawWaves(Canvas canvas, Offset center, double radius, double fillLevel) {
    if (innerColor == null) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));

    // Fill the bottom part with a solid color first
    final baseHeight = center.dy + radius - (2 * radius * fillLevel);
    
    // Draw two waves for a more dynamic look
    _drawSingleWave(canvas, center, radius, fillLevel, waveValue, innerColor!.withOpacity(0.3), 0);
    _drawSingleWave(canvas, center, radius, fillLevel, (waveValue + 0.5) % 1.0, innerColor!.withOpacity(0.5), 10);

    canvas.restore();
  }

  void _drawSingleWave(Canvas canvas, Offset center, double radius, double fillLevel, double animValue, Color color, double phaseShift) {
    final path = Path();
    final waveHeight = 8.0; // Amptitude of the wave
    final waveLength = radius * 2;
    
    final baseHeight = center.dy + radius - (2 * radius * fillLevel);
    
    path.moveTo(center.dx - radius, center.dy + radius); // Start at bottom left
    path.lineTo(center.dx - radius, baseHeight); // Up to the wave start

    for (double i = 0; i <= radius * 2; i++) {
      final dx = center.dx - radius + i;
      final dy = baseHeight + sin((i / waveLength * 2 * pi) + (animValue * 2 * pi) + phaseShift) * waveHeight;
      path.lineTo(dx, dy);
    }

    path.lineTo(center.dx + radius, center.dy + radius); // Down to bottom right
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CycleRingPainter oldDelegate) => true;
}
