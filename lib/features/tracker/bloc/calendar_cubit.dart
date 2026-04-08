import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart';
import 'package:infano_care_mobile/features/tracker/utils/calendar_phase_computer.dart';
import 'package:infano_care_mobile/features/tracker/utils/calendar_utils.dart';
import 'package:infano_care_mobile/features/tracker/utils/prediction_windows_computer.dart';
import 'package:infano_care_mobile/features/tracker/utils/prediction_windows_provider.dart';

part 'calendar_cubit.freezed.dart';

// ── State ────────────────────────────────────────────────────────────────────

@freezed
class CalendarState with _$CalendarState {
  const factory CalendarState.initial() = _Initial;
  const factory CalendarState.loading() = _Loading;
  const factory CalendarState.loaded({
    required int viewYear,
    required int viewMonth,
    required CycleProfileModel profile,
    PredictionResultModel? prediction,
    @Default([]) List<CycleLogModel> logs,
    @Default([]) List<CycleRecordModel> cycles,

    /// Phase for every day in the 3-month window: key = 'yyyy-MM-dd'
    @Default({}) Map<String, CyclePhase> phaseMap,

    /// Dates inside the predicted period window: key = 'yyyy-MM-dd'
    /// Covers ALL 5 future predicted cycles (not just the next one).
    @Default({}) Set<String> predictionDates,

    /// Dates inside the fertility window
    @Default({}) Set<String> fertilityDates,

    /// The 5 computed future cycle windows (from PredictionWindowsProvider).
    @Default([]) List<PredictedCycle> predictedCycles,

    /// Currently tapped date (shown in DayDetailPanel)
    String? selectedDate,

    /// Edit Mode State
    @Default(false) bool isEditMode,
    DateTime? editStartDate,
    DateTime? editEndDate,
    @Default(false) bool isSavingRange,

    /// True while a background refresh is happening alongside stale data
    @Default(false) bool isRefreshing,

    /// True when data came from the offline cache
    @Default(false) bool isOffline,
  }) = _Loaded;
  const factory CalendarState.error(String message) = _Error;
}

// ── Cubit ────────────────────────────────────────────────────────────────────

class CalendarCubit extends Cubit<CalendarState> {
  final TrackerRepository _repository;

  /// Current view position — kept here so it survives state rebuilds.
  late int _viewYear;
  late int _viewMonth;

  static final _now = DateTime.now();

  /// Min: 12 months back. Max: 5 months forward.
  static int get _minMonthOffset => -12;
  static int get _maxMonthOffset => 5;

  CalendarCubit(this._repository) : super(const CalendarState.initial()) {
    _viewYear = _now.year;
    _viewMonth = _now.month;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> loadCalendarData() async {
    emit(const CalendarState.loading());
    await _fetchAndEmit(_viewYear, _viewMonth);
  }

  /// Navigate month by [delta] (+1 = forward, -1 = back).
  Future<void> changeMonth(int delta) async {
    // Compute candidate month
    int newMonth = _viewMonth + delta;
    int newYear = _viewYear;
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear--;
    }

    // Guard min/max bounds
    final currentBase = DateTime(_now.year, _now.month);
    final candidate = DateTime(newYear, newMonth);
    final offsetMonths = _monthDiff(currentBase, candidate);
    if (offsetMonths < _minMonthOffset || offsetMonths > _maxMonthOffset) return;

    _viewYear = newYear;
    _viewMonth = newMonth;

    // Show stale data + isRefreshing while fetching, if already loaded
    final prev = state;
    if (prev is _Loaded) {
      emit(prev.copyWith(
        viewYear: newYear,
        viewMonth: newMonth,
        isRefreshing: true,
        selectedDate: null,
      ));
    } else {
      emit(const CalendarState.loading());
    }

    await _fetchAndEmit(newYear, newMonth, showLoading: false);
  }

  /// Jump to a specific month and optionally select a date.
  /// Used by [PeriodHistoryList] to navigate to past cycles.
  Future<void> jumpToMonth(int year, int month, {String? selectedDate}) async {
    // Guard min/max bounds
    final currentBase = DateTime(_now.year, _now.month);
    final candidate = DateTime(year, month);
    final offsetMonths = _monthDiff(currentBase, candidate);
    if (offsetMonths < _minMonthOffset || offsetMonths > _maxMonthOffset) return;

    _viewYear = year;
    _viewMonth = month;

    final prev = state;
    if (prev is _Loaded) {
      emit(prev.copyWith(
        viewYear: year,
        viewMonth: month,
        isRefreshing: true,
        selectedDate: selectedDate,
      ));
    } else {
      emit(const CalendarState.loading());
    }

    await _fetchAndEmit(year, month, showLoading: false);
  }

  void selectDate(String? dateStr) {
    final s = state;
    if (s is! _Loaded) return;
    if (s.isEditMode) {
      if (dateStr == null) return;
      final date = DateTime.tryParse(dateStr);
      if (date != null) _handleEditTap(date);
      return;
    }
    emit(s.copyWith(selectedDate: s.selectedDate == dateStr ? null : dateStr));
  }

