import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/day_cell.dart';
import 'package:infano_care_mobile/features/tracker/utils/calendar_types.dart';
import 'package:infano_care_mobile/features/tracker/utils/calendar_utils.dart';
import 'package:infano_care_mobile/features/tracker/utils/prediction_windows_computer.dart';
import 'package:infano_care_mobile/features/tracker/utils/prediction_windows_provider.dart';
import 'package:provider/provider.dart';

// ── CalendarGrid ──────────────────────────────────────────────────────────────

class CalendarGrid extends StatefulWidget {
  final DateTime month;
  final List<CycleLogModel> logs;

  /// Pre-computed phase for every date in the 3-month window.
  final Map<String, CyclePhase> phaseMap;

  /// Dates inside the predicted period window (yyyy-MM-dd strings).
  final Set<String> predictionDates;

  /// Dates inside the fertility window (yyyy-MM-dd strings).
  final Set<String> fertilityDates;

  /// The 5 computed future cycle windows.
  final List<PredictedCycle> predictedCycles;

  /// Currently selected date string ('yyyy-MM-dd'), or null.
  final String? selectedDate;

  /// Edit mode props
  final bool isEditMode;
  final DateTime? editStartDate;
  final DateTime? editEndDate;

  final Function(DateTime) onDayTap;

  const CalendarGrid({
    super.key,
    required this.month,
    required this.logs,
    required this.phaseMap,
    required this.predictionDates,
    this.fertilityDates = const {},
    this.predictedCycles = const [],
    this.selectedDate,
    this.isEditMode = false,
    this.editStartDate,
    this.editEndDate,
    required this.onDayTap,
  });

  @override
  State<CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<CalendarGrid>
    with SingleTickerProviderStateMixin {
  late List<DateTime> _days;

  /// Map of weekIndex -> weekKey for rows that are full 7-day streaks.
  final Map<int, String> _streakWeeks = {};

  /// Currently animating week index, or null.
  int? _animatingWeekIndex;

  late AnimationController _streakController;
  final List<Animation<double>> _staggeredAnims = [];

  @override
  void initState() {
    super.initState();
    _streakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Prepare 7 staggered intervals
    for (int i = 0; i < 7; i++) {
      _staggeredAnims.add(
        CurvedAnimation(
          parent: _streakController,
          curve: Interval(
            (i * 50) / 700,
            (i * 50 + 300) / 700, // 300ms total for pop + color
            curve: Curves.easeInOut,
          ),
        ),
      );
    }

    _calculateDays();
    // Schedule animation check after first frame so context (storage) is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndTriggerStreak());
  }

  @override
  void dispose() {
    _streakController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CalendarGrid old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month || old.logs != widget.logs) {
      _calculateDays();
      _checkAndTriggerStreak();
    }
  }

