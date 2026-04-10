import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';

/// Flutter equivalent of the React `usePredictionWindows()` hook.
///
/// Computes the set of date strings that fall within:
///  - [predictionDates] — the expected period window (windowEarly…windowLate)
///    plus the assumed ~5-day flow duration.
///  - [fertilityDates]  — fertilityStart…fertilityEnd from the prediction model.
class PredictionWindowsComputer {
  /// ISO-8601 date keys (`yyyy-MM-dd`) for the predicted period window.
  static Set<String> computePredictionDates(PredictionResultModel prediction) {
    final dates = <String>{};
    // Expand the window by 1 day on each side for visual clarity.
    var cursor = prediction.windowEarly.subtract(const Duration(days: 1));
    final end = prediction.windowLate.add(const Duration(days: 4)); // ~5-day period
    while (!cursor.isAfter(end)) {
      dates.add(_toKey(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
    return dates;
  }

  /// ISO-8601 date keys for the fertility window.
  static Set<String> computeFertilityDates(PredictionResultModel prediction) {
    final dates = <String>{};
    var cursor = prediction.fertilityStart;
    final end = prediction.fertilityEnd;
    while (!cursor.isAfter(end)) {
      dates.add(_toKey(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
    return dates;
  }

  static String _toKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String toKey(DateTime d) => _toKey(d);
}
