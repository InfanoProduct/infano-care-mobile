import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/calendar_grid.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/period_editor_sheet.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  bool _showGigiMessage = false;
  bool _isEditMode = false;
  DateTime? _selectedStart;
  DateTime? _selectedEnd;

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
    return BlocBuilder<TrackerBloc, TrackerState>(
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(),
          body: state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            notStarted: () => const Center(child: Text('Please setup tracker first')),
            error: (msg) => Center(child: Text('Error: $msg')),
            loaded: (profile, prediction, logs, history, milestone) {
              return Column(
                children: [
                   if (_showGigiMessage) _buildGigiMessage(),
                  _buildMonthHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CalendarGrid(
                              month: _focusedMonth,
                              logs: logs,
                              profile: profile,
                              prediction: prediction,
                              isEditMode: _isEditMode,
                              selectedStart: _selectedStart,
                              selectedEnd: _selectedEnd,
                              onDayTap: (date) => _onDayTap(context, date),
                            ),
                            if (!_isEditMode) ...[
                              const SizedBox(height: 24),
                              _buildHistorySection(history),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_isEditMode ? 'Edit Period' : 'Cycle Calendar', 
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: true,
      leading: _isEditMode ? IconButton(
        icon: const Icon(Icons.close, color: AppColors.textMedium),
        onPressed: () => setState(() {
           _isEditMode = false;
           _selectedStart = null;
           _selectedEnd = null;
        }),
      ) : null,
      actions: [
        if (_isEditMode)
          TextButton(
            onPressed: (_selectedStart != null && _selectedEnd != null) ? _saveRange : null,
            child: Text('Save', style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800, 
              color: (_selectedStart != null && _selectedEnd != null) ? AppColors.purple : AppColors.textMedium.withOpacity(0.5)
            )),
          )
        else
          IconButton(
            icon: const Icon(Icons.edit_note, color: AppColors.purple),
            onPressed: () => setState(() => _isEditMode = true),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _saveRange() {
    if (_selectedStart != null && _selectedEnd != null) {
      context.read<TrackerBloc>().add(
        TrackerEvent.updatePeriodRange(_selectedStart!, _selectedEnd!)
      );
      setState(() {
        _isEditMode = false;
        _selectedStart = null;
        _selectedEnd = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Period range updated! ✨'), backgroundColor: AppColors.purple),
      );
    }
  }

  Widget _buildGigiMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('🌸', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gigi: \"Your cycle history is right here — every logged day tells your body\'s story. Tap any empty day to fill in what you remember 💜\"',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _showGigiMessage = false),
                  child: const Text('Got it!', style: TextStyle(color: AppColors.purple)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.purple),
            onPressed: () => setState(() {
              _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
            }),
          ),
          Text(
            '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.textDark,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.purple),
            onPressed: () => setState(() {
              _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
            }),
          ),
        ],
      ),
    );
  }

  void _onDayTap(BuildContext context, DateTime date) {
    if (_isEditMode) {
      setState(() {
        if (_selectedStart == null || (_selectedStart != null && _selectedEnd != null)) {
          _selectedStart = date;
          _selectedEnd = null;
        } else {
          if (date.isBefore(_selectedStart!)) {
            _selectedEnd = _selectedStart;
            _selectedStart = date;
          } else {
            _selectedEnd = date;
          }
        }
      });
      return;
    }

    // Retroactive logging check (up to 6 days back)
    final now = DateTime.now();
    if (date.isAfter(now)) {
      // Future day, cannot log
      return;
    }

    _showLogSheet(context, date);
  }

  Widget _buildHistorySection(List<CycleRecordModel> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Cycle History',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textDark),
          ),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text('No history yet. Start logging to see your cycle trends 🌸', 
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(color: AppColors.textMedium)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final record = history[index];
              final startStr = DateFormat('MMM d').format(record.periodStartDate);
              final endStr = record.periodEndDate != null ? DateFormat('MMM d').format(record.periodEndDate!) : '?';
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _isEditMode = true;
                    _selectedStart = record.periodStartDate;
                    _selectedEnd = record.periodEndDate;
                    _focusedMonth = record.periodStartDate;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.purple.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.pink.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Text('🩸', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$startStr - $endStr',
                              style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.textDark),
                            ),
                            Text(
                              '${record.periodDurationDays ?? 5} days period',
                              style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_outlined, color: AppColors.purple, size: 20),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showLogSheet(BuildContext context, DateTime date) {
    final state = context.read<TrackerBloc>().state;
    state.maybeWhen(
      loaded: (profile, _, logs, ____, ___) {
        // Find existing log for this date if any
        final log = logs.firstWhere(
           (l) => DateUtils.isSameDay(l.date, date),
           orElse: () => CycleLogModel(id: '', date: date),
        );

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BlocProvider.value(
            value: context.read<TrackerBloc>(),
            child: PeriodEditorSheet(
              date: date,
              profile: profile,
              initialLog: log.id.isNotEmpty ? log : null,
            ),
          ),
        );
      },
      orElse: () {},
    );
  }
}
