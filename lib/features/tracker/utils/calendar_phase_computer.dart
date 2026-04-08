import 'package:flutter/material.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/utils/calendar_utils.dart';

/// Flutter equivalent of the React `usePhaseComputer()` hook.
///
/// Pre-computes a [CyclePhase] for every date in a given range so that
/// [CalendarGrid] never has to call per-cell logic on each rebuild.
class CalendarPhaseComputer {
  /// Returns a map keyed by ISO-8601 date string (`yyyy-MM-dd`) → [CyclePhase].
  ///
  /// [from] and [to] define the date range (inclusive).
  /// All logs across the 3-month window should be passed in [logs].
  static Map<String, CyclePhase> compute({
    required DateTime from,
    required DateTime to,
    required CycleProfileModel profile,
    required List<CycleLogModel> logs,
    required List<CycleRecordModel> cycles,
    required Set<String> fertilityDates,
    required DateTime? ovulationDate,
  }) {
    final map = <String, CyclePhase>{};
    var cursor = DateTime(from.year, from.month, from.day);
    final rangeEnd = DateTime(to.year, to.month, to.day);

    // 0. Sort cycles newest first to ensure firstWhere picks the current cycle on boundary days.
    final sortedCycles = List<CycleRecordModel>.from(cycles)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    while (!cursor.isAfter(rangeEnd)) {
      final key = _toKey(cursor);
      final cursorDate = DateUtils.dateOnly(cursor);
      
      // 1. Check Cycle Records (Historical and Current)
      final record = sortedCycles.firstWhere(
        (c) => !cursorDate.isBefore(DateUtils.dateOnly(c.startDate)) && 
               (c.endDate == null || !cursorDate.isAfter(DateUtils.dateOnly(c.endDate!))),
        orElse: () => CycleRecordModel(id: '', cycleNumber: 0, startDate: DateTime(0), periodStartDate: DateTime(0)),
      );

      if (record.id.isNotEmpty) {
        final recPeriodStart = DateUtils.dateOnly(record.periodStartDate);
        // Effective period end: either the actual date, or a fallback based on avg duration
        final effectivePeriodEnd = record.periodEndDate != null
            ? DateUtils.dateOnly(record.periodEndDate!)
            : recPeriodStart.add(Duration(days: (profile.avgPeriodDuration > 0 ? profile.avgPeriodDuration : 5) - 1));

        // If within the period part of that record
        if (!cursorDate.isBefore(recPeriodStart) && !cursorDate.isAfter(effectivePeriodEnd)) {
          map[key] = CyclePhase.menstrual;
        } else {
          // It's in a cycle but outside the period
          final cycleStart = DateUtils.dateOnly(record.startDate);
          final diff = cursorDate.difference(cycleStart).inDays;
          final cycleDay = diff + 1;
          final cycleLen = record.cycleLengthDays ?? (profile.avgCycleLength > 0 ? profile.avgCycleLength : 28);
          
          // Estimated Ovulation: Standard is 14 days before the end of the cycle (the Luteal phase is constant)
          final ovulationDay = cycleLen - 13; // e.g. Day 15 for a 28-day cycle
          
          if (cycleDay == ovulationDay) {
            map[key] = CyclePhase.ovulation;
          } else if (cycleDay >= ovulationDay - 4 && cycleDay <= ovulationDay + 1) {
            // Fertile window (6 days total: 5 before ovulation, 1 after)
            map[key] = CyclePhase.fertile;
          } else if (cycleDay < ovulationDay) {
            map[key] = CyclePhase.follicular;
          } else {
            map[key] = CyclePhase.luteal;
          }
        }
      } else if (ovulationDate != null && DateUtils.isSameDay(cursorDate, DateUtils.dateOnly(ovulationDate))) {
        // 2. Ovulation Day (usually current prediction)
        map[key] = CyclePhase.ovulation;
      } else if (fertilityDates.contains(key)) {
        // 3. Fertile Window (current prediction)
        map[key] = CyclePhase.fertile;
      } else if (profile.lastPeriodStart != null && !cursorDate.isBefore(DateUtils.dateOnly(profile.lastPeriodStart!))) {
        // 4. Current/Future Cycle Phases (if not covered by records yet)
        final phase = CalendarUtils.getPhaseForDate(cursorDate, profile, logs);
        final diff = cursorDate.difference(DateUtils.dateOnly(profile.lastPeriodStart!)).inDays;
        if (diff < profile.avgCycleLength + 5) { // Allow some slack for future display
          map[key] = phase;
        } else {
          map[key] = CyclePhase.unknown;
        }
      } else {
        map[key] = CyclePhase.unknown;
      }
      
      cursor = cursor.add(const Duration(days: 1));
    }
    return map;
  }

  /// Convenience method: compute for the prev + current + next month window.
  static Map<String, CyclePhase> computeForWindow(
    int year,
    int month, {
    required CycleProfileModel profile,
    required List<CycleLogModel> logs,
    required List<CycleRecordModel> cycles,
    required Set<String> fertilityDates,
    required DateTime? ovulationDate,
  }) {
    final windowStart = DateTime(year, month - 1, 1);
    final windowEnd = DateTime(year, month + 2, 0); // last day of month+1
    return compute(
      from: windowStart,
      to: windowEnd,
      profile: profile,
      logs: logs,
      cycles: cycles,
      fertilityDates: fertilityDates,
      ovulationDate: ovulationDate,
    );
  }

  static String _toKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
