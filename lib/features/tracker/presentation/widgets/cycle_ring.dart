import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'cycle_ring_painter.dart';

class CycleRing extends StatefulWidget {
  final CycleProfileModel profile;
  final PredictionResultModel? prediction;
  final List<CycleRecordModel> history;
  final VoidCallback? onCenterTap;
  final Function(String)? onSegmentTap;

  const CycleRing({
    super.key,
    required this.profile,
    this.prediction,
    this.history = const [],
    this.onCenterTap,
    this.onSegmentTap,
  });

  @override
  State<CycleRing> createState() => _CycleRingState();
}

class _CycleRingState extends State<CycleRing> with TickerProviderStateMixin {
  int _viewingCycleIndex = 0; // 0 is current, 1+ is history
  double? _selectedDaySmooth; // Double for smooth animation
  bool _isDragging = false;
  late AnimationController _fadeController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _selectedDaySmooth = widget.profile.currentCycleDay?.toDouble();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _handleSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;
    
    // Only allow swiping if we aren't currently "dragging" the day indicator
    // Or if the velocity is high enough to indicate a clear swipe intent
    if (details.primaryVelocity!.abs() < 800) return;

    if (details.primaryVelocity! < -800) {
      // Swipe Left -> Next (Return to current if possible)
      if (_viewingCycleIndex > 0) {
        setState(() {
          _viewingCycleIndex--;
          _selectedDaySmooth = widget.profile.currentCycleDay?.toDouble();
          _isDragging = false;
        });
        _fadeController.forward(from: 0.0);
      }
    } else if (details.primaryVelocity! > 800) {
      // Swipe Right -> Past
      if (_viewingCycleIndex < widget.history.length) {
        setState(() => _viewingCycleIndex++);
        _fadeController.forward(from: 0.0);
      }
    }
  }

  void _handleTap(TapUpDetails details, BoxConstraints constraints) {
    final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
    final tapPos = details.localPosition;
    final distance = (tapPos - center).distance;
    final size = constraints.maxWidth;
    
    final innerR = size * 0.36;
    final outerR = size * 0.46;

    // 1. Center Disc Tap
    if (distance < innerR) {
       _openDailyLog();
       return;
    }

    // 2. Ring Segment Tap
    if (distance >= innerR && distance <= outerR) {
      final dx = tapPos.dx - center.dx;
      final dy = tapPos.dy - center.dy;
      double angle = atan2(dy, dx);
      
      // Convert to 0..2PI range starting from 12 o'clock (-PI/2)
      angle = (angle + pi / 2) % (2 * pi);
      final percent = angle / (2 * pi);
      
      _onSegmentTapped(percent);
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_viewingCycleIndex > 0) return; // Disable dragging in history mode

    final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
    final touchPos = details.localPosition;
    final dx = touchPos.dx - center.dx;
    final dy = touchPos.dy - center.dy;
    
    double angle = atan2(dy, dx);
    // Convert to 0..2PI range starting from 12 o'clock (-PI/2)
    angle = (angle + pi / 2) % (2 * pi);
    
    final avgLength = widget.profile.avgCycleLength;
    final percent = angle / (2 * pi);
    final day = (percent * avgLength) + 1; // Keep as double for smoothness
    
    final clampedDay = day.clamp(1.0, avgLength.toDouble());
    if (clampedDay != _selectedDaySmooth) {
      setState(() {
        _selectedDaySmooth = clampedDay;
        _isDragging = true;
      });
    }
  }

  void _handlePanEnd() {
    setState(() => _isDragging = false);
  }

  void _openDailyLog() {
    widget.onCenterTap?.call();
  }

  void _onSegmentTapped(double percent) {
    final phases = _getPhasesForCurrentMode();
    for (var phase in phases) {
      if (percent >= phase.startPercent && percent <= phase.endPercent) {
        widget.onSegmentTap?.call(phase.id);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = constraints.maxWidth;
        
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _handleTap(details, constraints),
          onPanStart: (details) => _handlePanUpdate(DragUpdateDetails(
            globalPosition: details.globalPosition,
            localPosition: details.localPosition,
          ), constraints),
          onPanUpdate: (details) => _handlePanUpdate(details, constraints),
          onPanEnd: (details) {
            _handleSwipe(details);
            _handlePanEnd();
          },
          child: FadeTransition(
            opacity: _fadeController,
            child: _getPainterWidget(size),
          ),
        );
      }
    );
  }

  Widget _getPainterWidget(double size) {
    final phases = _getPhasesForCurrentMode();
    final bool isHistory = _viewingCycleIndex > 0;
    
    if (isHistory) {
      final record = widget.history[_viewingCycleIndex - 1];
      return CustomPaint(
        size: Size(size, size),
        painter: CycleRingPainter(
          phases: phases,
          trackerMode: 'active',
          totalCycleDays: record.cycleLengthDays ?? 28,
          confidenceLevel: 'high',
          currentProgress: 1.0,
          phaseEmoji: '📊',
          phaseName: 'Past Cycle ${record.cycleNumber}',
          historicalSegments: [0.0, (record.periodDurationDays ?? 5) / (record.cycleLengthDays ?? 28)],
        ),
      );
    }

    final currentDay = widget.profile.currentCycleDay;
    final avgLength = widget.profile.avgCycleLength;
    final displayDay = _selectedDaySmooth?.round() ?? currentDay ?? 1;
    
    // Calculate absolute date
    final lastStart = widget.profile.lastPeriodStart ?? DateTime.now();
    final absoluteDate = lastStart.add(Duration(days: displayDay - 1));
    final formattedDate = DateFormat('d MMMM').format(absoluteDate);

    // Calculate day within phase
    final dayInPhase = _calculateDayInPhase(displayDay, avgLength);
    
    // Dynamic data for selected day
    final selectedPhase = _calculatePhase(displayDay, avgLength);
    final nextPhaseInfo = _calculateNextPhase(displayDay, avgLength);
    
    // Get color for the inner background based on selected phase
    final phaseColor = phases.firstWhere((p) => p.id == selectedPhase, orElse: () => phases.first).gradient[0];

    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(size, size),
          painter: CycleRingPainter(
            phases: phases,
            trackerMode: widget.profile.trackerMode,
            totalCycleDays: avgLength,
            confidenceLevel: widget.prediction?.confidenceLevel ?? 'none',
            currentProgress: (currentDay ?? 1) / avgLength.toDouble(),
            currentDay: currentDay,
            selectedDaySmooth: _selectedDaySmooth,
            isDragging: _isDragging,
            innerColor: phaseColor,
            waveValue: _waveController.value,
            formattedDate: formattedDate,
            dayInPhase: dayInPhase,
            phaseEmoji: _getPhaseEmoji(selectedPhase),
            phaseName: _getPhaseName(selectedPhase),
            nextPhaseName: nextPhaseInfo['name'] as String?,
            daysUntilNextPhase: nextPhaseInfo['daysLeft'] as int?,
            coefficientOfVar: widget.prediction?.coefficientOfVar ?? 0.0,
          ),
        );
      },
    );
  }

  int _calculateDayInPhase(int day, int avgLength) {
    if (day <= 5) return day; // Menstrual
    if (day <= avgLength * 0.45) return day - 5; // Follicular
    if (day <= avgLength * 0.55) return day - (avgLength * 0.45).floor(); // Ovulation
    return day - (avgLength * 0.55).floor(); // Luteal
  }

  String _calculatePhase(int day, int avgLength) {
    if (day <= 5) return 'menstrual';
    if (day <= avgLength * 0.45) return 'follicular';
    if (day <= avgLength * 0.55) return 'ovulation';
    if (day <= avgLength) return 'luteal';
    return 'waiting';
  }

  Map<String, dynamic> _calculateNextPhase(int day, int avgLength) {
    final follicularStart = 6;
    final ovulationStart = (avgLength * 0.45).floor() + 1;
    final lutealStart = (avgLength * 0.55).floor() + 1;
    final periodStart = avgLength + 1;

    if (day < follicularStart) return {'name': 'follicular', 'daysLeft': follicularStart - day};
    if (day < ovulationStart) return {'name': 'ovulation', 'daysLeft': ovulationStart - day};
    if (day < lutealStart) return {'name': 'luteal', 'daysLeft': lutealStart - day};
    if (day < periodStart) return {'name': 'period', 'daysLeft': periodStart - day};
    return {'name': 'period', 'daysLeft': 0};
  }

  List<CyclePhaseData> _getPhasesForCurrentMode() {
    final avgLength = widget.profile.avgCycleLength;
    // New requested color scheme
    return [
      CyclePhaseData(
        id: 'menstrual',
        name: 'Menstrual',
        startPercent: 0.0,
        endPercent: 5 / avgLength,
        gradient: [const Color(0xFFC026D3), const Color(0xFFDB2777)], // Dark Pink
      ),
      CyclePhaseData(
        id: 'follicular',
        name: 'Follicular',
        startPercent: 5 / avgLength,
        endPercent: (avgLength * 0.45) / avgLength,
        gradient: [const Color(0xFFFDE047), const Color(0xFFEAB308)], // Yellow
      ),
      CyclePhaseData(
        id: 'ovulation',
        name: 'Ovulation',
        startPercent: (avgLength * 0.45) / avgLength,
        endPercent: (avgLength * 0.55) / avgLength,
        gradient: [const Color(0xFF2563EB), const Color(0xFF1E40AF)], // Blue
      ),
      CyclePhaseData(
        id: 'luteal',
        name: 'Luteal',
        startPercent: (avgLength * 0.55) / avgLength,
        endPercent: 1.0,
        gradient: [const Color(0xFF7DD3FC), const Color(0xFF38BDF8)], // Light Blue
      ),
    ];
  }

  String _getPhaseEmoji(String? phase) {
    switch (phase) {
      case 'menstrual': return '🩸';
      case 'follicular': return '🌱';
      case 'ovulation': return '🥚';
      case 'luteal': return '🌙';
      default: return '🌱';
    }
  }

  String _getPhaseName(String? phase) {
    if (phase == null || phase == 'waiting') return 'Preparing';
    return phase[0].toUpperCase() + phase.substring(1);
  }
}
