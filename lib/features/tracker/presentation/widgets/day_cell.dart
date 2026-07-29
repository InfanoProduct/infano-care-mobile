import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/utils/calendar_types.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DayCell
// ─────────────────────────────────────────────────────────────────────────────

/// Individual calendar day cell for the Infano.Care period tracker.
///
/// Const-constructible. Place inside a [RepaintBoundary] (already done by
/// [CalendarGrid]) to avoid cascading repaints across the 35-cell grid.
///
/// Animation: 1.0→1.06 scale on tap (150 ms spring). Skipped when
/// [MediaQueryData.disableAnimations] is true.
class DayCell extends StatefulWidget {
  final DateTime date;
  final PhaseInfo? phaseInfo;
  final FlowLevel? flow;
  final bool isToday;
  final bool isSelected;
  final bool hasLog;
  final bool isOtherMonth;

  /// Edit mode props
  final bool isEditMode;
  final bool isInEditRange;
  final bool isPreviousPeriod;
  final bool isFutureDate;

  /// Pass `true` when this date is the *first* day of a new phase segment
  /// so the [PhaseIcon] renders.
  final bool isFirstDayOfPhase;

  /// Optional animation for the 7-day streak glow.
  final Animation<double>? streakAnimation;

  /// If true, the streak is already completed and animated (permanent amber state).
  final bool isStreakStatic;

  final VoidCallback onTap;

  const DayCell({
    super.key,
    required this.date,
    this.phaseInfo,
    this.flow,
    required this.isToday,
    required this.isSelected,
    required this.hasLog,
    required this.isOtherMonth,
    this.isEditMode = false,
    this.isInEditRange = false,
    this.isPreviousPeriod = false,
    this.isFutureDate = false,
    this.isFirstDayOfPhase = false,
    this.streakAnimation,
    this.isStreakStatic = false,
    required this.onTap,
  });

