import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:intl/intl.dart';

class PeriodEditorSheet extends StatefulWidget {
  final DateTime date;
  final CycleProfileModel profile;
  final CycleLogModel? initialLog;

  const PeriodEditorSheet({
    super.key,
    required this.date,
    required this.profile,
    this.initialLog,
  });

  @override
  State<PeriodEditorSheet> createState() => _PeriodEditorSheetState();
}

class _PeriodEditorSheetState extends State<PeriodEditorSheet> {
  late bool _isPeriodDay;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final flow = widget.initialLog?.flow;
    _isPeriodDay = flow != null && flow != 'none' && flow != 'ended';
  }

  Future<void> _togglePeriodDay(bool value) async {
    setState(() => _isSaving = true);
    
    // We use logDaily with a default 'medium' flow when toggled ON, and 'none' when toggled OFF.
    final data = {
      'date': DateTime(widget.date.year, widget.date.month, widget.date.day, 12).toUtc().toIso8601String(),
      'flow': value ? 'medium' : 'none',
    };

    context.read<TrackerBloc>().add(TrackerEvent.logDaily(data));
    
    setState(() {
      _isPeriodDay = value;
      _isSaving = false;
    });
  }

  Future<void> _setAsPeriodStart() async {
    setState(() => _isSaving = true);
    
    // Update the profile's lastPeriodStart. This triggers a full prediction re-calculation.
    final data = {
      'lastPeriodStart': widget.date.toIso8601String(),
      'cycleLengthDays': widget.profile.avgCycleLength,
      'periodLengthDays': widget.profile.avgPeriodDuration,
      'trackerMode': widget.profile.trackerMode,
    };

    context.read<TrackerBloc>().add(TrackerEvent.setup(data));
    
    // Also mark this day as a period day if it wasn't already.
    if (!_isPeriodDay) {
       final logData = {
        'date': DateTime(widget.date.year, widget.date.month, widget.date.day, 12).toUtc().toIso8601String(),
        'flow': 'medium',
      };
      context.read<TrackerBloc>().add(TrackerEvent.logDaily(logData));
    }

    setState(() => _isSaving = false);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cycle updated! Starting from ${DateFormat('MMM d').format(widget.date)} 🌸'),
        backgroundColor: AppColors.purple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMMM d').format(widget.date);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(32), right: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Text(
            'Edit Cycle',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            dateStr,
            style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 15),
          ),
          const SizedBox(height: 32),
          
          _buildActionTile(
            title: 'Is this a period day?',
            trailing: Switch.adaptive(
              value: _isPeriodDay,
              activeColor: AppColors.pink,
              onChanged: _isSaving ? null : _togglePeriodDay,
            ),
          ),
          
          const Divider(height: 32),
          
          _buildActionTile(
            title: 'Mark as Period Start',
            subtitle: 'This will update your predictions based on this date.',
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_filled_rounded, color: AppColors.purple, size: 32),
              onPressed: _isSaving ? null : _setAsPeriodStart,
            ),
          ),

          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Done 🌸', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionTile({required String title, String? subtitle, required Widget trailing}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 16)),
              if (subtitle != null)
                Text(subtitle, style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 12)),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
