import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PredictedCycle  —  value type for one future cycle window
// ─────────────────────────────────────────────────────────────────────────────

/// Represents one client-computed future cycle prediction.
///
/// Values are derived solely from [PredictionResultModel] +
/// [CycleProfileModel] — no extra network call is needed.
@immutable
class PredictedCycle {
  /// First day of the predicted period (same as `predictedStart` for cycle 0).
  final DateTime start;

  /// Last preiod-flow day (start + avgPeriodDuration - 1).
  final DateTime periodEnd;

  /// Last day of the cycle (start + avgCycleLength - 1).
  final DateTime cycleEnd;

  /// Early boundary of the confidence window.
  final DateTime windowEarly;

  /// Late boundary of the confidence window.
  final DateTime windowLate;

  /// 1 = first future cycle, 5 = fifth future cycle.
  final int monthsAhead;

  /// Confidence opacity: 1.0 → 0.40 (decreases 0.15 per cycle).
  final double opacity;

  /// Always true for predicted cycles.
  final bool isPredicted;

  const PredictedCycle({
    required this.start,
    required this.periodEnd,
    required this.cycleEnd,
    required this.windowEarly,
    required this.windowLate,
    required this.monthsAhead,
    required this.opacity,
    this.isPredicted = true,
  });

  /// All calendar date keys (`yyyy-MM-dd`) that belong to this cycle's
  /// predicted period window (windowEarly .. windowLate + avgPeriodDuration).
  Set<String> get periodWindowDates {
    final dates = <String>{};
    var cursor = windowEarly;
    while (!cursor.isAfter(periodEnd)) {
      dates.add(_toKey(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
    return dates;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictedCycle &&
          other.start == start &&
          other.monthsAhead == monthsAhead;

  @override
  int get hashCode => Object.hash(start, monthsAhead);

  @override
  String toString() =>
      'PredictedCycle(#$monthsAhead start=$start opacity=${opacity.toStringAsFixed(2)})';
}

// ─────────────────────────────────────────────────────────────────────────────
// PredictionWindowsProvider
// ─────────────────────────────────────────────────────────────────────────────

/// Client-side computation of 5 future predicted cycle windows.
///
/// The backend provides only the *next* predicted start date.
/// This class projects that forward using [avgCycleLength] from
/// [CycleProfileModel] to produce windows for up to 5 future cycles —
/// keeping the prediction API fast and the server stateless.
///
/// Usage:
/// ```dart
/// final windows = PredictionWindowsProvider.compute(
///   prediction: state.prediction,
///   profile: state.profile,
/// );
/// final allDates = PredictionWindowsProvider.computeAllDates(windows);
/// ```
class PredictionWindowsProvider {
  PredictionWindowsProvider._(); // static-only

  static const _maxCycles = 5;

  // ── Primary API ─────────────────────────────────────────────────────────────

  /// Compute up to 5 [PredictedCycle] windows from [prediction] + [profile].
  ///
  /// Returns an empty list when no valid prediction is available
  /// (i.e., [prediction] is null, or its `predictedStart` is in the past and
  /// `daysUntilPrediction` is negative).
  static List<PredictedCycle> compute({
    required PredictionResultModel? prediction,
    required CycleProfileModel profile,
  }) {
    // ── Step 1: Guard — prediction available? ─────────────────────────────
    if (!_isPredictionAvailable(prediction)) return const [];

    final p = prediction!;

    // ── Step 2–4: Base values ─────────────────────────────────────────────
    final base      = DateTime(p.predictedStart.year,
                               p.predictedStart.month,
                               p.predictedStart.day);
    final avgLen    = profile.avgCycleLength;      // from CycleProfileModel
    final avgPeriod = profile.avgPeriodDuration;   // from CycleProfileModel

    // ── Step 5–6: Window offset in days (signed) ──────────────────────────
    // windowEarly is before base  → earlyDays is negative
    // windowLate  is after  base  → lateDays  is positive
    final early     = DateTime(p.windowEarly.year,
                               p.windowEarly.month,
                               p.windowEarly.day);
    final late_     = DateTime(p.windowLate.year,
                               p.windowLate.month,
                               p.windowLate.day);
    final earlyDays = early.difference(base).inDays;   // ≤ 0
    final lateDays  = late_.difference(base).inDays;   // ≥ 0

    // ── Step 7: Build 5 cycles ────────────────────────────────────────────
    final windows = <PredictedCycle>[];

    for (int i = 0; i < _maxCycles; i++) {
      final DateTime start;
      if (i == 0) {
        start = base;
      } else {
        start = windows[i - 1].start.add(Duration(days: avgLen));
      }

      final opacity     = math.max(0.30, 1.0 - i * 0.15);
      final windowEarly = start.add(Duration(days: earlyDays));
      final windowLate  = start.add(Duration(days: lateDays));
      final periodEnd   = start.add(Duration(days: avgPeriod - 1));
      final cycleEnd    = start.add(Duration(days: avgLen - 1));

      windows.add(PredictedCycle(
        start:       start,
        periodEnd:   periodEnd,
        cycleEnd:    cycleEnd,
        windowEarly: windowEarly,
        windowLate:  windowLate,
        monthsAhead: i + 1,
        opacity:     opacity,
        isPredicted: true,
      ));
    }

    debugPrint('[PredictionWindowsProvider] Generated ${windows.length} '
        'predicted cycles from ${_toKey(base)}');

    return windows;
  }

  // ── Convenience helpers ──────────────────────────────────────────────────────

  /// Flat set of all `yyyy-MM-dd` keys for every predicted cycle's period
  /// window across all [windows] — suitable as `CalendarGrid.predictionDates`.
  static Set<String> computeAllDates(List<PredictedCycle> windows) {
    final dates = <String>{};
    for (final w in windows) {
      dates.addAll(w.periodWindowDates);
    }
    return dates;
  }

  /// Returns only the cycles whose period window overlaps with the
  /// [year]/[month] being viewed — used to avoid computing phases for
  /// cycles far in the future.
  static List<PredictedCycle> forMonth(
    List<PredictedCycle> windows,
    int year,
    int month,
  ) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd   = DateTime(year, month + 1, 0); // last day
    return windows.where((w) {
      // Overlaps if window's period hasn't ended before month starts,
      // and the cycle hasn't started after month ends.
      return !w.periodEnd.isBefore(monthStart) &&
             !w.start.isAfter(monthEnd);
    }).toList();
  }

  /// Derive the opacity value for a specific date that falls inside
  /// [windows]. Returns null if the date isn't in any predicted window.
  static double? opacityForDate(DateTime date, List<PredictedCycle> windows) {
    final key = _toKey(date);
    for (final w in windows) {
      if (w.periodWindowDates.contains(key)) return w.opacity;
    }
    return null;
  }

  // ── Internal helpers ─────────────────────────────────────────────────────────

  /// A prediction is considered "available" when the next predicted start
  /// is in the future (or today), i.e. [daysUntilPrediction] >= 0, and the
  /// prediction model is non-null.
  static bool _isPredictionAvailable(PredictionResultModel? p) {
    if (p == null) return false;
    // daysUntilPrediction < 0 means the window has already passed with no log
    return p.daysUntilPrediction >= 0;
  }
}

String _toKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
