import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/utils/calendar_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class CalendarGrid extends StatefulWidget {
  final DateTime month;
  final List<CycleLogModel> logs;
  final CycleProfileModel profile;
  final PredictionResultModel? prediction;
  final Function(DateTime) onDayTap;
  final bool isEditMode;
  final DateTime? selectedStart;
  final DateTime? selectedEnd;

  const CalendarGrid({
    super.key,
    required this.month,
    required this.logs,
    required this.profile,
    this.prediction,
    required this.onDayTap,
    this.isEditMode = false,
    this.selectedStart,
    this.selectedEnd,
  });

  @override
  State<CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<CalendarGrid> with SingleTickerProviderStateMixin {
  late List<DateTime> _daysInMonth;
  late List<List<DateTime>> _streakRows;

  @override
  void initState() {
    super.initState();
    _calculateDays();
  }

  @override
  void didUpdateWidget(CalendarGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month || oldWidget.logs != widget.logs) {
      _calculateDays();
    }
  }

  void _calculateDays() {
    final firstDay = DateTime(widget.month.year, widget.month.month, 1);
    final lastDay = DateTime(widget.month.year, widget.month.month + 1, 0);
    
    // Adjust to start from the beginning of the week (assuming Sunday)
    final startDay = firstDay.subtract(Duration(days: firstDay.weekday % 7));
    final endDay = lastDay.add(Duration(days: 6 - (lastDay.weekday % 7)));

    _daysInMonth = [];
    for (var d = startDay; d.isBefore(endDay.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
      _daysInMonth.add(d);
    }

    _streakRows = CalendarUtils.getStreakRows(_daysInMonth, widget.logs);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWeekHeader(),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemCount: _daysInMonth.length,
          itemBuilder: (context, index) {
            final day = _daysInMonth[index];
            final isSameMonth = day.month == widget.month.month;
            final streakRow = _streakRows.firstWhereOrNull((row) => row.contains(day));
            final isStreak = streakRow != null;
            final streakIndex = isStreak ? streakRow.indexOf(day) : 0;

            return CalendarDayCell(
              day: day,
              isSameMonth: isSameMonth,
              phase: CalendarUtils.getPhaseForDate(day, widget.profile, widget.logs),
              isPredicted: CalendarUtils.isDateInPredictionWindow(day, widget.prediction),
              log: widget.logs.firstWhere(
                (l) => DateUtils.isSameDay(l.date, day),
                orElse: () => CycleLogModel(id: '', date: day),
              ),
              isStreak: isStreak,
              animationDelay: isStreak ? Duration(milliseconds: 100 + (streakIndex * 50)) : Duration.zero,
              isSelected: _isDateSelected(day),
              isSelectionEnd: _isSelectionEnd(day),
              onTap: () => widget.onDayTap(day),
            );
          },
        ),
      ],
    );
  }

  bool _isDateSelected(DateTime date) {
    if (widget.selectedStart == null) return false;
    if (widget.selectedEnd == null) {
      return DateUtils.isSameDay(date, widget.selectedStart!);
    }
    return (date.isAfter(widget.selectedStart!) || DateUtils.isSameDay(date, widget.selectedStart!)) &&
           (date.isBefore(widget.selectedEnd!) || DateUtils.isSameDay(date, widget.selectedEnd!));
  }

  bool _isSelectionEnd(DateTime date) {
     return DateUtils.isSameDay(date, widget.selectedStart) || 
            DateUtils.isSameDay(date, widget.selectedEnd);
  }

  Widget _buildWeekHeader() {
    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekdays.map((d) => Text(
          d,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: AppColors.textMedium,
          ),
        )).toList(),
      ),
    );
  }
}

class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final bool isSameMonth;
  final CyclePhase phase;
  final bool isPredicted;
  final CycleLogModel log;
  final bool isStreak;
  final Duration animationDelay;
  final bool isSelected;
  final bool isSelectionEnd;
  final VoidCallback onTap;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.isSameMonth,
    required this.phase,
    required this.isPredicted,
    required this.log,
    required this.isStreak,
    required this.animationDelay,
    required this.isSelected,
    required this.isSelectionEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(day, DateTime.now());
    final bgColor = CalendarUtils.getPhaseColor(phase);
    
    Widget content = Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSameMonth ? bgColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: _getBorder(isToday, bgColor),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isStreak)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
              ).animate().shimmer(duration: 1000.ms, color: Colors.white24).fadeIn(delay: animationDelay),
            ),
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(isSelectionEnd ? 0.8 : 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelectionEnd ? Border.all(color: Colors.white, width: 2) : null,
                ),
              ),
            ),
          if (isPredicted)
            CustomPaint(
              painter: DashedBorderPainter(color: const Color(0xFFE84393)),
              child: Container(),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: GoogleFonts.nunito(
                  fontWeight: (isToday || isSelectionEnd) ? FontWeight.w800 : FontWeight.w600,
                  color: isSelectionEnd ? Colors.white : (isSameMonth ? AppColors.textDark : AppColors.textMedium.withOpacity(0.3)),
                  fontSize: 15,
                ),
              ),
              // Milestone FIRE indicator for Sundays on streak weeks
              if (isStreak && day.weekday == DateTime.sunday)
                 const Padding(
                   padding: EdgeInsets.only(top: 1.0),
                   child: Text('🔥', style: TextStyle(fontSize: 10)),
                 ),
            ],
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      ),
    );
  }

  BoxBorder? _getBorder(bool isToday, Color phaseColor) {
    if (isToday) {
      return Border.all(color: phaseColor.withOpacity(0.8), width: 2);
    }
    return null;
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 2.0;
    double currentPos = 0;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ));

    for (final metric in path.computeMetrics()) {
      while (currentPos < metric.length) {
        canvas.drawPath(
          metric.extractPath(currentPos, currentPos + dashWidth),
          paint,
        );
        currentPos += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
