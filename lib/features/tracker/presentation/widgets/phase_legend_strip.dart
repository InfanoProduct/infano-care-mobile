import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Horizontal scrollable legend strip for calendar phase colors and indicators.
///
/// Features distinct shapes for standard phases (squares), predicted phases
/// (dashed squares), and the current day (pink circle).
class PhaseLegendStrip extends StatelessWidget {
  const PhaseLegendStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Phase color legend",
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          border: Border(
            bottom: BorderSide(color: Color(0xFFF3F4F6), width: 0.5),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _LegendItem(
                color: const Color(0xFFFFE4E6), // Soft Rose
                label: 'Period',
                description: 'Phase: renewal + shedding',
              ),
              const _Gap(),
              _LegendItem(
                color: const Color(0xFFF0FDFA), // Soft Mint
                label: 'Follicular',
                description: 'Phase: energy building',
              ),
              const _Gap(),
              _LegendItem(
                color: const Color(0xFFFEFCE8), // Soft Amber
                label: 'Fertile',
                description: 'Phase: high fertility',
              ),
              const _Gap(),
              _LegendItem(
                color: const Color(0xFFFFAE8A), // Specific Peach Orange
                label: 'Ovulation',
                description: 'Phase: peak energy',
              ),
              const _Gap(),
              _LegendItem(
                color: const Color(0xFFEFF6FF), // Soft Blue
                label: 'Luteal',
                description: 'Phase: introspective',
              ),
              const _Gap(),
              _LegendItem(
                color: const Color(0xFFE91E8C),
                label: 'Today',
                description: "Today's date",
                isToday: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String description;
  final bool isPredicted;
  final bool isToday;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.description,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          "${isToday ? 'pink circle' : 'color square'}: $label — $description",
      child: Tooltip(
        message: description,
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(seconds: 2),
        triggerMode: TooltipTriggerMode.tap,
        preferBelow: false,
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.nunito(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        child: InkWell(
          onTap: () {}, // Tooltip trigger
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _IndicatorShape(
                color: color,
                isPredicted: isPredicted,
                isToday: isToday,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: const Color(
                    0xFF374151,
                  ), // Darker gray for better contrast
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicatorShape extends StatelessWidget {
  final Color color;
  final bool isPredicted;
  final bool isToday;

  const _IndicatorShape({
    required this.color,
    required this.isPredicted,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    if (isToday) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: Color.lerp(color, Colors.black, 0.1)!, // Subtle darker border
          width: 1,
        ),
      ),
    );
  }
}

/// Custom painter for the 8x8 dashed square (Predicted phase indicator).
class _DashedSquarePainter extends CustomPainter {
  final Color color;
  const _DashedSquarePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(1)),
      fillPaint,
    );

    const dashWidth = 2.0;
    const dashSpace = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1)));

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedSquarePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _Gap extends StatelessWidget {
  const _Gap();
  @override
  Widget build(BuildContext context) => const SizedBox(width: 12);
}
