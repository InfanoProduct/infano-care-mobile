import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/daily_log_sheet.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';

class TrackerCalendar extends StatefulWidget {
  final List<CycleLogModel> logs;
  final PredictionResultModel? prediction;

  const TrackerCalendar({super.key, required this.logs, this.prediction});

  @override
  State<TrackerCalendar> createState() => _TrackerCalendarState();
}

class _TrackerCalendarState extends State<TrackerCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _showLogScreen(selectedDay);
          },
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: AppColors.purple.withOpacity(0.1), shape: BoxShape.circle),
            todayTextStyle: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold),
            selectedDecoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle),
            markerDecoration: const BoxDecoration(color: AppColors.pink, shape: BoxShape.circle),
            outsideDaysVisible: false,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 18),
            leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.purple),
            rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.purple),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              final log = _getLogForDate(date);
              if (log == null && !_isPredictedPeriod(date)) return const SizedBox();

              return Positioned(
                bottom: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (log?.flow != null && log!.flow != 'none')
                      _buildMarker(AppColors.pink),
                    if (_isPredictedPeriod(date))
                      _buildMarker(AppColors.purple.withOpacity(0.3)),
                    if (log?.mood != null)
                      const Text('•', style: TextStyle(color: Colors.blue, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildLegend(),
      ],
    );
  }

  Widget _buildMarker(Color color) {
    return Container(
      width: 6, height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _legendItem('Period', AppColors.pink),
          _legendItem('Predicted', AppColors.purple.withOpacity(0.3)),
          _legendItem('Logged', Colors.blue),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMedium)),
      ],
    );
  }

  CycleLogModel? _getLogForDate(DateTime date) {
    try {
      return widget.logs.firstWhere((l) => isSameDay(l.date, date));
    } catch (_) {
      return null;
    }
  }

  bool _isPredictedPeriod(DateTime date) {
    if (widget.prediction == null) return false;
    final start = widget.prediction!.windowEarly;
    final end = widget.prediction!.windowLate.add(const Duration(days: 4)); // Assume 5 day period
    return date.isAfter(start.subtract(const Duration(days: 1))) && date.isBefore(end);
  }

  void _showLogScreen(DateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<TrackerBloc>(),
          child: DailyLogScreen(date: date),
        ),
      ),
    );
  }
}