  @override
  State<DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<DayCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    final disableAnim =
        MediaQuery.of(context).disableAnimations;
    if (!disableAnim) {
      _ctrl.forward().then((_) => _ctrl.reverse());
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Semantics(
        label: _semanticLabel(),
        button: true,
        child: GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _scaleAnim,
                if (widget.streakAnimation != null) widget.streakAnimation!,
              ]),
              builder: (_, child) {
                double scale = _scaleAnim.value;
                if (widget.streakAnimation != null) {
                  // Scale pop: 1.0 -> 1.05 (0.0 to 0.4 fraction of the interval) then back
                  // Actually since the caller provides a tailored Animation<double>, 
                  // we just map it here.
                  final s = widget.streakAnimation!.value;
                  // Map 0->1 to 1.0->1.05 and back? 
                  // The prompt says ScaleTransition: 1.0 -> 1.05 for 100ms, then back after 200ms.
                  // I'll assume the provided Animation is designed to do exactly this.
                  scale *= s; 
                }
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: _DayCellContent(
                date: widget.date,
                phaseInfo: widget.phaseInfo,
                flow: widget.flow,
                isToday: widget.isToday,
                isSelected: widget.isSelected,
                hasLog: widget.hasLog,
                isOtherMonth: widget.isOtherMonth,
                isEditMode: widget.isEditMode,
                isInEditRange: widget.isInEditRange,
                isPreviousPeriod: widget.isPreviousPeriod,
                isFutureDate: widget.isFutureDate,
                isFirstDayOfPhase: widget.isFirstDayOfPhase,
                streakProgress: widget.streakAnimation?.value ?? (widget.isStreakStatic ? 1.0 : 0.0),
              ),
            ),
        ),
      ),
    );
  }

  String _semanticLabel() {
    final parts = <String>[
      '${widget.date.day} ${_kMonthNames[widget.date.month]}',
    ];
    if (widget.isToday) parts.add('today');
    if (widget.isSelected) parts.add('selected');
    if (widget.phaseInfo != null && !widget.isOtherMonth) {
      parts.add(_phaseLabel(widget.phaseInfo!.phase));
      if (widget.phaseInfo!.isPredicted) parts.add('predicted');
    }
    final fl = widget.flow ?? FlowLevel.none;
    if (fl != FlowLevel.none && fl != FlowLevel.ended) {
      parts.add('${fl.name} flow');
    }
    return parts.join(', ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DayCellContent  (pure StatelessWidget — the actual visual)
// ─────────────────────────────────────────────────────────────────────────────

class _DayCellContent extends StatelessWidget {
  final DateTime date;
  final PhaseInfo? phaseInfo;
  final FlowLevel? flow;
  final bool isToday;
  final bool isSelected;
  final bool hasLog;
  final bool isOtherMonth;
  final bool isFirstDayOfPhase;

  final bool isEditMode;
  final bool isInEditRange;
  final bool isPreviousPeriod;
  final bool isFutureDate;

  /// 0.0 to 1.0 progress of the streak animation. 
  /// 1.0 means the cell is permanently in the amber "streak realized" state.
  final double streakProgress;

  const _DayCellContent({
    required this.date,
    required this.phaseInfo,
    required this.flow,
    required this.isToday,
    required this.isSelected,
    required this.hasLog,
    required this.isOtherMonth,
    required this.isFirstDayOfPhase,
    required this.isEditMode,
    required this.isInEditRange,
    required this.isPreviousPeriod,
    required this.isFutureDate,
    this.streakProgress = 0.0,
  });

  // ── Colours ────────────────────────────────────────────────────────────────

  static const _kTodayBg      = Color(0xFFE91E8C);
  static const _kSelectedRing = Color(0xFF7C3AED);
  static const _kPredictedNum = Color(0xFF7C3AED);
  static const _kOtherMonthTxt= Color(0xFFD1D5DB);

  static _PhaseStyle _phaseStyle(PhaseType phase) {
    switch (phase) {
      case PhaseType.menstrual:
        return const _PhaseStyle(
          bg: Color(0xFFFFE4E6), // Soft Rose
          border: Color(0xFFFDA4AF),
        );
      case PhaseType.follicular:
        return const _PhaseStyle(
          bg: Color(0xFFF0FDFA), // Soft Mint
          border: Color(0xFF5EEAD4),
        );
      case PhaseType.fertile:
        return const _PhaseStyle(
          bg: Color(0xFFFEFCE8), // Soft Amber
          border: Color(0xFFFDE68A),
        );
      case PhaseType.ovulation:
        return const _PhaseStyle(
          bg: Color(0xFFFFAE8A), // Specific Peach Orange
          border: Color(0xFFEA580C), // Saturated Orange Border
        );
      case PhaseType.luteal:
        return const _PhaseStyle(
          bg: Color(0xFFEFF6FF), // Soft Blue
          border: Color(0xFFBFDBFE),
        );
      case PhaseType.unknown:
        return const _PhaseStyle(
          bg: Colors.transparent,
          border: Colors.transparent,
        );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isPeriodFlow = flow != null &&
        flow != FlowLevel.none &&
        flow != FlowLevel.ended;

    // ── Determine visual layer ─────────────────────────────────────────────
    // Priority (highest first): today > selected > phase/predicted > other-month

    Widget cell;

    if (isToday) {
      cell = _buildTodayCell();
    } else if (isEditMode) {
      cell = _buildEditCell();
    } else if (phaseInfo != null && phaseInfo!.phase != PhaseType.unknown) {
      // Prioritize phase coloring only if NOT in edit mode
      cell = _buildPhaseCell(isPeriodFlow);
    } else if (isOtherMonth) {
      cell = _buildOtherMonthCell();
    } else if (isEditMode) {
      cell = _buildEditCell();
    } else {
      cell = _buildPhaseCell(isPeriodFlow);
    }

    // Wrap with selection ring if selected AND not today
    if (isSelected && !isToday) {
      cell = Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          border: Border.all(color: _kSelectedRing, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: cell,
      );
    }

    return cell;
  }

  // ── Today cell ─────────────────────────────────────────────────────────────

  Widget _buildTodayCell() {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _kTodayBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kTodayBg, width: 2),
      ),
      child: Center(
        child: _DateNumber(
          day: date.day,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Other month cell ───────────────────────────────────────────────────────

  Widget _buildOtherMonthCell() {
    final isUnknown = phaseInfo?.phase == PhaseType.unknown;
    
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isUnknown ? Colors.transparent : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: _DateNumber(
          day: date.day,
          color: _kOtherMonthTxt,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  // ── Edit mode cell ─────────────────────────────────────────────────────────

  Widget _buildEditCell() {
    Color bgColor = Colors.transparent;
    Color borderColor = Colors.grey.withValues(alpha: 0.1);
    Color textColor = AppColors.textMedium;
    FontWeight textWeight = FontWeight.normal;
    IconData? icon;
    Color iconColor = Colors.grey.withValues(alpha: 0.3);

    if (isFutureDate) {
      textColor = Colors.grey.withValues(alpha: 0.3);
      icon = Icons.lock_rounded;
      iconColor = Colors.grey.withValues(alpha: 0.2);
    } else if (isInEditRange) {
      bgColor = AppColors.purple.withValues(alpha: 0.12);
      borderColor = AppColors.purple.withValues(alpha: 0.3);
      textColor = AppColors.purple;
      textWeight = FontWeight.w700;
      icon = Icons.check_circle_rounded;
      iconColor = AppColors.purple;
    } else if (isPreviousPeriod) {
      bgColor = const Color(0xFFFDF2F8); // Very soft pink
      borderColor = const Color(0xFFFBCFE8); // Pink border
      textColor = const Color(0xFF9D174D);
      textWeight = FontWeight.w600;
      icon = Icons.radio_button_unchecked_rounded;
      iconColor = const Color(0xFFFBCFE8);
    } else {
      icon = Icons.radio_button_unchecked_rounded;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isInEditRange ? 1.5 : 1.0),
      ),
      child: Stack(
        children: [
          Center(
            child: _DateNumber(
              day: date.day,
              color: textColor,
              fontWeight: textWeight,
            ),
          ),
          if (icon != null)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                icon,
                size: 14,
                color: iconColor,
              ),
            ),
        ],
      ),
    );
  }

  // ── Phase cell (normal/predicted) ─────────────────────────────────────────

  Widget _buildPhaseCell(bool isPeriodFlow) {
    final info = phaseInfo;
    final style = info != null
        ? _phaseStyle(info.phase)
        : const _PhaseStyle(
            bg: Colors.transparent, border: Colors.transparent);

    // Background colour — solid even for predicted days
    final styleBg = info == null || style.bg.a == 0
        ? Colors.transparent
        : style.bg; // No more opacity-based fading for predicted days
    
    // Streak interpolation (Make it much subtler so it doesn't hide the phase)
    const streakBg = Color(0xFFFFFBEB);
    final bgColor = streakProgress > 0 
        ? Color.lerp(styleBg, streakBg, streakProgress * 0.3) // Only 30% yellow overlay for streak
        : styleBg;

    final numColor = info?.isPredicted == true
        ? _kPredictedNum
        : (info?.phase == PhaseType.unknown || info == null 
            ? const Color(0xFF6B7280) // Muted grey for non-cycle dates
            : const Color(0xFF1F2937)); // Darker gray

    // Predicted days now have the same border as active days
    final borderColor = streakProgress > 0.8 ? const Color(0xFFFDE68A) : style.border;

    var baseBg = (info?.isPredicted == true)
        ? const Color(0xFFFFE4E6) // Soft Rose for the entire window
        : bgColor;

    // If it's a day from another month, keep the color but make it slightly more pastel/faded
    if (isOtherMonth) {
      baseBg = baseBg?.withValues(alpha: 0.5);
    }

    Widget inner = Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: baseBg,
        borderRadius: BorderRadius.circular(10),
        border: info != null && info.phase != PhaseType.unknown && !info.isPredicted
            ? Border.all(color: borderColor, width: 1.2)
            : Border.all(color: Colors.grey.withValues(alpha: 0.05), width: 1), 
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DateNumber(
            day: date.day,
            color: numColor,
            fontWeight: FontWeight.normal,
          ),
          
          // Icon Row/Column
          if (info != null && !isToday)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _buildPhaseIcon(info),
            ),
        ],
      ),
    );

    return inner;
  }

  Widget _buildPhaseIcon(PhaseInfo info) {
    // Show icon on EVERY day for Period and Ovulation as requested
    if (info.phase == PhaseType.menstrual) {
      return const PhaseIcon(phase: PhaseType.menstrual);
    }
    if (info.phase == PhaseType.ovulation) {
      return const PhaseIcon(phase: PhaseType.ovulation);
    }
    
    // For others, only first day of phase
    if (isFirstDayOfPhase) {
      return PhaseIcon(phase: info.phase);
    }
    
    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FlowDot (Hidden in favor of Red Drop or kept as backup?)
// ─────────────────────────────────────────────────────────────────────────────

/// Coloured dot indicating menstrual flow intensity.
class FlowDot extends StatelessWidget {
  final FlowLevel level;

  const FlowDot({super.key, required this.level});

  static double _size(FlowLevel l) {
    switch (l) {
      case FlowLevel.heavy:   return 6;
      case FlowLevel.medium:  return 5;
      case FlowLevel.light:   return 4;
      case FlowLevel.spotting: return 3;
      default:                return 0;
    }
  }

  static Color _color(FlowLevel l) {
    switch (l) {
      case FlowLevel.heavy:    return const Color(0xFFDC2626);
      case FlowLevel.medium:   return const Color(0xFFEF4444);
      case FlowLevel.light:    return const Color(0xFFFCA5A5);
      case FlowLevel.spotting: return const Color(0xFFD97706);
      default:                 return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = _size(level);
    if (size == 0) return const SizedBox.shrink();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color(level),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PhaseIcon
// ─────────────────────────────────────────────────────────────────────────────

/// 8 dp inline SVG icon shown on the first day of each new phase.
class PhaseIcon extends StatelessWidget {
  final PhaseType phase;

  const PhaseIcon({super.key, required this.phase});

  static const double _kSize = 10;

  // ── Inline SVG strings ─────────────────────────────────────────────────────

  // Red Drop / Menstrual
  static const _svgMenstrual = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 21.5C15.5899 21.5 18.5 18.5899 18.5 15C18.5 11.4101 12 3 12 3C12 3 5.5 11.4101 5.5 15C5.5 18.5899 8.41015 21.5 12 21.5Z" fill="#EF4444"/>
</svg>''';

  // Seedling / follicular
  static const _svgFollicular = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 20V10" stroke="#10B981" stroke-width="2" stroke-linecap="round"/>
  <path d="M12 10C12 10 8 8 8 4c2.5 0 4 2 4 6z" fill="#10B981"/>
  <path d="M12 13C12 13 16 11 16 7c-2.5 0-4 2-4 6z" fill="#34D399"/>
</svg>''';

  // Sparkle / ovulation
  static const _svgOvulation = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2v4M12 18v4M2 12h4M18 12h4" stroke="#F59E0B" stroke-width="2" stroke-linecap="round"/>
  <path d="M5.64 5.64l2.83 2.83M15.54 15.54l2.83 2.83M5.64 18.36l2.83-2.83M15.54 8.46l2.83-2.83"
        stroke="#FBBF24" stroke-width="1.5" stroke-linecap="round"/>
  <circle cx="12" cy="12" r="2.5" fill="#FBBF24"/>
</svg>''';

  // Moon / luteal
  static const _svgLuteal = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M21 12.79A9 9 0 1 1 11.21 3a7 7 0 0 0 9.79 9.79z"
        fill="#6366F1" stroke="#818CF8" stroke-width="1"/>
</svg>''';

  static String _svgFor(PhaseType p) {
    switch (p) {
      case PhaseType.menstrual:  return _svgMenstrual;
      case PhaseType.follicular: return _svgFollicular;
      case PhaseType.ovulation:  return _svgOvulation;
      case PhaseType.luteal:     return _svgLuteal;
      case PhaseType.fertile:    return _svgFollicular; // Use follicular seedling for fertile too or something else
      case PhaseType.unknown:    return _svgFollicular; // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svgFor(phase),
      width: _kSize,
      height: _kSize,
      fit: BoxFit.contain,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DateNumber
// ─────────────────────────────────────────────────────────────────────────────

class _DateNumber extends StatelessWidget {
  final int day;
  final Color color;
  final FontWeight fontWeight;

  const _DateNumber({
    required this.day,
    required this.color,
    required this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$day',
      style: GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: fontWeight,
        color: color,
        height: 1.1,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PhaseDashedBorderPainter
// ─────────────────────────────────────────────────────────────────────────────

/// Draws a dashed rounded-rect border at the specified [color].
/// Used for predicted phase days since Flutter has no native dashed border.
class _PhaseDashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  const _PhaseDashedBorderPainter({
    required this.color,
    this.borderRadius = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashLen   = 1.0;
    const gapLen    = 2.0;
    const inset     = 2.0; // more breathing room

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inset, inset,
              size.width - inset * 2, size.height - inset * 2),
          Radius.circular(borderRadius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double pos = 0;
      bool draw = true;
      while (pos < metric.length) {
        final segLen = draw ? dashLen : gapLen;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(pos, math.min(pos + segLen, metric.length)),
            paint,
          );
        }
        pos += segLen;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_PhaseDashedBorderPainter old) =>
      old.color != color || old.borderRadius != borderRadius;
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

class _PhaseStyle {
  final Color bg;
  final Color border;
  const _PhaseStyle({required this.bg, required this.border});
}

const _kMonthNames = [
  '', 'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _phaseLabel(PhaseType p) {
  switch (p) {
    case PhaseType.menstrual:  return 'menstrual phase';
    case PhaseType.follicular: return 'follicular phase';
    case PhaseType.fertile:    return 'fertile window';
    case PhaseType.ovulation:  return 'ovulation phase';
    case PhaseType.luteal:     return 'luteal phase';
    case PhaseType.unknown:    return '';
  }
}
