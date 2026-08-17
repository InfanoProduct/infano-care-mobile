import 'dart:ui';
import 'package:flutter/material.dart';

class DottedCurvePainter extends CustomPainter {
  final bool startFromLeft; // true: top-left -> bottom-right; false: top-right -> bottom-left
  final Color lineColor;
  final bool isCompleted;

  DottedCurvePainter({
    required this.startFromLeft,
    required this.lineColor,
    this.isCompleted = false,
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

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCompleted ? 4.0 : 3.0
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, path, paint);
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
        oldDelegate.isCompleted != isCompleted;
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
        ? const Color(0xFFF59E0B) // Gold
        : isUnlocked
            ? const Color(0xFF7C3AED) // Purple
            : const Color(0xFFD1D5DB); // Soft grey

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: CustomPaint(
        painter: DottedCurvePainter(
          startFromLeft: startFromLeft,
          lineColor: color,
          isCompleted: isCompleted,
        ),
      ),
    );
  }
}
