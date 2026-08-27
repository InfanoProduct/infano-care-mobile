import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'cycle_ring_painter.dart';

class CycleRing extends StatefulWidget {
  final CycleProfileModel profile;
  final PredictionResultModel? prediction;
  final List<CycleRecordModel> history;
  final bool isRefreshing;
  final VoidCallback? onCenterTap;
  final Function(String)? onSegmentTap;

  const CycleRing({
    super.key,
    required this.profile,
    this.prediction,
    this.history = const [],
    this.isRefreshing = false,
    this.onCenterTap,
    this.onSegmentTap,
  });

  @override
  State<CycleRing> createState() => _CycleRingState();
}

class _CycleRingState extends State<CycleRing> with TickerProviderStateMixin {
  int _centerDataIndex = 0; // 0: Date/Phase/Day, 1: Period/Pregnancy/Avg
  int _viewingCycleIndex = 0; // 0 is current, 1+ is history
  double? _selectedDaySmooth; // Double for smooth animation
  bool _isDragging = false;
  late AnimationController _fadeController;
  late AnimationController _waveController;
  Timer? _autoRotateTimer;

  void _startAutoRotate() {
    _autoRotateTimer?.cancel();
    _autoRotateTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _centerDataIndex = (_centerDataIndex + 1) % 3;
        });
      }
    });
  }

  void _resetAutoRotate() {
    _startAutoRotate();
  }

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
    
    int localCurrentDay = 1;
    if (widget.profile.lastPeriodStart != null) {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final lastStart = widget.profile.lastPeriodStart!;
      final startDate = DateTime(lastStart.year, lastStart.month, lastStart.day);
      localCurrentDay = todayDate.difference(startDate).inDays + 1;
      if (localCurrentDay < 1) localCurrentDay = 1;
      _selectedDaySmooth = localCurrentDay.toDouble();
    } else {
      _selectedDaySmooth = 1.0;
    }

    _startAutoRotate();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _waveController.dispose();
    _autoRotateTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CycleRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final bool refreshFinished = oldWidget.isRefreshing && !widget.isRefreshing;
    final bool profileChanged = oldWidget.profile != widget.profile;
    
    if (profileChanged || refreshFinished) {
      if (widget.profile.lastPeriodStart != null) {
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);
        final lastStart = widget.profile.lastPeriodStart!;
        final startDate = DateTime(lastStart.year, lastStart.month, lastStart.day);
        int localCurrentDay = todayDate.difference(startDate).inDays + 1;
        if (localCurrentDay < 1) localCurrentDay = 1;
        
        setState(() {
          _selectedDaySmooth = localCurrentDay.toDouble();
          _viewingCycleIndex = 0;
        });
      } else {
        setState(() {
          _selectedDaySmooth = 1.0;
          _viewingCycleIndex = 0;
        });
      }
    }
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

    // 1. Center Disc Tap -> Cycle Data Sets
    if (distance < innerR) {
       setState(() {
         _centerDataIndex = (_centerDataIndex + 1) % 3;
       });
       _resetAutoRotate();
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
    
    // Compute localCurrentDay for delay check
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final lastStart = widget.profile.lastPeriodStart ?? now;
    final startDate = DateTime(lastStart.year, lastStart.month, lastStart.day);
    int localCurrentDay = todayDate.difference(startDate).inDays + 1;
    if (localCurrentDay < 1) localCurrentDay = 1;

    final bool isTodayDelayed = localCurrentDay > avgLength;
    final double maxDay = isTodayDelayed ? localCurrentDay.toDouble() : avgLength.toDouble();

    final percent = angle / (2 * pi);
    final day = (percent * maxDay) + 1; // Scale smoothly to maxDay
    
    final clampedDay = day.clamp(1.0, maxDay);
    if (_selectedDaySmooth != null) {
      final double diff = (clampedDay - _selectedDaySmooth!).abs();
      if (isTodayDelayed && diff > maxDay / 2) {
        return; // Block wrap-around in delayed phase to prevent forward rotation
      }
    }
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
        
        return Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _handleTap(details, constraints),
              onVerticalDragStart: (details) => _handlePanUpdate(DragUpdateDetails(
                globalPosition: details.globalPosition,
                localPosition: details.localPosition,
              ), constraints),
              onVerticalDragUpdate: (details) => _handlePanUpdate(details, constraints),
              onHorizontalDragStart: (details) => _handlePanUpdate(DragUpdateDetails(
                globalPosition: details.globalPosition,
                localPosition: details.localPosition,
              ), constraints),
              onHorizontalDragUpdate: (details) => _handlePanUpdate(details, constraints),
              onVerticalDragEnd: (details) {
                _handlePanEnd();
              },
              onHorizontalDragEnd: (details) {
                _handleSwipe(details);
                _handlePanEnd();
              },
              child: FadeTransition(
                opacity: _fadeController,
                child: _getPainterWidget(size),
              ),
            ),
            // Center Content Layer
            if (_viewingCycleIndex == 0) // Only show in current cycle view
              _buildCenterContent(size),
          ],
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
          historicalSegments: [0.0, (record.periodDurationDays ?? 5) / (record.cycleLengthDays ?? 28)],
        ),
      );
    }

    final now = DateTime.now();
    final lastStart = widget.profile.lastPeriodStart ?? now;
    final todayDate = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(lastStart.year, lastStart.month, lastStart.day);
    
    int localCurrentDay = todayDate.difference(startDate).inDays + 1;
    if (localCurrentDay < 1) localCurrentDay = 1;
    
    final avgLength = widget.profile.avgCycleLength;
    final displayDay = _selectedDaySmooth?.round() ?? localCurrentDay;
    
    // Calculate absolute date
    final selectedPhase = _calculatePhase(displayDay, avgLength);
    
    // Get color for the inner background based on selected phase
    final phaseColor = selectedPhase == 'delayed'
        ? const Color(0xFFFEF2F2)
        : phases.firstWhere((p) => p.id == selectedPhase, orElse: () => phases.first).gradient[0];

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
            currentProgress: localCurrentDay / avgLength.toDouble(),
            currentDay: localCurrentDay,
            selectedDaySmooth: _selectedDaySmooth,
            isDragging: _isDragging,
            innerColor: phaseColor,
            waveValue: _waveController.value,
          ),
        );
      },
    );
  }

  Widget _buildCenterContent(double size) {
    final innerR = size * 0.36;
    final avgLength = widget.profile.avgCycleLength;
    final displayDay = _selectedDaySmooth?.round() ?? widget.profile.currentCycleDay ?? 1;

    // Compute localCurrentDay for comparison
    final now = DateTime.now();
    final lastStart = widget.profile.lastPeriodStart ?? now;
    final todayDate = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(lastStart.year, lastStart.month, lastStart.day);
    int localCurrentDay = todayDate.difference(startDate).inDays + 1;
    if (localCurrentDay < 1) localCurrentDay = 1;

    final selectedPhase = _calculatePhase(displayDay, avgLength);
    final nextPhaseInfo = _calculateNextPhase(displayDay, avgLength);
    
    // Formatting date
    final absoluteDate = lastStart.add(Duration(days: displayDay - 1));
    final dayStr = DateFormat('d').format(absoluteDate);
    final monthStr = DateFormat('MMMM').format(absoluteDate).toLowerCase();

    final bool isTodayDelayed = localCurrentDay > avgLength;
    final bool isFutureDate = displayDay > localCurrentDay;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _centerDataIndex = (_centerDataIndex + 1) % 3;
        });
      },
      child: Container(
        width: innerR * 2,
        height: innerR * 2,
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: widget.isRefreshing 
            ? Column(
                key: const ValueKey('refreshing'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppColors.purple,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Refreshing...',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              )
            : (isTodayDelayed && isFutureDate)
              ? Column(
                  key: const ValueKey('future_delayed_notice'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Text(dayStr, style: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w300, color: AppColors.textDark)),
                    Text(monthStr, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textMedium)),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Log your periods and get your next period prediction.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.purple,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                )
              : _centerDataIndex == 0 
                ? _buildSetOne(dayStr, monthStr, selectedPhase, displayDay, nextPhaseInfo)
                : _centerDataIndex == 1
                  ? _buildSetTwo(selectedPhase, displayDay)
                  : _buildSetThree(),
        ),
      ),
    );
  }

  Widget _buildSetOne(String day, String month, String phase, int cycleDay, Map<String, dynamic> nextPhase) {
    final nextPhaseName = nextPhase['name'] as String?;
    final daysUntilNextPhase = nextPhase['daysLeft'] as int?;
    final avgLength = widget.profile.avgCycleLength;
    
    if (phase == 'delayed') {
      final int daysLate = cycleDay - avgLength.toInt();
      final bool isExpectedToday = daysLate == 1;

      if (isExpectedToday) {
        return Column(
          key: const ValueKey('set_one_expected_today'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🩸', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text(
              'Periods Expected Today',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onCenterTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Mark Today as Period Day',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      }

      return Column(
        key: const ValueKey('set_one_delayed'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 6),
          Text(
            'Late for ${daysLate - 1} ${daysLate - 1 == 1 ? 'day' : 'days'}',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_getPhaseEmoji(phase), style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                _getPhaseName(phase),
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          Text(
            'Cycle day $cycleDay',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: widget.onCenterTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Mark Today as Period Day',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('set_one'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. Cycle day 1
        Text(
          'Cycle day $cycleDay',
          style: GoogleFonts.nunito(
            fontSize: 26, 
            fontWeight: FontWeight.w900, 
            color: AppColors.pink,
          ),
        ),
        const SizedBox(height: 4),
        // 2. Phase Icon and name
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_getPhaseEmoji(phase), style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              _getPhaseName(phase),
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 3. Date
        Text(
          '$day ${month[0].toUpperCase()}${month.substring(1)}',
          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMedium),
        ),
        const SizedBox(height: 8),
        // 4. Number of days left for the next phase
        if (nextPhaseName != null && daysUntilNextPhase != null)
          Text(
            daysUntilNextPhase == 0 
              ? 'Phase change today!' 
              : '$daysUntilNextPhase ${daysUntilNextPhase == 1 ? 'day' : 'days'} until ${nextPhaseName[0].toUpperCase()}${nextPhaseName.substring(1)}',
            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMedium),
          ),
      ],
    );
  }

  Widget _buildSetTwo(String phase, int displayDay) {
    final avgLength = widget.profile.avgCycleLength;
    final avgPeriod = widget.profile.avgPeriodDuration;

    // Calculate days until period relative to the selected displayDay
    int daysToPeriod = 999;
    if (widget.prediction?.predictedStart != null) {
      final now = DateTime.now();
      final lastStart = widget.profile.lastPeriodStart ?? now;
      final absoluteDate = lastStart.add(Duration(days: displayDay - 1));
      
      final selectedDate = DateTime(absoluteDate.year, absoluteDate.month, absoluteDate.day);
      final predictedDate = DateTime(
        widget.prediction!.predictedStart.year,
        widget.prediction!.predictedStart.month,
        widget.prediction!.predictedStart.day,
      );
      
      daysToPeriod = predictedDate.difference(selectedDate).inDays;
    }

    // If in delayed phase OR if we've reached/passed the predicted period date (daysToPeriod <= 0),
    // show the helpful period logging prompt instead of a countdown.
    if (phase == 'delayed' || daysToPeriod <= 0) {
      return Column(
        key: const ValueKey('set_two_delayed'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            'Log Your Period',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.purple,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'to get accurate predictions',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Avg. Cycle', '$avgLength'),
              _buildStatItem('Avg. Period', '${avgPeriod.round()}'),
            ],
          ),
        ],
      );
    }

    String pregnancyChance = 'Low';
    if (phase == 'follicular') pregnancyChance = 'Medium';
    if (phase == 'ovulation') pregnancyChance = 'High';

    return Column(
      key: const ValueKey('set_two'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$daysToPeriod days',
          style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.purple),
        ),
        Text(
          'until next period',
          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMedium),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getPregnancyColor(pregnancyChance).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$pregnancyChance chance of pregnancy',
            style: GoogleFonts.nunito(
              fontSize: 12, 
              fontWeight: FontWeight.w700, 
              color: _getPregnancyColor(pregnancyChance)
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('Avg. Cycle', '$avgLength'),
            _buildStatItem('Avg. Period', '${avgPeriod.round()}'),
          ],
        ),
      ],
    );
  }

  Widget _buildSetThree() {
    final streak = widget.prediction?.currentLogStreak ?? 0;
    final mode = widget.profile.trackerMode;
    final displayMode = mode == 'active' ? 'Active Tracking' : 'Watching & Waiting';

    return Column(
      key: const ValueKey('set_three'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🔥', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Text(
          '$streak Day Streak',
          style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.pink),
        ),
        Text(
          'Keep logging to bloom! ✨',
          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            displayMode,
            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.purple),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        Text(label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
      ],
    );
  }

  Color _getPregnancyColor(String chance) {
    if (chance == 'High') return Colors.red;
    if (chance == 'Medium') return Colors.orange;
    return Colors.green;
  }



  String _calculatePhase(int day, int avgLength) {
    final hasPeriodStarted = widget.profile.lastPeriodStart != null;
    final hasPeriodEnded = widget.profile.lastPeriodEnd != null &&
        widget.profile.lastPeriodStart != null &&
        !widget.profile.lastPeriodEnd!.isBefore(widget.profile.lastPeriodStart!);

    if (hasPeriodStarted && !hasPeriodEnded) {
      return 'menstrual';
    }

    int periodDuration = 5;
    if (hasPeriodEnded) {
      periodDuration = widget.profile.lastPeriodEnd!.difference(widget.profile.lastPeriodStart!).inDays + 1;
    } else if (widget.profile.avgPeriodDuration > 0) {
      periodDuration = widget.profile.avgPeriodDuration;
    }

    if (day <= periodDuration) return 'menstrual';
    if (day <= avgLength * 0.45) return 'follicular';
    if (day <= avgLength * 0.55) return 'ovulation';
    if (day <= avgLength) return 'luteal';
    return 'delayed';
  }

  Map<String, dynamic> _calculateNextPhase(int day, int avgLength) {
    final hasPeriodStarted = widget.profile.lastPeriodStart != null;
    final hasPeriodEnded = widget.profile.lastPeriodEnd != null &&
        widget.profile.lastPeriodStart != null &&
        !widget.profile.lastPeriodEnd!.isBefore(widget.profile.lastPeriodStart!);

    if (hasPeriodStarted && !hasPeriodEnded) {
      return {'name': 'follicular', 'daysLeft': 1};
    }

    int periodDuration = 5;
    if (hasPeriodEnded) {
      periodDuration = widget.profile.lastPeriodEnd!.difference(widget.profile.lastPeriodStart!).inDays + 1;
    } else if (widget.profile.avgPeriodDuration > 0) {
      periodDuration = widget.profile.avgPeriodDuration;
    }

    final follicularStart = periodDuration + 1;
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
    final hasPeriodStarted = widget.profile.lastPeriodStart != null;
    final hasPeriodEnded = widget.profile.lastPeriodEnd != null &&
        widget.profile.lastPeriodStart != null &&
        !widget.profile.lastPeriodEnd!.isBefore(widget.profile.lastPeriodStart!);

    final now = DateTime.now();
    final lastStart = widget.profile.lastPeriodStart ?? now;
    final todayDate = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(lastStart.year, lastStart.month, lastStart.day);
    int localCurrentDay = todayDate.difference(startDate).inDays + 1;
    if (localCurrentDay < 1) localCurrentDay = 1;

    int periodDuration = 5;
    if (hasPeriodEnded) {
      periodDuration = widget.profile.lastPeriodEnd!.difference(widget.profile.lastPeriodStart!).inDays + 1;
    } else if (hasPeriodStarted) {
      periodDuration = max(widget.profile.avgPeriodDuration > 0 ? widget.profile.avgPeriodDuration : 5, localCurrentDay);
    }

    // New requested color scheme
    return [
      CyclePhaseData(
        id: 'menstrual',
        name: 'Menstrual',
        startPercent: 0.0,
        endPercent: periodDuration / avgLength,
        gradient: [const Color(0xFFC026D3), const Color(0xFFDB2777)], // Dark Pink
      ),
      CyclePhaseData(
        id: 'follicular',
        name: 'Follicular',
        startPercent: periodDuration / avgLength,
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
      case 'delayed': return '⏰';
      default: return '🌱';
    }
  }

  String _getPhaseName(String? phase) {
    if (phase == 'delayed') return 'Period Delayed';
    if (phase == null || phase == 'waiting') return 'Preparing';
    return phase[0].toUpperCase() + phase.substring(1);
  }
}
