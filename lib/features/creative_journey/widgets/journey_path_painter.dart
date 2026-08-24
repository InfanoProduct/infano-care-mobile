import 'dart:ui';
import 'package:flutter/material.dart';

/// Road Path Painter that draws a paved road curve with asphalt borders, center dashes,
/// and glowing progress lines connecting the nodes.
class DottedCurvePainter extends CustomPainter {
  final bool startFromLeft; // true: top-left -> bottom-right; false: top-right -> bottom-left
  final Color lineColor;
  final bool isCompleted;
  final bool isUnlocked;

  DottedCurvePainter({
    required this.startFromLeft,
    required this.lineColor,
    this.isCompleted = false,
    this.isUnlocked = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double leftX = 56.0;
    final double rightX = size.width - 56.0;

    final double startX = startFromLeft ? leftX : rightX;
    final double endX = startFromLeft ? rightX : leftX;

    final path = Path();
    path.moveTo(startX, 0);
    path.cubicTo(
      startX, size.height * 0.55,
      endX, size.height * 0.45,
      endX, size.height,
    );

    // ── 1. Road Base/Curb Underlay ──────────────────────────────────────────
    final roadBasePaint = Paint()
      ..color = isCompleted
          ? const Color(0xFFEDE9FE).withValues(alpha: 0.85)
          : isUnlocked
              ? const Color(0xFFEDE9FE).withValues(alpha: 0.7)
              : const Color(0xFFE5E7EB).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, roadBasePaint);

    // ── 2. Road Border Edges ───────────────────────────────────────────────
    final edgePaint = Paint()
      ..color = isCompleted
          ? const Color(0xFFA78BFA).withValues(alpha: 0.5)
          : isUnlocked
              ? const Color(0xFFA78BFA).withValues(alpha: 0.4)
              : const Color(0xFFD1D5DB).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, edgePaint);

    // ── 3. Main Center Dashed Line / Glow Line ─────────────────────────────
    final mainPaint = Paint()
      ..color = isCompleted ? const Color(0xFF8B5CF6) : lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCompleted ? 5.0 : 3.5
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, path, mainPaint);

    // ── 4. Completed Glow Effect ────────────────────────────────────────────
    if (isCompleted) {
      final glowPaint = Paint()
        ..color = const Color(0xFFA78BFA).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawPath(path, glowPaint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const double dashWidth = 8.0;
    const double dashSpace = 6.0;

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        final Path extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedCurvePainter oldDelegate) {
    return oldDelegate.startFromLeft != startFromLeft ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.isUnlocked != isUnlocked;
  }
}

class NodeConnectorWidget extends StatelessWidget {
  final bool startFromLeft;
  final bool isCompleted;
  final bool isUnlocked;

  const NodeConnectorWidget({
    super.key,
    required this.startFromLeft,
    this.isCompleted = false,
    this.isUnlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isCompleted
        ? const Color(0xFFD97706) // Deep Gold
        : isUnlocked
            ? const Color(0xFF7C3AED) // Deep Purple
            : const Color(0xFF9CA3AF); // Soft grey

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: CustomPaint(
        painter: DottedCurvePainter(
          startFromLeft: startFromLeft,
          lineColor: color,
          isCompleted: isCompleted,
          isUnlocked: isUnlocked,
        ),
      ),
    );
  }
}
