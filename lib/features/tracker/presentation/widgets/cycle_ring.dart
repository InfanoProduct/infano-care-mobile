import 'dart:math';
import 'package:flutter/material.dart';
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

class _CycleRingState extends State<CycleRing> with SingleTickerProviderStateMixin {
  int _viewingCycleIndex = 0; // 0 is current, 1+ is history
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _handleSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;
    
    if (details.primaryVelocity! < -500) {
      // Swipe Left -> Next (Return to current if possible)
      if (_viewingCycleIndex > 0) {
        setState(() => _viewingCycleIndex--);
        _fadeController.forward(from: 0.0);
      }
    } else if (details.primaryVelocity! > 500) {
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
          onHorizontalDragEnd: _handleSwipe,
          onTapUp: (details) => _handleTap(details, constraints),
          child: FadeTransition(
            opacity: _fadeController,
            child: CustomPaint(
              size: Size(size, size),
              painter: _getPainter(size),
            ),
          ),
        );
      }
    );
  }

  CycleRingPainter _getPainter(double size) {
    final phases = _getPhasesForCurrentMode();
    final bool isHistory = _viewingCycleIndex > 0;
    
    if (isHistory) {
      final record = widget.history[_viewingCycleIndex - 1];
      return CycleRingPainter(
        phases: phases,
        trackerMode: 'active',
        confidenceLevel: 'high', // History is 100% confident
        currentProgress: 1.0, // Full ring for history? Or show end of cycle?
        phaseEmoji: '📊',
        phaseName: 'Past Cycle ${record.cycleNumber}',
        historicalSegments: [0.0, (record.periodDurationDays ?? 5) / (record.cycleLengthDays ?? 28)],
      );
    }

    return CycleRingPainter(
      phases: phases,
      trackerMode: widget.profile.trackerMode,
      confidenceLevel: widget.prediction?.confidenceLevel ?? 'none',
      currentProgress: (widget.profile.currentCycleDay ?? 1) / 28.0,
      currentDay: widget.profile.currentCycleDay,
      phaseEmoji: _getPhaseEmoji(widget.profile.currentPhase),
      phaseName: _getPhaseName(widget.profile.currentPhase),
      coefficientOfVar: widget.prediction?.coefficientOfVar ?? 0.0,
    );
  }

  List<CyclePhaseData> _getPhasesForCurrentMode() {
    // Standard 28-day breakdown
    return [
      CyclePhaseData(
        id: 'menstrual',
        name: 'Menstrual',
        startPercent: 0.0,
        endPercent: 5 / 28,
        gradient: [const Color(0xFFDC2626), const Color(0xFFF97316)],
      ),
      CyclePhaseData(
        id: 'follicular',
        name: 'Follicular',
        startPercent: 5 / 28,
        endPercent: 12 / 28,
        gradient: [const Color(0xFFEC4899), const Color(0xFF9333EA)],
      ),
      CyclePhaseData(
        id: 'ovulation',
        name: 'Ovulation',
        startPercent: 12 / 28,
        endPercent: 16 / 28,
        gradient: [const Color(0xFFD97706), const Color(0xFF16A34A)],
      ),
      CyclePhaseData(
        id: 'luteal',
        name: 'Luteal',
        startPercent: 16 / 28,
        endPercent: 1.0,
        gradient: [const Color(0xFF2563EB), const Color(0xFF6B21A8)],
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