  void _checkAndTriggerStreak() {
    if (!mounted) return;
    final storage = context.read<LocalStorageService>();
    final disableAnim = MediaQuery.of(context).disableAnimations;

    for (final entry in _streakWeeks.entries) {
      final weekIndex = entry.key;
      final weekKey = entry.value;

      if (!storage.isWeekStreakAnimated(weekKey)) {
        if (disableAnim) {
          // Skip animation, mark as done
          storage.setWeekStreakAnimated(weekKey);
          _showStreakSnackBar();
        } else if (_animatingWeekIndex == null) {
          // Trigger animation
          setState(() => _animatingWeekIndex = weekIndex);
          _streakController.forward().then((_) {
            storage.setWeekStreakAnimated(weekKey);
            setState(() => _animatingWeekIndex = null);
          });
          
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) _showStreakSnackBar();
          });
        }
      }
    }
  }

  void _showStreakSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🔥 7-day streak! Your predictions are getting sharper."),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _calculateDays() {
    final first = DateTime(widget.month.year, widget.month.month, 1);
    final last  = DateTime(widget.month.year, widget.month.month + 1, 0);

    // Grid starts on Sunday
    final start = first.subtract(Duration(days: first.weekday % 7));
    final end   = last.add(Duration(days: 6 - (last.weekday % 7)));

    _days = [];
    for (var d = start;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      _days.add(d);
    }

    // Identify streaks
    _streakWeeks.clear();
    for (int week = 0; week < _days.length / 7; week++) {
      bool allLogged = true;
      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final d = _days[week * 7 + dayIndex];
        final hasLog = widget.logs.any((l) => DateUtils.isSameDay(l.date, d));
        if (!hasLog) {
          allLogged = false;
          break;
        }
      }
      if (allLogged) {
        final weekStart = _days[week * 7];
        _streakWeeks[week] = "streak_${weekStart.year}_${weekStart.month}_${weekStart.day}";
      }
    }
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
          itemCount: _days.length,
          itemBuilder: _buildCell,
        ),
      ],
    );
  }

  Widget _buildCell(BuildContext context, int index) {
    final day       = _days[index];
    final dayKey    = PredictionWindowsComputer.toKey(day);
    final isOtherM  = day.month != widget.month.month;
    final isToday   = DateUtils.isSameDay(day, DateTime.now());
    final isSelected = dayKey == widget.selectedDate;
    final isPredicted = widget.predictionDates.contains(dayKey);

    // Phase → PhaseType bridge
    final cyclePhase = widget.phaseMap[dayKey] ?? CyclePhase.unknown;
    final phaseType  = _toPhaseType(cyclePhase);
    final dynamicOpacity = PredictionWindowsProvider.opacityForDate(day, widget.predictedCycles) ?? 1.0;

    final phaseInfo = phaseType != PhaseType.unknown || isPredicted
        ? PhaseInfo(
            phase: phaseType,
            isPredicted: isPredicted,
            opacity: isPredicted ? dynamicOpacity : 1.0,
          )
        : null;

    // Log for this day
    final log = widget.logs.firstWhereOrNull(
      (l) => DateUtils.isSameDay(l.date, day),
    );
    final flow       = flowLevelFromString(log?.flow);
    final hasLog     = log != null && log.id.isNotEmpty;

    // Is this the first day of a new phase compared to yesterday?
    final prevKey    = PredictionWindowsComputer.toKey(
      day.subtract(const Duration(days: 1)),
    );
    final prevPhase  = widget.phaseMap[prevKey];
    final isFirstDayOfPhase =
        !isOtherM && prevPhase != null && prevPhase != cyclePhase;

    final weekIndex = index ~/ 7;
    final dayInWeek = index % 7;
    final isStreakRow = _streakWeeks.containsKey(weekIndex);
    final isAnimating = _animatingWeekIndex == weekIndex;
    final isStaticStreak = isStreakRow && !isAnimating && 
        context.read<LocalStorageService>().isWeekStreakAnimated(_streakWeeks[weekIndex]!);

    return DayCell(
      key: ValueKey(dayKey),
      date: day,
      phaseInfo: isOtherM ? null : phaseInfo,
      flow: isOtherM ? null : flow,
      isToday: isToday,
      isSelected: isSelected,
      hasLog: hasLog,
      isOtherMonth: isOtherM,
      isFirstDayOfPhase: isFirstDayOfPhase,
      streakAnimation: isAnimating ? _staggeredAnims[dayInWeek] : null,
      isStreakStatic: isStaticStreak,
      isEditMode: widget.isEditMode,
      isInEditRange: _isInRange(day),
      onTap: () => widget.onDayTap(day),
    );
  }

  bool _isInRange(DateTime d) {
    if (widget.editStartDate == null || widget.editEndDate == null) return false;
    final start = DateUtils.dateOnly(widget.editStartDate!);
    final end   = DateUtils.dateOnly(widget.editEndDate!);
    final day   = DateUtils.dateOnly(d);
    return (day.isAtSameMomentAs(start) || day.isAfter(start)) &&
           (day.isAtSameMomentAs(end) || day.isBefore(end));
  }

  Widget _buildWeekHeader() {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekdays
            .map(
              (d) => Text(
                d,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMedium,
                  fontSize: 13,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── CyclePhase (old enum) ↔ PhaseType (new enum) bridge ────────────────────

  static PhaseType _toPhaseType(CyclePhase p) {
    switch (p) {
      case CyclePhase.menstrual:  return PhaseType.menstrual;
      case CyclePhase.follicular: return PhaseType.follicular;
      case CyclePhase.fertile:    return PhaseType.fertile;
      case CyclePhase.ovulation:  return PhaseType.ovulation;
      case CyclePhase.luteal:     return PhaseType.luteal;
      case CyclePhase.unknown:    return PhaseType.unknown;
    }
  }
}

// ── DashedBorderPainter (kept for backward compat with other callers) ─────────

class DashedBorderPainter extends CustomPainter {
  final Color color;
  const DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 2.0;
    double pos = 0;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(10),
      ));

    for (final metric in path.computeMetrics()) {
      while (pos < metric.length) {
        canvas.drawPath(
          metric.extractPath(pos, pos + dashWidth),
          paint,
        );
        pos += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter old) =>
      old.color != color;
}
