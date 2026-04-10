import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/utils/calendar_types.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DayDetailPanel
// ─────────────────────────────────────────────────────────────────────────────

/// Inline edit panel shown below the calendar grid when a day is selected.
///
/// Slides up (translateY 80→0) and fades in over 280 ms.
/// Animation is skipped when [MediaQueryData.disableAnimations] is true.
class DayDetailPanel extends StatefulWidget {
  /// ISO date string `"YYYY-MM-DD"`, or null when nothing is selected.
  final String? selectedDate;
  final PhaseInfo? phaseInfo;
  final FlowLevel? existingFlow;
  final bool isFutureDay;
  final bool isPredictedPeriodDay;

  /// Called every time the user taps a flow pill.
  final void Function(FlowLevel) onFlowChange;

  /// Called when the user taps the Save button.
  final Future<void> Function() onSave;
  final bool isSaving;

  const DayDetailPanel({
    super.key,
    required this.selectedDate,
    required this.phaseInfo,
    required this.existingFlow,
    required this.isFutureDay,
    required this.isPredictedPeriodDay,
    required this.onFlowChange,
    required this.onSave,
    required this.isSaving,
  });

  @override
  State<DayDetailPanel> createState() => _DayDetailPanelState();
}

class _DayDetailPanelState extends State<DayDetailPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 1), // +80dp relative — SlideTransition uses fraction
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

    // Skip animation if reduce-motion is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _ctrl.value = 1.0;
      } else {
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedDate == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Semantics(
          label: 'Day details for ${_formattedDate(widget.selectedDate!)}',
          child: _PanelBody(
            selectedDate: widget.selectedDate!,
            phaseInfo: widget.phaseInfo,
            existingFlow: widget.existingFlow,
            isFutureDay: widget.isFutureDay,
            isPredictedPeriodDay: widget.isPredictedPeriodDay,
            onFlowChange: widget.onFlowChange,
            onSave: widget.onSave,
            isSaving: widget.isSaving,
          ),
        ),
      ),
    );
  }

  static String _formattedDate(String iso) {
    try {
      return DateFormat('EEEE d MMMM').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PanelBody  (pure StatelessWidget, receives all state from parent)
// ─────────────────────────────────────────────────────────────────────────────

class _PanelBody extends StatelessWidget {
  final String selectedDate;
  final PhaseInfo? phaseInfo;
  final FlowLevel? existingFlow;
  final bool isFutureDay;
  final bool isPredictedPeriodDay;
  final void Function(FlowLevel) onFlowChange;
  final Future<void> Function() onSave;
  final bool isSaving;

  const _PanelBody({
    required this.selectedDate,
    required this.phaseInfo,
    required this.existingFlow,
    required this.isFutureDay,
    required this.isPredictedPeriodDay,
    required this.onFlowChange,
    required this.onSave,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final phase = phaseInfo?.phase ?? PhaseType.unknown;
    final style = _PhaseStyle.of(phase, phaseInfo?.isPredicted ?? false);

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.borderColor.withAlpha(51), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: style.accentColor.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Header row ─────────────────────────────────────────────────
          _Header(
            dateStr: selectedDate,
            phaseInfo: phaseInfo,
            style: style,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 2. Predicted future info box ────────────────────────────
                if (isFutureDay && isPredictedPeriodDay) ...[
                  _PredictedInfoBox(phaseInfo: phaseInfo),
                  const SizedBox(height: 12),
                ],

                // ── 3. Flow pills (past / today only) ───────────────────────
                if (!isFutureDay) ...[
                  _FlowPillRow(
                    selected: existingFlow ?? FlowLevel.none,
                    phase: phase,
                    style: style,
                    onSelect: onFlowChange,
                  ),
                  const SizedBox(height: 14),
                ],

                // ── 4. Save button ───────────────────────────────────────────
                _SaveButton(isSaving: isSaving, onSave: onSave),

                // ── 5. Phase tip ─────────────────────────────────────────────
                const SizedBox(height: 10),
                _PhaseTip(phase: phase),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String dateStr;
  final PhaseInfo? phaseInfo;
  final _PhaseStyle style;

  const _Header({
    required this.dateStr,
    required this.phaseInfo,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(dateStr);
    final isToday = date != null && DateUtils.isSameDay(date, DateTime.now());

    final label = isToday
        ? 'Today'
        : date != null
            ? DateFormat('EEE, d MMM').format(date)
            : dateStr;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: style.bgColor.withAlpha(90),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Date label
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),

          // Phase chip badge
          if (phaseInfo != null)
            _PhaseChipBadge(phaseInfo: phaseInfo!, style: style),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PhaseChipBadge
// ─────────────────────────────────────────────────────────────────────────────

class _PhaseChipBadge extends StatelessWidget {
  final PhaseInfo phaseInfo;
  final _PhaseStyle style;

  const _PhaseChipBadge({required this.phaseInfo, required this.style});

  @override
  Widget build(BuildContext context) {
    final label = _phaseLabel(phaseInfo.phase, phaseInfo.isPredicted);

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: phaseInfo.isPredicted
            ? Colors.white
            : style.accentColor.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: phaseInfo.isPredicted
            ? null // dashed painted separately
            : Border.all(color: style.accentColor.withAlpha(77), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: style.accentColor,
        ),
      ),
    );

    if (phaseInfo.isPredicted) {
      chip = Stack(
        children: [
          chip,
          Positioned.fill(
            child: CustomPaint(
              painter: _DashedChipBorderPainter(
                color: style.accentColor,
                radius: 20,
              ),
            ),
          ),
        ],
      );
    }

    return chip;
  }

  static String _phaseLabel(PhaseType p, bool isPredicted) {
    if (isPredicted) return '🔮 Predicted';
    switch (p) {
      case PhaseType.menstrual:  return '🩸 Menstrual';
      case PhaseType.follicular: return '🌱 Follicular';
      case PhaseType.fertile:    return '✨ Fertile Window';
      case PhaseType.ovulation:  return '✨ Ovulation';
      case PhaseType.luteal:     return '🌙 Luteal';
      case PhaseType.unknown:    return '🌸 Unknown';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PredictedInfoBox  (future + predicted)
// ─────────────────────────────────────────────────────────────────────────────

class _PredictedInfoBox extends StatelessWidget {
  final PhaseInfo? phaseInfo;

  const _PredictedInfoBox({required this.phaseInfo});

  @override
  Widget build(BuildContext context) {
    // Confidence comes through as opacity proxy: opacity>=0.9=high, >=0.6=medium, else low
    final opacity = phaseInfo?.opacity ?? 0.5;
    final conf = opacity >= 0.9
        ? 'High'
        : opacity >= 0.6
            ? 'Medium'
            : 'Low';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔮', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Predicted period day — Gigi\'s confidence: $conf. '
              'Has your period started? Tap a flow level below.',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: const Color(0xFF7C3AED),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FlowPillRow
// ─────────────────────────────────────────────────────────────────────────────

class _FlowPillRow extends StatelessWidget {
  final FlowLevel selected;
  final PhaseType phase;
  final _PhaseStyle style;
  final void Function(FlowLevel) onSelect;

  const _FlowPillRow({
    required this.selected,
    required this.phase,
    required this.style,
    required this.onSelect,
  });

  static const _levels = [
    FlowLevel.none,
    FlowLevel.spotting,
    FlowLevel.light,
    FlowLevel.medium,
    FlowLevel.heavy,
    FlowLevel.ended,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _levels
          .map((lvl) => _FlowPill(
                level: lvl,
                isSelected: lvl == selected,
                style: style,
                onTap: () => onSelect(lvl),
              ))
          .toList(),
    );
  }
}

class _FlowPill extends StatelessWidget {
  final FlowLevel level;
  final bool isSelected;
  final _PhaseStyle style;
  final VoidCallback onTap;

  const _FlowPill({
    required this.level,
    required this.isSelected,
    required this.style,
    required this.onTap,
  });

  static String _label(FlowLevel l) {
    switch (l) {
      case FlowLevel.none:     return 'None';
      case FlowLevel.spotting: return 'Spotting';
      case FlowLevel.light:    return 'Light';
      case FlowLevel.medium:   return 'Medium';
      case FlowLevel.heavy:    return 'Heavy';
      case FlowLevel.ended:    return 'Ended';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${_label(level)} flow',
      checked: isSelected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? style.bgColor : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? style.accentColor.withAlpha(180)
                  : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            _label(level),
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? style.accentColor : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SaveButton
// ─────────────────────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final Future<void> Function() onSave;

  const _SaveButton({required this.isSaving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Save and update prediction',
      child: GestureDetector(
        onTap: isSaving
            ? null
            : () async {
                await onSave();
                if (context.mounted) {
                  SemanticsService.announce(
                    'Log saved and prediction updated.',
                    ui.TextDirection.ltr,
                  );
                }
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 42,
          decoration: BoxDecoration(
            gradient: isSaving
                ? const LinearGradient(
                    colors: [Color(0xFFE9D5FF), Color(0xFFFCE7F3)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  'Save & update prediction',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PhaseTip
// ─────────────────────────────────────────────────────────────────────────────

class _PhaseTip extends StatelessWidget {
  final PhaseType phase;

  const _PhaseTip({required this.phase});

  static String _tip(PhaseType p) {
    switch (p) {
      case PhaseType.menstrual:  return 'Rest, warmth, iron-rich foods';
      case PhaseType.follicular: return 'Great time to start new habits';
      case PhaseType.fertile:    return 'High energy — stay active';
      case PhaseType.ovulation:  return 'Peak energy — social activities';
      case PhaseType.luteal:     return 'Reflective, finish projects, magnesium';
      case PhaseType.unknown:    return 'Log daily to reveal your patterns';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('💡', style: TextStyle(fontSize: 10)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            _tip(phase),
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF6B7280),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PhaseStyle  (colour lookup table)
// ─────────────────────────────────────────────────────────────────────────────

class _PhaseStyle {
  final Color bgColor;
  final Color borderColor;
  final Color accentColor;

  const _PhaseStyle({
    required this.bgColor,
    required this.borderColor,
    required this.accentColor,
  });

  static _PhaseStyle of(PhaseType phase, bool isPredicted) {
    if (isPredicted) {
      return const _PhaseStyle(
        bgColor: Color(0xFFF5F3FF),
        borderColor: Color(0xFFE9D5FF),
        accentColor: Color(0xFF7C3AED),
      );
    }
    switch (phase) {
      case PhaseType.menstrual:
        return const _PhaseStyle(
          bgColor: Color(0xFFFEF2F2),
          borderColor: Color(0xFFFECACA),
          accentColor: Color(0xFFDC2626),
        );
      case PhaseType.follicular:
        return const _PhaseStyle(
          bgColor: Color(0xFFFDF4FF),
          borderColor: Color(0xFFE9D5FF),
          accentColor: Color(0xFF7C3AED),
        );
      case PhaseType.fertile:
        return const _PhaseStyle(
          bgColor: Color(0xFFFFF7ED),
          borderColor: Color(0xFFFFEDD5),
          accentColor: Color(0xFFF59E0B),
        );
      case PhaseType.ovulation:
        return const _PhaseStyle(
          bgColor: Color(0xFFFFFBEB),
          borderColor: Color(0xFFFDE68A),
          accentColor: Color(0xFFD97706),
        );
      case PhaseType.luteal:
        return const _PhaseStyle(
          bgColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFFBFDBFE),
          accentColor: Color(0xFF1D4ED8),
        );
      case PhaseType.unknown:
        return const _PhaseStyle(
          bgColor: Color(0xFFF9FAFB),
          borderColor: Color(0xFFE5E7EB),
          accentColor: Color(0xFF6B7280),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DashedChipBorderPainter
// ─────────────────────────────────────────────────────────────────────────────

class _DashedChipBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedChipBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dash = 3.0;
    const gap  = 2.5;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0.6, 0.6, size.width - 1.2, size.height - 1.2),
        Radius.circular(radius),
      ));

    for (final m in path.computeMetrics()) {
      double pos = 0;
      bool draw = true;
      while (pos < m.length) {
        final len = draw ? dash : gap;
        if (draw) {
          canvas.drawPath(
            m.extractPath(pos, math.min(pos + len, m.length)),
            paint,
          );
        }
        pos += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedChipBorderPainter old) =>
      old.color != color || old.radius != radius;
}
