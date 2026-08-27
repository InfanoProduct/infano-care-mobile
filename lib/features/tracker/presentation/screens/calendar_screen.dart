import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/bloc/calendar_cubit.dart';
import 'package:infano_care_mobile/features/tracker/bloc/calendar_edit_notifier.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/calendar_grid.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/day_detail_panel.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/phase_legend_strip.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/period_history_list.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/prediction_window_card.dart';
import 'package:infano_care_mobile/features/tracker/utils/calendar_types.dart';
import 'package:infano_care_mobile/features/tracker/utils/calendar_utils.dart';
import 'package:infano_care_mobile/features/tracker/utils/prediction_windows_provider.dart';
import 'package:infano_care_mobile/features/tracker/utils/prediction_windows_computer.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TrackerBloc, TrackerState>(
      listener: (context, trackerState) {
        trackerState.maybeWhen(
          loaded: (profile, prediction, logs, history, dailyInsights, recommendedArticles, milestone, pointsEarned, isRefreshing) {
            context.read<CalendarCubit>().loadCalendarData(forceRefresh: true);
          },
          orElse: () {},
        );
      },
      child: BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        return state.when(
          initial: () => const _LoadingView(),
          loading: () => const _LoadingView(),
          error: (msg) => _ErrorView(message: msg),
          loaded: (
            year,
            month,
            profile,
            prediction,
            logs,
            cycles,
            phaseMap,
            predictionDates,
            fertilityDates,
            predictedCycles,
            existingPeriodDates,
            selectedDate,
            isEditMode,
            editStartDate,
            editEndDate,
            isSavingRange,
            isRefreshing,
            isOffline,
          ) =>
              _LoadedView(
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
            existingPeriodDates: existingPeriodDates,
            selectedDate: selectedDate,
            isEditMode: isEditMode,
            editStartDate: editStartDate,
            editEndDate: editEndDate,
            isSavingRange: isSavingRange,
            onSwipe: (v) => context.read<CalendarCubit>().changeMonth(v > 0 ? -1 : 1),
          ),
        );
      },
    ),
  );
}
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator(color: AppColors.purple)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('❌', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 16),
            Text(message, style: GoogleFonts.nunito(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<CalendarCubit>().loadCalendarData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

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
  final Set<String> existingPeriodDates;
  final String? selectedDate;
  final bool isEditMode;
  final DateTime? editStartDate;
  final DateTime? editEndDate;
  final bool isSavingRange;
  final Function(double) onSwipe;

  const _LoadedView({
    required this.viewYear,
    required this.viewMonth,
    required this.profile,
    this.prediction,
    required this.logs,
    required this.cycles,
    required this.phaseMap,
    required this.predictionDates,
    required this.fertilityDates,
    required this.predictedCycles,
    required this.existingPeriodDates,
    this.selectedDate,
    required this.isEditMode,
    this.editStartDate,
    this.editEndDate,
    required this.isSavingRange,
    required this.onSwipe,
  });

  @override
  State<_LoadedView> createState() => _LoadedViewState();
}

class _LoadedViewState extends State<_LoadedView> {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CalendarCubit>();
    final viewMonth_ = DateTime(widget.viewYear, widget.viewMonth);
    final monthStr = DateFormat('MMMM yyyy').format(viewMonth_);

    final selDate = widget.selectedDate != null
        ? DateTime.tryParse(widget.selectedDate!)
        : null;
    
    // Find log or use placeholder
    CycleLogModel selLog;
    try {
      selLog = widget.logs.firstWhere(
        (l) => widget.selectedDate != null && l.date.toIso8601String().startsWith(widget.selectedDate!),
      );
    } catch (_) {
      selLog = CycleLogModel(
        id: '',
        date: selDate ?? DateTime.now(),
        flow: 'none',
      );
    }

    final isFuture = selDate != null && selDate.isAfter(DateTime.now());
    final isPredDay = widget.predictionDates.contains(widget.selectedDate);
    final cyclePhase = widget.phaseMap[widget.selectedDate];
    final phaseInfo = cyclePhase != null 
        ? PhaseInfo(phase: _toPhaseType(cyclePhase), isPredicted: isPredDay)
        : null;

    final hasMeaningfulLog = selLog.id.isNotEmpty && (
      (selLog.flow != null && selLog.flow != 'none') ||
      selLog.symptoms.isNotEmpty ||
      (selLog.noteText != null && selLog.noteText!.trim().isNotEmpty) ||
      selLog.moodPrimary != null ||
      selLog.moodSecondary.isNotEmpty ||
      selLog.activityTags.isNotEmpty ||
      selLog.nutritionTags.isNotEmpty
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: ChangeNotifierProvider<CalendarEditNotifier>(
        create: (ctx) => CalendarEditNotifier(
          repository: ctx.read<TrackerRepository>(),
          onSaveComplete: () async => cubit.refreshAfterLog(),
        ),
        child: Consumer<CalendarEditNotifier>(
          builder: (context, notifier, _) {
            // Update notifier with latest logs/cycles from state
            notifier.updateContext(
              logs: widget.logs,
              cycles: widget.cycles,
              predictionDates: widget.predictionDates,
            );
            
            final editState = notifier.state;

            return Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          monthStr,
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                        Row(
                          children: [
                            _HeaderCircleBtn(
                              icon: Icons.chevron_left_rounded,
                              onTap: () => cubit.changeMonth(-1),
                            ),
                            const SizedBox(width: 12),
                            _HeaderCircleBtn(
                              icon: Icons.chevron_right_rounded,
                              onTap: () => cubit.changeMonth(1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  PhaseLegendStrip(),
                  const SizedBox(height: 8),

                  // Calendar + Details in a scrollable area
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => cubit.loadCalendarData(forceRefresh: true),
                      color: AppColors.purple,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          child: Column(
                            children: [
                              if (widget.isEditMode) _buildEditControls(context, cubit),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onHorizontalDragEnd: (details) {
                                  final v = details.primaryVelocity ?? 0;
                                  if (v.abs() > 200) widget.onSwipe(v);
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 350),
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  child: CalendarGrid(
                                    key: ValueKey('${widget.viewYear}-${widget.viewMonth}-${widget.isEditMode}-${widget.isSavingRange}-${widget.logs.length}'),
                                    month: viewMonth_,
                                    logs: widget.logs,
                                    phaseMap: widget.phaseMap,
                                    predictionDates: widget.predictionDates,
                                    existingPeriodDates: widget.existingPeriodDates,
                                    fertilityDates: widget.fertilityDates,
                                    predictedCycles: widget.predictedCycles,
                                    selectedDate: widget.selectedDate,
                                    isEditMode: widget.isEditMode,
                                    editStartDate: widget.editStartDate,
                                    editEndDate: widget.editEndDate,
                                    onDayTap: (date) {
                                      final key = PredictionWindowsComputer.toKey(date);
                                      cubit.selectDate(key);
                                      notifier.selectDate(key);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (!widget.isEditMode) _buildEditControls(context, cubit),
                              const SizedBox(height: 16),
                              
                              // Day Detail Panel
                              AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, anim) => SizeTransition(
                                    sizeFactor: CurvedAnimation(
                                      parent: anim,
                                      curve: Curves.easeInOutCubic,
                                    ),
                                    child: FadeTransition(opacity: anim, child: child),
                                  ),
                                  child: (widget.selectedDate != null && 
                                          ((phaseInfo != null && phaseInfo.phase != PhaseType.unknown) || hasMeaningfulLog))
                                      ? DayDetailPanel(
                                          key: ValueKey(widget.selectedDate),
                                          selectedDate: widget.selectedDate,
                                          phaseInfo: phaseInfo,
                                          log: selLog.id.isEmpty ? null : selLog,
                                          isFutureDay: isFuture,
                                          isPredictedPeriodDay: isPredDay,
                                          onFlowChange: (f) => notifier.setFlow(f),
                                          onSave: () => notifier.save(context),
                                          isSaving: editState.isSaving,
                                          isEditMode: widget.isEditMode,
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              
                              const SizedBox(height: 24),
                              
                              PredictionWindowCard(
                                profile: widget.profile,
                                prediction: widget.prediction,
                              ),

                              const SizedBox(height: 24),

                              // History List
                              PeriodHistoryList(
                                cycles: widget.cycles,
                                profile: widget.profile,
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
                              
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isSavingRange)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.8),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                color: AppColors.purple,
                                strokeWidth: 3.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Saving Period Range...',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
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
              fontSize: 14,
              color: AppColors.purple,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            backgroundColor: AppColors.purple.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    final hasRange = widget.editStartDate != null && widget.editEndDate != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF), // Soft Lavender Pastel
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE9FE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Edit Period Range',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: const Color(0xFF5B21B6), // Deep rich purple
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasRange 
                ? '${DateFormat('MMM d').format(widget.editStartDate!)} – ${DateFormat('MMM d').format(widget.editEndDate!)}'
                : 'Select start & end dates on the calendar',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7C3AED), // Primary purple
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => cubit.toggleEditMode(),
                  child: Text(
                    'Cancel', 
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold, 
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: hasRange && !widget.isSavingRange 
                      ? () => cubit.confirmEditRange()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.purple.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: widget.isSavingRange 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Save Range',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static PhaseType _toPhaseType(CyclePhase p) {
    switch (p) {
      case CyclePhase.menstrual:  return PhaseType.menstrual;
      case CyclePhase.follicular: return PhaseType.follicular;
      case CyclePhase.fertile:    return PhaseType.fertile;
      case CyclePhase.ovulation:  return PhaseType.ovulation;
      case CyclePhase.luteal:     return PhaseType.luteal;
      case CyclePhase.unknown:    return PhaseType.unknown;
    }
  }
}

class _HeaderCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderCircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Icon(icon, size: 20, color: AppColors.textDark),
      ),
    );
  }
}
