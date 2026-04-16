import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:intl/intl.dart';

/// Renders the last 5 complete menstrual cycles with gap detection and
/// deep-link navigation back into the calendar grid.
class PeriodHistoryList extends StatelessWidget {
  final List<CycleRecordModel> cycles;
  final void Function(String startDate) onCycleSelected;

  const PeriodHistoryList({
    super.key,
    required this.cycles,
    required this.onCycleSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Filter: Last 5 COMPLETE cycles
    final completeCycles =
        cycles.where((c) => c.isComplete).toList();
    
    // Sort newest first just in case
    completeCycles.sort((a, b) => b.startDate.compareTo(a.startDate));

    final displayList = completeCycles.take(5).toList();

    if (displayList.isEmpty) {
      return const Column(
        children: [
          SizedBox(height: 32),
          Text(
            'Log your first period to see your cycle history.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          SizedBox(height: 32),
        ],
      );
    }

    return Semantics(
      container: true,
      label: "Period history list",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Text(
              'Cycle History',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          _buildListWithGaps(displayList),
        ],
      ),
    );
  }

  Widget _buildListWithGaps(List<CycleRecordModel> displayList) {
    final widgets = <Widget>[];

    for (int i = 0; i < displayList.length; i++) {
      final cycle = displayList[i];

      // Add the cycle row
      widgets.add(_CycleHistoryRow(
        cycle: cycle,
        onTap: () => onCycleSelected(
          DateFormat('yyyy-MM-dd').format(cycle.periodStartDate),
        ),
      ));

      // Separate with spacing
      if (i < displayList.length - 1) {
        widgets.add(const SizedBox(height: 12));
        
        // Gap detection logic: gap between current cycle end and next (older) cycle start? 
        // Wait, if it's newest first: cycles[i] is newer than cycles[i+1].
        // Gap is between cycles[i+1]'s endDate and cycles[i]'s startDate.
        final nextCycle = displayList[i + 1];
        if (cycle.startDate.difference(nextCycle.endDate ?? nextCycle.startDate).inDays > 42) {
          widgets.add(_GapTile());
          widgets.add(const SizedBox(height: 12));
        }
      }
    }

    return Column(children: widgets);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CycleHistoryRow extends StatelessWidget {
  final CycleRecordModel cycle;
  final VoidCallback onTap;

  const _CycleHistoryRow({required this.cycle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('MMM d').format(cycle.periodStartDate);
    final endStr = cycle.periodEndDate != null
        ? DateFormat('MMM d, yyyy').format(cycle.periodEndDate!)
        : '?';
    
    final periodDuration = cycle.periodDurationDays ?? 5;
    final cycleLen = cycle.cycleLengthDays ?? 28;
    final errorDays = cycle.predictionErrorDays ?? 0;
    final isIrregular = errorDays.abs() > 4;

    final a11yLabel = "Cycle ${cycle.cycleNumber}. $startStr to $endStr. "
        "$periodDuration days period, $cycleLen day cycle.";

    return Semantics(
      button: true,
      label: a11yLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3F4F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 1. Cycle number badge
              CircleAvatar(
                radius: 11,
                backgroundColor: const Color(0xFFF3F4F6),
                child: Text(
                  '${cycle.cycleNumber}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. Date range Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$startStr – $endStr',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$periodDuration days period · $cycleLen day cycle',
                      style: GoogleFonts.nunito(
                        fontSize: 9,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Cycle length badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${cycleLen}d',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ),

              // 4. Irregular indicator
              if (isIrregular) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    '±${errorDays.abs()}d',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GapTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Gap detected — did you miss logging a period?',
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          const Text(
            'Tap to add →',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }
}