  void toggleEditMode() {
    final s = state;
    if (s is! _Loaded) return;
    if (s.isEditMode) {
      // Exiting edit mode - clear states
      emit(s.copyWith(
        isEditMode: false,
        editStartDate: null,
        editEndDate: null,
        isSavingRange: false,
      ));
    } else {
      emit(s.copyWith(isEditMode: true));
    }
  }

  void _handleEditTap(DateTime date) {
    final s = state;
    if (s is! _Loaded) return;

    final dateOnly = DateUtils.dateOnly(date);

    if (s.editStartDate == null) {
      // First tap: Select starting date + default duration
      final duration = s.profile.avgPeriodDuration;
      final endDate = dateOnly.add(Duration(days: duration - 1));
      emit(s.copyWith(
        editStartDate: dateOnly,
        editEndDate: endDate,
      ));
    } else {
      final start = DateUtils.dateOnly(s.editStartDate!);
      final end   = s.editEndDate != null ? DateUtils.dateOnly(s.editEndDate!) : null;

      // If user taps the exact start or end date that is already selected alone, clear selection
      if (dateOnly.isAtSameMomentAs(start) && (end == null || dateOnly.isAtSameMomentAs(end))) {
        emit(s.copyWith(editStartDate: null, editEndDate: null));
        return;
      }

      // Second tap: Adjust range
      if (dateOnly.isBefore(start)) {
        emit(s.copyWith(editStartDate: dateOnly));
      } else {
        emit(s.copyWith(editEndDate: dateOnly));
      }
    }
  }

  Future<void> confirmEditRange() async {
    final s = state;
    if (s is! _Loaded || s.editStartDate == null || s.editEndDate == null) return;

    emit(s.copyWith(isSavingRange: true));
    try {
      await _repository.updatePeriodRange(s.editStartDate!, s.editEndDate!);
      
      // Success: Clear edit mode and refresh
      emit(s.copyWith(
        isEditMode: false,
        editStartDate: null,
        editEndDate: null,
        isSavingRange: false,
      ));
      await refreshAfterLog();
    } catch (e) {
      emit(s.copyWith(isSavingRange: false));
      // Re-throw so UI can catch it if needed, or we could emit error
      rethrow;
    }
  }

  /// Call this after a successful POST /logs to invalidate & reload.
  Future<void> refreshAfterLog() async {
    await _repository.invalidateLogsCache();
    await _fetchAndEmit(_viewYear, _viewMonth, forceRefresh: true);
  }

  // ── Internals ───────────────────────────────────────────────────────────────

  Future<void> _fetchAndEmit(
    int year,
    int month, {
    bool showLoading = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Parallel fetch
      final results = await Future.wait([
        _repository.getProfile(),
        _repository.getPredictionCached(forceRefresh: forceRefresh),
        _repository.getLogsForWindow(year, month, forceRefresh: forceRefresh),
        _repository.getCyclesCached(forceRefresh: forceRefresh),
      ]);

      final profile = results[0] as CycleProfileModel?;
      if (profile == null) {
        emit(const CalendarState.error('Tracker not set up'));
        return;
      }

      final prediction = results[1] as PredictionResultModel?;
      final logs = results[2] as List<CycleLogModel>;
      final cycles = results[3] as List<CycleRecordModel>;

      // 5-cycle prediction windows
      final predictedCycles = PredictionWindowsProvider.compute(
        prediction: prediction,
        profile: profile,
      );
      // All future period dates (all 5 cycles) for CalendarGrid highlighting
      final predictionDates = predictedCycles.isNotEmpty
          ? PredictionWindowsProvider.computeAllDates(predictedCycles)
          : prediction != null
              ? PredictionWindowsComputer.computePredictionDates(prediction)
              : <String>{};

      final fertilityDates = prediction != null
          ? PredictionWindowsComputer.computeFertilityDates(prediction)
          : <String>{};

      // Compute derived sets (expensive, done once per load)
      final phaseMap = CalendarPhaseComputer.computeForWindow(
        year, month,
        profile: profile,
        logs: logs,
        cycles: cycles,
        fertilityDates: fertilityDates,
        ovulationDate: prediction?.ovulationDate,
      );

      final prev = state;
      final prevSelected = prev is _Loaded ? prev.selectedDate : null;

      emit(CalendarState.loaded(
        viewYear: year,
        viewMonth: month,
        profile: profile,
        prediction: prediction,
        logs: logs,
        cycles: cycles,
        phaseMap: phaseMap,
        predictionDates: predictionDates,
        fertilityDates: fertilityDates,
        predictedCycles: predictedCycles,
        selectedDate: prevSelected,
        isRefreshing: false,
      ));
    } catch (e) {
      emit(CalendarState.error(e.toString()));
    }
  }

  int _monthDiff(DateTime a, DateTime b) =>
      (b.year - a.year) * 12 + (b.month - a.month);
}
