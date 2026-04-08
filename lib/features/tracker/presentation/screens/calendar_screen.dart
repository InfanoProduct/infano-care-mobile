import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/bloc/calendar_cubit.dart';
import 'package:infano_care_mobile/features/tracker/bloc/calendar_edit_notifier.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/calendar_grid.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/calendar_header.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/day_detail_panel.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/period_editor_sheet.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/period_history_list.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/phase_legend_strip.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/prediction_banner.dart';
import 'package:infano_care_mobile/features/tracker/utils/calendar_types.dart';
import 'package:infano_care_mobile/features/tracker/utils/calendar_utils.dart';
import 'package:infano_care_mobile/features/tracker/utils/prediction_windows_computer.dart';
import 'package:infano_care_mobile/features/tracker/utils/prediction_windows_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TrackerRepository>();
    return BlocProvider(
      create: (ctx) {
        final cubit = CalendarCubit(repo)..loadCalendarData();
        // CalendarEditNotifier is created AFTER CalendarCubit so it can call
        // cubit.refreshAfterLog() via the closure below.
        return cubit;
      },
      child: Builder(builder: (ctx) {
        return ChangeNotifierProvider(
          create: (_) => CalendarEditNotifier(
            repository: repo,
            onSaveComplete: ctx.read<CalendarCubit>().refreshAfterLog,
          ),
          child: const _CalendarScreenBody(),
        );
      }),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _CalendarScreenBody extends StatefulWidget {
  const _CalendarScreenBody();

  @override
  State<_CalendarScreenBody> createState() => _CalendarScreenBodyState();
}

class _CalendarScreenBodyState extends State<_CalendarScreenBody> {
  bool _showGigiMessage = false;

  // Swipe tracking
  static const _swipeThreshold = 300.0;

  @override
  void initState() {
    super.initState();
    _checkFirstVisit();
  }

  void _checkFirstVisit() async {
    final storage = context.read<LocalStorageService>();
    if (!storage.hasCalendarVisited) {
      setState(() => _showGigiMessage = true);
      await storage.setCalendarVisited(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(state),
          body: state.when(
            initial: () => _loadingView(),
            loading: () => _loadingView(),
            error: (msg) => _errorView(msg),
            loaded: (
              viewYear,
              viewMonth,
              profile,
              prediction,
              logs,
              cycles,
              phaseMap,
              predictionDates,
              fertilityDates,
              predictedCycles,
              selectedDate,
              isEditMode,
              editStartDate,
              editEndDate,
              isSavingRange,
              isRefreshing,
              isOffline,
            ) {
              return _LoadedView(
                viewYear: viewYear,
                viewMonth: viewMonth,
                profile: profile,
                prediction: prediction,
                logs: logs,
                cycles: cycles,
                phaseMap: phaseMap,
                predictionDates: predictionDates,
                fertilityDates: fertilityDates,
                predictedCycles: predictedCycles,
                selectedDate: selectedDate,
                isEditMode: isEditMode,
                editStartDate: editStartDate,
                editEndDate: editEndDate,
                isSavingRange: isSavingRange,
                isRefreshing: isRefreshing,
                isOffline: isOffline,
                showGigiMessage: _showGigiMessage,
                onDismissGigi: () => setState(() => _showGigiMessage = false),
                onSwipe: _handleSwipe,
              );
            },
          ),
        );
      },
    );
  }

  void _handleSwipe(double velocity) {
    final cubit = context.read<CalendarCubit>();
    if (velocity < -_swipeThreshold) cubit.changeMonth(1);    // swipe left → next
    if (velocity > _swipeThreshold) cubit.changeMonth(-1);    // swipe right → prev
  }

  PreferredSizeWidget _buildAppBar(CalendarState state) {
    final isOffline = state.maybeWhen(
      loaded: (
        _,
        __,
        ___,
        ____,
        _____,
        ______,
        _______,
        ________,
        _________,
        __________,
        ___________,
        isEditMode,
        editStartDate,
        editEndDate,
        isSavingRange,
        isRefreshing,
        isOffline,
      ) =>
          isOffline,
      orElse: () => false,
    );
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cycle Calendar',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
          ),
          if (isOffline) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.bloom.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.bloom.withOpacity(0.3)),
              ),
              child: Text(
                'Offline',
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bloom,
                ),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: true,
    );
  }

  Widget _loadingView() => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.purple),
          strokeWidth: 2,
        ),
      );

  Widget _errorView(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(color: AppColors.textMedium)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    context.read<CalendarCubit>().loadCalendarData(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}

// ── Loaded view ───────────────────────────────────────────────────────────────

class _LoadedView extends StatefulWidget {
  final int viewYear;
  final int viewMonth;
  final CycleProfileModel profile;
  final PredictionResultModel? prediction;
  final List<CycleLogModel> logs;
  final List<CycleRecordModel> cycles;
  final Map<String, CyclePhase> phaseMap;
  final Set<String> predictionDates;
  final Set<String> fertilityDates;
  final List<PredictedCycle> predictedCycles;
  final String? selectedDate;
  final bool isEditMode;
  final DateTime? editStartDate;
  final DateTime? editEndDate;
  final bool isSavingRange;
  final bool isRefreshing;
  final bool isOffline;
  final bool showGigiMessage;
  final VoidCallback onDismissGigi;
  final void Function(double velocity) onSwipe;

  const _LoadedView({
    required this.viewYear,
    required this.viewMonth,
    required this.profile,
    required this.prediction,
    required this.logs,
    required this.cycles,
    required this.phaseMap,
    required this.predictionDates,
    required this.fertilityDates,
    required this.predictedCycles,
    required this.selectedDate,
    required this.isEditMode,
    this.editStartDate,
    this.editEndDate,
    required this.isSavingRange,
    required this.isRefreshing,
    required this.isOffline,
    required this.showGigiMessage,
    required this.onDismissGigi,
    required this.onSwipe,
  });

  @override
  State<_LoadedView> createState() => _LoadedViewState();
}

class _LoadedViewState extends State<_LoadedView> {
  @override
  Widget build(BuildContext context) {
    final cubit    = context.read<CalendarCubit>();
    final notifier = context.read<CalendarEditNotifier>();
    final editState = context.watch<CalendarEditNotifier>().state;

    // Keep notifier aware of latest data for detection logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        notifier.updateContext(
          logs: widget.logs,
          cycles: widget.cycles,
          predictionDates: widget.predictionDates,
        );
      }
    });

    // Sync selectedDate into notifier when cubit changes it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.selectedDate != editState.selectedDate) {
        notifier.selectDate(widget.selectedDate);
      }
    });

    final viewMonth_ = DateTime(widget.viewYear, widget.viewMonth);
    final monthName = DateFormat('MMMM').format(viewMonth_);

    final a11yLabel =
        'Period calendar. Viewing $monthName ${widget.viewYear}. '
        '${widget.prediction != null ? '${widget.prediction!.daysUntilPrediction} days until next predicted period. '
            'Current phase: ${widget.prediction!.currentPhase}.' : 'No prediction available.'}';

    // ── Selected day derived values ─────────────────────────────────────────
    final selLog    = widget.logs.where((l) {
      final sel = widget.selectedDate;
      if (sel == null) return false;
      final parsed = DateTime.tryParse(sel);
      if (parsed == null) return false;
      return DateUtils.isSameDay(l.date, parsed);
    }).firstOrNull;
    final selPhase  = widget.phaseMap[widget.selectedDate] ?? CyclePhase.unknown;
    final selDate   = widget.selectedDate != null
        ? DateTime.tryParse(widget.selectedDate!)
        : null;
    final isFuture  = selDate != null && selDate.isAfter(DateTime.now());
    final isPredDay = widget.selectedDate != null &&
        widget.predictionDates.contains(widget.selectedDate);

    // PhaseType bridge
    PhaseType toPhaseType(CyclePhase p) {
      switch (p) {
        case CyclePhase.menstrual:  return PhaseType.menstrual;
        case CyclePhase.follicular: return PhaseType.follicular;
        case CyclePhase.fertile:    return PhaseType.fertile;
        case CyclePhase.ovulation:  return PhaseType.ovulation;
        case CyclePhase.luteal:     return PhaseType.luteal;
        case CyclePhase.unknown:    return PhaseType.unknown;
      }
    }

    final dynamicOpacity = selDate != null
        ? PredictionWindowsProvider.opacityForDate(selDate, widget.predictedCycles) ?? 0.55
        : 0.55;

    final phaseInfo = widget.selectedDate != null
        ? PhaseInfo(
            phase: toPhaseType(selPhase),
            isPredicted: isPredDay,
            opacity: isPredDay ? dynamicOpacity : 1.0,
          )
        : null;

    final existingFlow = selLog != null && selLog.id.isNotEmpty
        ? flowLevelFromString(selLog.flow)
        : null;

    final effectiveFlow = editState.pendingFlow ?? existingFlow;

    return Column(
      children: [
        Semantics(
          label: a11yLabel,
          child: const SizedBox.shrink(),
        ),
        if (widget.showGigiMessage)
          _GigiMessage(onDismiss: widget.onDismissGigi),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: CalendarHeader(
            year: widget.viewYear,
            month: widget.viewMonth,
            isRefreshing: widget.isRefreshing,
            onPrevMonth: () => cubit.changeMonth(-1),
            onNextMonth: () => cubit.changeMonth(1),
          ),
        ),
        const PhaseLegendStrip(),
        const SizedBox(height: 8),
        if (PredictionBanner.shouldShow(widget.prediction))
          PredictionBanner(prediction: widget.prediction!),
        
        Expanded(
          child: SingleChildScrollView(
            key: const PageStorageKey('calendar_scroll'),
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              child: Column(
                children: [
                  GestureDetector(
                    onHorizontalDragEnd: (details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v.abs() > 200) widget.onSwipe(v);
                    },
                    child: CalendarGrid(
                      month: viewMonth_,
                      logs: widget.logs,
                      phaseMap: widget.phaseMap,
                      predictionDates: widget.predictionDates,
                      fertilityDates: widget.fertilityDates,
                      predictedCycles: widget.predictedCycles,
                      selectedDate: widget.selectedDate,
                      isEditMode: widget.isEditMode,
                      editStartDate: widget.editStartDate,
                      editEndDate: widget.editEndDate,
                      onDayTap: (date) {
                        final key = PredictionWindowsComputer.toKey(date);
                        cubit.selectDate(key);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildEditControls(context, cubit),
                  const SizedBox(height: 16),
                  if (!widget.isEditMode)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => SizeTransition(
                        sizeFactor: CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeInOutCubic,
                        ),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: widget.selectedDate != null
                          ? DayDetailPanel(
                              key: ValueKey(widget.selectedDate),
                              selectedDate: widget.selectedDate,
                              phaseInfo: phaseInfo,
                              existingFlow: effectiveFlow,
                              isFutureDay: isFuture,
                              isPredictedPeriodDay: isPredDay,
                              onFlowChange: notifier.setFlow,
                              onSave: () => notifier.save(context),
                              isSaving: editState.isSaving,
                            )
                          : const SizedBox.shrink(),
                    ),
                  const SizedBox(height: 24),
                  PeriodHistoryList(
                    cycles: widget.cycles,
                    onCycleSelected: (startDateStr) {
                      final date = DateTime.tryParse(startDateStr);
                      if (date != null) {
                        cubit.jumpToMonth(
                          date.year,
                          date.month,
                          selectedDate: startDateStr,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditControls(BuildContext context, CalendarCubit cubit) {
    if (!widget.isEditMode) {
      return Center(
        child: TextButton.icon(
          onPressed: () => cubit.toggleEditMode(),
          icon: const Icon(Icons.edit_calendar_rounded, size: 18),
          label: Text(
            'Edit Cycle',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.purple,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: AppColors.purple.withOpacity(0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    final hasRange = widget.editStartDate != null && widget.editEndDate != null;

    return Column(
      children: [
        if (!hasRange)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Tap a date to set cycle start',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.textMedium,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (!hasRange || widget.isSavingRange) ? null : () => _handleSaveRange(context, cubit),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: widget.isSavingRange
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : Text(
                        'Update Cycle',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.isSavingRange ? null : () => cubit.toggleEditMode(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMedium,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleSaveRange(BuildContext context, CalendarCubit cubit) async {
    try {
      await cubit.confirmEditRange();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cycle updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onEditRecord(
    BuildContext context,
    CycleRecordModel record,
    CycleProfileModel profile,
    List<CycleLogModel> logs,
  ) {
    final cubit = context.read<CalendarCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: PeriodEditorSheet(
          date: record.periodStartDate,
          profile: profile,
          initialLog: null,
        ),
      ),
    ).then((_) => cubit.refreshAfterLog());
  }
}

// ── Gigi onboarding message ───────────────────────────────────────────────────

class _GigiMessage extends StatelessWidget {
  final VoidCallback onDismiss;
  const _GigiMessage({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌸', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gigi: "Your cycle history is right here — every logged day tells your body\'s story. Tap any day to explore! 💜"',
                  style: GoogleFonts.nunito(
                      fontSize: 13, color: AppColors.textDark, height: 1.5),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onDismiss,
                  child: Text(
                    'Got it!',
                    style: GoogleFonts.nunito(
                      color: AppColors.purple,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
