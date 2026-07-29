import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:intl/intl.dart';

class PeriodHistoryList extends StatelessWidget {
  final List<CycleRecordModel> cycles;
  final CycleProfileModel profile;
  final void Function(String startDate) onCycleSelected;

  const PeriodHistoryList({
    super.key,
    required this.cycles,
    required this.profile,
    required this.onCycleSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Combine history with current active cycle from profile
    final List<CycleRecordModel> displayList = List<CycleRecordModel>.from(cycles);
    
    final hasActiveCycle = profile.lastPeriodStart != null;
    final isAlreadyInHistory = displayList.any((c) => 
      c.startDate.year == profile.lastPeriodStart?.year && 
      c.startDate.month == profile.lastPeriodStart?.month &&
      c.startDate.day == profile.lastPeriodStart?.day
    );

    if (hasActiveCycle && !isAlreadyInHistory) {
      // Synthesize a current cycle record
      displayList.add(CycleRecordModel(
        id: 'current',
        cycleNumber: (cycles.firstOrNull?.cycleNumber ?? 0) + 1,
        startDate: profile.lastPeriodStart!,
        periodStartDate: profile.lastPeriodStart!,
        isComplete: false,
      ));
    }

    // 2. Sort newest first
    displayList.sort((a, b) => b.startDate.compareTo(a.startDate));

    if (displayList.isEmpty) {
      return _buildEmptyState(context);
    }

    return Semantics(
      container: true,
      label: "Period history list",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Cycle History',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${displayList.length}',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildListWithGaps(displayList),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.1),
                      AppColors.purple.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🗓️', style: TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cycle History',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Track your body\'s natural patterns. Your cycle history will appear here once you start logging your periods.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: AppColors.textMedium,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        isCurrent: !cycle.isComplete,
        onTap: () => onCycleSelected(
          DateFormat('yyyy-MM-dd').format(cycle.periodStartDate),
        ),
      ));

      // Separate with spacing
      if (i < displayList.length - 1) {
        widgets.add(const SizedBox(height: 12));
        
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

class _CycleHistoryRow extends StatelessWidget {
  final CycleRecordModel cycle;
  final bool isCurrent;
  final VoidCallback onTap;

  const _CycleHistoryRow({
    required this.cycle,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('MMM d').format(cycle.periodStartDate);
    final endStr = cycle.periodEndDate != null
        ? DateFormat('MMM d, yyyy').format(cycle.periodEndDate!)
        : 'Present';
    
    final periodDuration = cycle.periodDurationDays ?? 5;
    final cycleLen = cycle.cycleLengthDays ?? 28;
    // final errorDays = cycle.predictionErrorDays ?? 0;
    // final isIrregular = errorDays.abs() > 4;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent ? const Color(0xFFFFEDD5) : const Color(0xFFF3F4F6),
            width: isCurrent ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. Status Indicator
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFFFFE4E6) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isCurrent ? '🩸' : '${cycle.cycleNumber}',
                  style: GoogleFonts.nunito(
                    fontSize: isCurrent ? 18 : 14,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 2. Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$startStr – $endStr',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFB7185),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'CURRENT',
                            style: GoogleFonts.nunito(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCurrent 
                      ? '$periodDuration days so far · Day ${DateTime.now().difference(cycle.startDate).inDays + 1}'
                      : '$periodDuration days period · $cycleLen day cycle',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Arrow
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}

class _GapTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'A gap was detected between these cycles.',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'Add Missing',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }
}
