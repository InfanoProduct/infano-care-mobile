import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart';
import 'package:infano_care_mobile/features/tracker/utils/calendar_types.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CalendarEditState  (immutable value object)
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable snapshot of all edit-side state managed by [CalendarEditNotifier].
@immutable
class CalendarEditState {
  final String? selectedDate;
  final FlowLevel? pendingFlow;
  final bool isSaving;
  final bool isOffline;

  /// Non-null while a "new period start?" confirmation is pending.
  final _NewPeriodPrompt? newPeriodPrompt;

  /// Non-null while an "early period" notification is active.
  final _EarlyPeriodPrompt? earlyPeriodPrompt;

  const CalendarEditState({
    this.selectedDate,
    this.pendingFlow,
    this.isSaving = false,
    this.isOffline = false,
    this.newPeriodPrompt,
    this.earlyPeriodPrompt,
  });

  CalendarEditState copyWith({
    String? selectedDate,
    bool clearSelectedDate = false,
    FlowLevel? pendingFlow,
    bool clearPendingFlow = false,
    bool? isSaving,
    bool? isOffline,
    _NewPeriodPrompt? newPeriodPrompt,
    bool clearNewPeriodPrompt = false,
    _EarlyPeriodPrompt? earlyPeriodPrompt,
    bool clearEarlyPeriodPrompt = false,
  }) {
    return CalendarEditState(
      selectedDate:
          clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      pendingFlow:
          clearPendingFlow ? null : (pendingFlow ?? this.pendingFlow),
      isSaving: isSaving ?? this.isSaving,
      isOffline: isOffline ?? this.isOffline,
      newPeriodPrompt:
          clearNewPeriodPrompt ? null : (newPeriodPrompt ?? this.newPeriodPrompt),
      earlyPeriodPrompt: clearEarlyPeriodPrompt
          ? null
          : (earlyPeriodPrompt ?? this.earlyPeriodPrompt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEditState &&
          other.selectedDate == selectedDate &&
          other.pendingFlow == pendingFlow &&
          other.isSaving == isSaving &&
          other.isOffline == isOffline &&
          other.newPeriodPrompt == newPeriodPrompt &&
          other.earlyPeriodPrompt == earlyPeriodPrompt;

  @override
  int get hashCode => Object.hash(
        selectedDate, pendingFlow, isSaving, isOffline,
        newPeriodPrompt, earlyPeriodPrompt);
}

// ── Mini value objects for prompt data ────────────────────────────────────────

@immutable
class _NewPeriodPrompt {
  final String dateStr;     // "YYYY-MM-DD"
  final FlowLevel flow;
  const _NewPeriodPrompt({required this.dateStr, required this.flow});
}

@immutable
class _EarlyPeriodPrompt {
  final String dateStr;
  final int daysEarly;
  const _EarlyPeriodPrompt({required this.dateStr, required this.daysEarly});
}

// ─────────────────────────────────────────────────────────────────────────────
// CalendarEditNotifier
// ─────────────────────────────────────────────────────────────────────────────

/// ChangeNotifier that owns all "edit a log entry" side-effects:
///
/// * optimistic SQLite patch → API POST → invalidate caches
/// * offline queue via connectivity_plus listener
/// * new-period-start confirmation dialog gate
/// * early-period detection + messaging
/// * gamification point announcements
/// * SnackBar feedback (via [BuildContext] passed to [save])
class CalendarEditNotifier extends ChangeNotifier {
  final TrackerRepository _repo;

  // External data injected on each build — kept as refs, never owned
  List<CycleLogModel> _logs = [];
  List<CycleRecordModel> _cycles = [];
  Set<String> _predictionDates = {};

  /// Callback invoked after a confirmed save so [CalendarCubit] can reload.
  final Future<void> Function() onSaveComplete;

  CalendarEditNotifier({
    required TrackerRepository repository,
    required this.onSaveComplete,
  }) : _repo = repository {
    _subscribeToConnectivity();
  }

  // ── State ──────────────────────────────────────────────────────────────────

  CalendarEditState _state = const CalendarEditState();
  CalendarEditState get state => _state;

  void _emit(CalendarEditState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  // ── Connectivity ───────────────────────────────────────────────────────────

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  void _subscribeToConnectivity() {
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final online = !results.contains(ConnectivityResult.none);
    _emit(_state.copyWith(isOffline: !online));

    if (online) {
      final synced = await _repo.syncOfflineQueue();
      if (synced > 0) {
        debugPrint('[EditNotifier] ✅ Synced $synced offline log(s)');
        await onSaveComplete();
      }
    }
  }

  // ── Inject external data (call from CalendarScreen build) ──────────────────

  /// Update references used by new-period detection.
  /// Cheap — no rebuild triggered.
  void updateContext({
    required List<CycleLogModel> logs,
    required List<CycleRecordModel> cycles,
    required Set<String> predictionDates,
  }) {
    _logs = logs;
    _cycles = cycles;
    _predictionDates = predictionDates;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  void selectDate(String? dateStr) {
    _emit(_state.copyWith(
      selectedDate: dateStr,
      clearPendingFlow: true,
      clearNewPeriodPrompt: true,
      clearEarlyPeriodPrompt: true,
    ));
  }

  void setFlow(FlowLevel flow) {
    _emit(_state.copyWith(pendingFlow: flow));
  }

  /// Primary save entry-point.
  ///
  /// Runs pre-save checks (new period / early period), shows confirmation
  /// dialogs if needed, then delegates to [_doSave] on confirm.
  Future<void> save(BuildContext context) async {
    final dateStr = _state.selectedDate;
    final flow    = _state.pendingFlow;
    if (dateStr == null || flow == null) return;
    if (_state.isSaving) return;

    final date = DateTime.tryParse(dateStr);
    if (date == null) return;

    // ── Check: early period (future predicted day) ────────────────────────
    final isFuturePredicted = _predictionDates.contains(dateStr) &&
        date.isAfter(DateTime.now());
    if (isFuturePredicted && flow != FlowLevel.none && flow != FlowLevel.ended) {
      final predictedStart = _predictionDates.isEmpty
          ? null
          : _predictionDates
              .map((s) => DateTime.tryParse(s))
              .whereType<DateTime>()
              .reduce((a, b) => a.isBefore(b) ? a : b);
      final daysEarly = predictedStart != null
          ? predictedStart.difference(date).inDays.abs()
          : 0;
      _emit(_state.copyWith(
        earlyPeriodPrompt:
            _EarlyPeriodPrompt(dateStr: dateStr, daysEarly: daysEarly),
      ));
      // Show early period notification, then proceed
      await _showEarlyPeriodNotice(context, daysEarly);
      _emit(_state.copyWith(clearEarlyPeriodPrompt: true));
      // Fall through — proceed with save
    }

    // ── Check: new period start (no cycle within 35 days) ─────────────────
    if (flow != FlowLevel.none && flow != FlowLevel.ended) {
      if (_isNewPeriodStart(date)) {
        _emit(_state.copyWith(
          newPeriodPrompt:
              _NewPeriodPrompt(dateStr: dateStr, flow: flow),
        ));
        final confirmed = await _showNewPeriodDialog(context, dateStr);
        if (!confirmed) {
          // User cancelled — revert pendingFlow
          _emit(_state.copyWith(
            clearNewPeriodPrompt: true,
            clearPendingFlow: true,
          ));
          return;
        }
        _emit(_state.copyWith(clearNewPeriodPrompt: true));
      }
    }

    await _doSave(context, dateStr: dateStr, flow: flow);
  }

  /// Programmatic confirm (e.g., from dialog callback without context).
  Future<void> confirmNewPeriod(BuildContext context) async {
    final prompt = _state.newPeriodPrompt;
    if (prompt == null) return;
    _emit(_state.copyWith(clearNewPeriodPrompt: true));
    await _doSave(context, dateStr: prompt.dateStr, flow: prompt.flow);
  }

  void cancelNewPeriod() {
    _emit(_state.copyWith(
      clearNewPeriodPrompt: true,
      clearPendingFlow: true,
    ));
  }

  // ── Core save logic ────────────────────────────────────────────────────────

  Future<void> _doSave(
    BuildContext context, {
    required String dateStr,
    required FlowLevel flow,
  }) async {
    final date = DateTime.tryParse(dateStr)!;

    // ── 1. Build optimistic log ────────────────────────────────────────────
    final existingLog = _logForDate(date);
    final optimisticLog = CycleLogModel(
      id: existingLog?.id ?? 'optimistic_${dateStr.replaceAll('-', '')}',
      date: date,
      flow: flow.name,
      symptoms: existingLog?.symptoms ?? [],
      crampIntensity: existingLog?.crampIntensity,
      moodPrimary: existingLog?.moodPrimary,
      moodSecondary: existingLog?.moodSecondary ?? [],
      energyLevel: existingLog?.energyLevel,
      sleepHours: existingLog?.sleepHours,
      sleepQuality: existingLog?.sleepQuality,
      noteText: existingLog?.noteText,
      nutritionTags: existingLog?.nutritionTags ?? [],
      activityTags: existingLog?.activityTags ?? [],
      isRetroactive: date.isBefore(DateTime.now()),
    );

    final apiPayload = <String, dynamic>{
      'log_date': dateStr,
      'period_flow': flow.name,
    };

    _emit(_state.copyWith(isSaving: true));

    try {
      // ── 2. Optimistic SQLite patch + API call ──────────────────────────
      final response = await _repo.logDailyCached(
        optimisticLog: optimisticLog,
        apiPayload: apiPayload,
      );

      final predictionUpdated =
          response['prediction_updated'] as bool? ?? false;
      final cycleUpdated =
          response['cycle_updated'] as bool? ?? false;
      final pointsAwarded =
          (response['points_awarded'] as num?)?.toInt() ?? 0;

      // ── 3. Selective cache invalidation ───────────────────────────────
      if (predictionUpdated) {
        await _repo.invalidatePredictionCache();
      }
      if (cycleUpdated) {
        await _repo.invalidateCyclesCache();
      }

      // ── 4. Trigger UI refresh ──────────────────────────────────────────
      await onSaveComplete();

      // ── 5. Gamification SnackBar ───────────────────────────────────────
      _emit(_state.copyWith(
        isSaving: false,
        clearPendingFlow: true,
      ));

      if (context.mounted) {
        final isOffline = _state.isOffline || response.isEmpty;
        final message = isOffline
            ? '💾 Saved locally — will sync when connected'
            : pointsAwarded > 0
                ? '✅ Saved! +$pointsAwarded pts · Gigi is recalculating…'
                : '✅ Saved! Gigi is recalculating…';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(milliseconds: 2500),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            backgroundColor: isOffline
                ? const Color(0xFF475569)
                : const Color(0xFF7C3AED),
          ),
        );
      }
    } on Exception catch (e) {
      debugPrint('[EditNotifier] ❌ Save failed: $e');

      // ── 6. Rollback optimistic patch ──────────────────────────────────
      // Re-apply the original log (or remove the patch by restoring null)
      if (existingLog != null) {
        await _repo.logDailyCached(
          optimisticLog: existingLog,
          apiPayload: {}, // no-op API call; stays offline if needed
        );
      } else {
        // Remove optimistic entry by patching with a "none flow" marker
        await _repo.logDailyCached(
          optimisticLog: optimisticLog.copyWith(flow: 'none', id: ''),
          apiPayload: {},
        );
      }

      _emit(_state.copyWith(isSaving: false));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                '⚠️ Could not save — will retry when connected.'),
            duration: const Duration(milliseconds: 3000),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  // ── Detection helpers ──────────────────────────────────────────────────────

  /// True when [date] has active flow AND there is no cycle record with a
  /// period start within the last 35 days.
  bool _isNewPeriodStart(DateTime date) {
    const windowDays = 35;
    if (_cycles.isEmpty) return true;

    final hasRecentCycle = _cycles.any((c) {
      final diff = date.difference(c.periodStartDate).inDays;
      return diff >= 0 && diff < windowDays;
    });
    if (hasRecentCycle) return false;

    // Also check in-memory logs — if the previous 5 days already have flow,
    // this is a continuation, not a new start
    for (int i = 1; i <= 5; i++) {
      final prev = date.subtract(Duration(days: i));
      final prevLog = _logForDate(prev);
      if (prevLog != null &&
          prevLog.flow != null &&
          prevLog.flow != 'none' &&
          prevLog.flow != 'ended') {
        return false; // continuation
      }
    }

    return true;
  }

  CycleLogModel? _logForDate(DateTime date) {
    try {
      return _logs.firstWhere(
          (l) => DateUtils.isSameDay(l.date, date));
    } catch (_) {
      return null;
    }
  }

  // ── Dialog / notice helpers ────────────────────────────────────────────────

  /// Shows confirmation dialog: "Looks like your period started on [date] — is that right?"
  /// Returns `true` if the user confirmed.
  Future<bool> _showNewPeriodDialog(
    BuildContext context,
    String dateStr,
  ) async {
    if (!context.mounted) return false;

    final date = DateTime.tryParse(dateStr);
    final label = date != null
        ? DateFormat('EEEE, d MMMM').format(date)
        : dateStr;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('🩸 New Period?',
            textAlign: TextAlign.center),
        content: Text(
          'Looks like your period started on $label — is that right?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, log it!',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Shows a brief informational notice that the period started early.
  /// Resolves when the user dismisses.
  Future<void> _showEarlyPeriodNotice(
    BuildContext context,
    int daysEarly,
  ) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('⏰ Early Period!',
            textAlign: TextAlign.center),
        content: Text(
          'Your period started $daysEarly ${daysEarly == 1 ? 'day' : 'days'} early! '
          'Gigi will update your predictions right away.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it!',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
