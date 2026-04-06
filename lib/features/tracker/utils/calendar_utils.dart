import 'package:flutter/material.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';

enum CyclePhase { menstrual, follicular, ovulation, luteal, unknown }

class CalendarUtils {
  static CyclePhase getPhaseForDate(DateTime date, CycleProfileModel profile, List<CycleLogModel> logs) {
    // Check if it's a logged period day
    final log = logs.firstWhere(
      (l) => DateUtils.isSameDay(l.date, date),
      orElse: () => CycleLogModel(id: '', date: date),
    );
    
    if (log.flow != null && log.flow != 'none' && log.flow != 'ended') {
      return CyclePhase.menstrual;
    }

    if (profile.lastPeriodStart == null) return CyclePhase.unknown;

    final diff = date.difference(profile.lastPeriodStart!).inDays;
    final cycleDay = (diff % (profile.avgCycleLength > 0 ? profile.avgCycleLength : 28)) + 1;

    if (cycleDay <= profile.avgPeriodDuration) {
      return CyclePhase.menstrual;
    } else if (cycleDay <= (profile.avgCycleLength / 2) - 2) {
      return CyclePhase.follicular;
    } else if (cycleDay <= (profile.avgCycleLength / 2) + 2) {
      return CyclePhase.ovulation;
    } else {
      return CyclePhase.luteal;
    }
  }

  static Color getPhaseColor(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return const Color(0xFFFCE4F3);
      case CyclePhase.follicular:
        return const Color(0xFFEDE9FE);
      case CyclePhase.ovulation:
        return const Color(0xFFFEF3C7);
      case CyclePhase.luteal:
        return const Color(0xFFDBEAFE);
      case CyclePhase.unknown:
        return Colors.transparent;
    }
  }

  static bool isDateInPredictionWindow(DateTime date, PredictionResultModel? prediction) {
    if (prediction == null) return false;
    return date.isAfter(prediction.windowEarly.subtract(const Duration(days: 1))) &&
           date.isBefore(prediction.windowLate.add(const Duration(days: 1)));
  }

  static List<List<DateTime>> getStreakRows(List<DateTime> daysInMonth, List<CycleLogModel> logs) {
    final streakRows = <List<DateTime>>[];
    for (int i = 0; i < daysInMonth.length; i += 7) {
      final row = daysInMonth.skip(i).take(7).toList();
      if (row.length < 7) continue;

      bool allLogged = true;
      for (final day in row) {
        final hasLog = logs.any((l) => DateUtils.isSameDay(l.date, day));
        if (!hasLog) {
          allLogged = false;
          break;
        }
      }

      if (allLogged) {
        streakRows.add(row);
      }
    }
    return streakRows;
  }
}
