import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

// ── Dark Purple Main CTA Color ───────────────────────────────────────────────
const _kDarkPurpleCTA = Color(0xFF6D28D9);

// ── Pastel palette for the 4 phases ─────────────────────────────────────────
const _kPhaseColors = [
  Color(0xFFFECDD3), // Rose — Period
  Color(0xFFDDD6FE), // Lavender — Follicular
  Color(0xFFFDE68A), // Amber — Ovulation
  Color(0xFFBBF7D0), // Mint — Luteal
];
const _kPhaseBorders = [
  Color(0xFFF43F5E), // Rose border
  Color(0xFF7C3AED), // Violet border
  Color(0xFFD97706), // Amber border
  Color(0xFF059669), // Emerald border
];
const _kPhaseText = [
  Color(0xFF9F1239), // Rose text
  Color(0xFF5B21B6), // Violet text
  Color(0xFF92400E), // Amber text
  Color(0xFF065F46), // Emerald text
];

// Creative rich metadata with reduced, concise text
const List<Map<String, String>> _kPhaseCreativeDetails = [
  {
    'zone': 'zone_1',
    'stepTitle': 'Step 1 • Period 🩸',
    'subtitle': 'The Reset & Refresh',
    'creativeDesc':
        'The body resets and sheds its soft lining to start fresh. Rest, stay warm, and hydrate.',
    'superpower': '🛀 Rest & Recharging',
  },
  {
    'zone': 'zone_2',
    'stepTitle': 'Step 2 • Follicular Phase 🌱',
    'subtitle': 'Power-Up & Energy Surge',
    'creativeDesc':
        'Estrogen rises, energy climbs, and a fresh new egg matures in the ovary.',
    'superpower': '💡 Focus & Creativity',
  },
  {
    'zone': 'zone_3',
    'stepTitle': 'Step 3 • Ovulation 🥚',
    'subtitle': 'The Peak Spark',
    'creativeDesc':
        'The mature egg is released. Energy, confidence, and natural glow reach their peak.',
    'superpower': '🌟 Vitality & Confidence',
  },
  {
    'zone': 'zone_4',
    'stepTitle': 'Step 4 • Luteal Phase 🌙',
    'subtitle': 'Inner Sanctuary & Wind-Down',
    'creativeDesc':
        'Progesterone warms the body and prepares a cozy space for wind-down.',
    'superpower': '🧘 Intuition & Self-Care',
  },
];

/// DragToLabelWidget — "Map Your Cycle"
/// 1. Drag phase labels onto any zone (Top, Right, Bottom, Left).
/// 2. Click "Reveal My Cycle!" (Dark Purple CTA) -> Wheel spins 720° and aligns into true sequence!
/// 3. In Reveal Screen, top is Period, right is Follicular, bottom is Ovulation, left is Luteal.
/// 4. Full Cycle Journey cards display in order with reduced, clean text.
class DragToLabelWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const DragToLabelWidget({
    super.key,
    required this.content,
    required this.onCompleted,
  });

  @override
  State<DragToLabelWidget> createState() => _DragToLabelWidgetState();
}

class _DragToLabelWidgetState extends State<DragToLabelWidget>
    with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _targets;
  // zoneIndex (0-3) -> placed target by user
  final Map<int, Map<String, dynamic>> _placed = {};
  bool _revealed = false;
  bool _isCompleting = false;

  late AnimationController _pulseController;
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  @override
  void initState() {
    super.initState();
    _targets =
        List<Map<String, dynamic>>.from(widget.content['targets'] as List? ?? []);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _unplaced =>
      _targets.where((t) => !_placed.values.contains(t)).toList();

  bool get _allPlaced => _placed.length == _targets.length;

  void _onDrop(Map<String, dynamic> target, int zoneIndex) {
    setState(() {
      _placed.removeWhere((k, v) => v == target);
      _placed.remove(zoneIndex);
      _placed[zoneIndex] = target;
    });
    AppSoundService.instance.playPop();
  }

  void _removeFromZone(int zoneIndex) {
    setState(() => _placed.remove(zoneIndex));
  }

  void _onReveal() {
    AppSoundService.instance.playCorrect();
    setState(() => _revealed = true);
    _spinController.forward(from: 0.0);
  }

  // Zone alignments (0: Top, 1: Right, 2: Bottom, 3: Left)
  static const List<Alignment> _zoneAlignments = [
    Alignment(0, -0.72),  // Top
    Alignment(0.72, 0),   // Right
    Alignment(0, 0.72),   // Bottom
    Alignment(-0.72, 0),  // Left
  ];

  static const List<String> _zoneHints = ['Top', 'Right', 'Bottom', 'Left'];

  // Map zone indices to actual sequence target on reveal:
  // Top (0) -> Period (cm1)
  // Right (1) -> Follicular Phase (cm2)
  // Bottom (2) -> Ovulation (cm3)
  // Left (3) -> Luteal Phase (cm4)
  Map<int, Map<String, dynamic>> get _shuffledCorrectPlaced {
    final map = <int, Map<String, dynamic>>{};
    for (int i = 0; i < 4; i++) {
      final target = _targets.firstWhere(
        (t) => (t['correctZone'] as String?) == 'zone_${i + 1}',
        orElse: () => _targets[i % _targets.length],
      );
      map[i] = target;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<bool>(_revealed),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildCircleDiagram(),
              const SizedBox(height: 24),
              if (!_revealed) ...[
                if (_unplaced.isNotEmpty) _buildLabelBank(),
                if (_unplaced.isEmpty && _allPlaced) ...[
                  const SizedBox(height: 8),
                  _buildRevealButton(),
                ],
              ],
              if (_revealed) ...[
                const SizedBox(height: 24),
                _buildPhaseFacts(),
                const SizedBox(height: 24),
                _buildCollectButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFCE7F3), Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDB2777).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _kDarkPurpleCTA,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _kDarkPurpleCTA.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(child: Text('🩸', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _revealed ? 'Cycle Mapped! 🌸' : (widget.content['title'] as String? ?? 'Map Your Cycle'),
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _kDarkPurpleCTA,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _revealed
                      ? 'Your cycle is auto-aligned to the actual menstrual sequence starting with Period!'
                      : (widget.content['instruction'] as String? ??
                          'Drag each phase label onto any zone on the cycle!'),
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    color: AppColors.textMedium,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Circular diagram with spinning wheel effect ───────────────────────────
  Widget _buildCircleDiagram() {
    final activePlacedMap = _revealed ? _shuffledCorrectPlaced : _placed;

    return AnimatedBuilder(
      animation: _spinAnimation,
      builder: (context, child) {
        // Spin angle: 2 full rotations (4*pi) settling smoothly to 0.0
        final spinAngle = (1.0 - _spinAnimation.value) * (4 * math.pi);

        return Transform.rotate(
          angle: spinAngle,
          child: child,
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _kDarkPurpleCTA.withValues(alpha: 0.12),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background arc painter
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CyclePainter(
                      placed: activePlacedMap,
                      revealed: _revealed,
                    ),
                  ),
                ),

                // Centre label (counter-rotated to stay upright)
                Center(
                  child: AnimatedBuilder(
                    animation: _spinAnimation,
                    builder: (context, child) {
                      final spinAngle = (1.0 - _spinAnimation.value) * (4 * math.pi);
                      return Transform.rotate(
                        angle: -spinAngle,
                        child: child,
                      );
                    },
                    child: Container(
                      width: size * 0.28,
                      height: size * 0.28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFE9D5FF),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _kDarkPurpleCTA.withValues(alpha: 0.1),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_revealed ? '✨' : '🔄', style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text(
                            _revealed ? 'Aligned' : 'Cycle',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _kDarkPurpleCTA,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4 Drop zone overlays at Top / Right / Bottom / Left
                ...List.generate(4, (i) {
                  return Align(
                    alignment: _zoneAlignments[i],
                    child: _buildDropZone(i, size, activePlacedMap),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropZone(
      int zoneIndex, double diagramSize, Map<int, Map<String, dynamic>> activePlacedMap) {
    final placedTarget = activePlacedMap[zoneIndex];
    final bgColor = _kPhaseColors[zoneIndex];
    final borderColor = _kPhaseBorders[zoneIndex];
    final textColor = _kPhaseText[zoneIndex];
    final hint = _zoneHints[zoneIndex];
    final zoneSize = diagramSize * 0.30;

    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) => _onDrop(details.data, zoneIndex),
      builder: (context, candidateData, _) {
        final isHovering = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: (placedTarget != null && !_revealed)
              ? () => _removeFromZone(zoneIndex)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: zoneSize,
            height: zoneSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: placedTarget != null
                  ? bgColor
                  : (isHovering ? bgColor.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.92)),
              border: Border.all(
                color: placedTarget != null || isHovering
                    ? borderColor
                    : borderColor.withValues(alpha: 0.35),
                width: placedTarget != null || isHovering ? 2.5 : 1.5,
                style: BorderStyle.solid,
              ),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: placedTarget != null ? 0.2 : 0.08),
                  blurRadius: placedTarget != null ? 12 : 6,
                  spreadRadius: placedTarget != null ? 1 : 0,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _spinAnimation,
              builder: (context, child) {
                final spinAngle = (1.0 - _spinAnimation.value) * (4 * math.pi);
                return Transform.rotate(
                  angle: -spinAngle, // Counter-rotate so badge text stays upright!
                  child: child,
                );
              },
              child: placedTarget != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          placedTarget['emoji'] as String? ?? '🌸',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 3),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            placedTarget['label'] as String? ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (_revealed) ...[
                          const SizedBox(height: 3),
                          Icon(Icons.check_circle_rounded,
                              size: 14, color: borderColor),
                        ],
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, child) => Opacity(
                            opacity: 0.35 + 0.45 * _pulseController.value,
                            child: Icon(
                              Icons.add_circle_outline_rounded,
                              size: 22,
                              color: borderColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHovering ? 'Drop!' : hint,
                          style: GoogleFonts.nunito(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: borderColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  // ── Draggable label bank ─────────────────────────────────────────────────
  Widget _buildLabelBank() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              'Drag a phase onto any zone:',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _unplaced
              .map((target) => _buildDraggableLabel(target))
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDraggableLabel(Map<String, dynamic> target) {
    final emoji = target['emoji'] as String? ?? '🌸';
    final label = target['label'] as String? ?? '';
    final idx = _targets.indexOf(target);
    final color = idx >= 0 ? _kPhaseColors[idx % 4] : const Color(0xFFFCE7F3);
    final border = idx >= 0 ? _kPhaseBorders[idx % 4] : AppColors.pink;
    final text = idx >= 0 ? _kPhaseText[idx % 4] : AppColors.textDark;

    return Draggable<Map<String, dynamic>>(
      data: target,
      feedback: Material(
        color: Colors.transparent,
        child: _LabelChip(
          emoji: emoji,
          label: label,
          bgColor: color,
          borderColor: border,
          textColor: text,
          isDragging: true,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.28,
        child: _LabelChip(
          emoji: emoji,
          label: label,
          bgColor: color,
          borderColor: border,
          textColor: text,
        ),
      ),
      child: _LabelChip(
        emoji: emoji,
        label: label,
        bgColor: color,
        borderColor: border,
        textColor: text,
      ),
    ).animate().fadeIn(delay: (_unplaced.indexOf(target) * 60).ms, duration: 300.ms).scale(begin: const Offset(0.9, 0.9));
  }

  // ── Primary Dark Purple CTA: Reveal button ──────────────────────────────────
  Widget _buildRevealButton() {
    return GestureDetector(
      onTap: _onReveal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _kDarkPurpleCTA, // Solid Dark Purple Main CTA Color
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _kDarkPurpleCTA.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌸', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'Reveal My Cycle!',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.15, curve: Curves.elasticOut);
  }

  // ── Full Cycle Journey (Proper Chronological Sequence + Reduced Text) ────────
  Widget _buildPhaseFacts() {
    final sortedTargets = List<Map<String, dynamic>>.from(_targets);
    sortedTargets.sort((a, b) {
      final za = (a['correctZone'] as String? ?? 'zone_1');
      final zb = (b['correctZone'] as String? ?? 'zone_1');
      return za.compareTo(zb);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sequence Bar Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Full Cycle Journey',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _kDarkPurpleCTA,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Top ➔ Period, followed by the natural monthly sequence:',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 12),
              // Chronological Flow Badges (1 ➔ 2 ➔ 3 ➔ 4)
              Row(
                children: List.generate(4, (idx) {
                  final color = _kPhaseColors[idx];
                  final border = _kPhaseBorders[idx];
                  final t = sortedTargets.length > idx ? sortedTargets[idx] : null;
                  final emoji = t?['emoji'] as String? ?? '🌸';

                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border, width: 1.5),
                            ),
                            child: Column(
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 2),
                                Text(
                                  'P${idx + 1}',
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: _kPhaseText[idx],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (idx < 3)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(Icons.chevron_right_rounded,
                                size: 16, color: Color(0xFFA78BFA)),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),

        const SizedBox(height: 18),

        // Shuffled Chronological Phase Cards with Reduced Text
        ...sortedTargets.asMap().entries.map((entry) {
          final i = entry.key;
          final target = entry.value;

          final zoneKey = target['correctZone'] as String? ?? 'zone_${i + 1}';
          final creativeMeta = _kPhaseCreativeDetails.firstWhere(
            (meta) => meta['zone'] == zoneKey,
            orElse: () => _kPhaseCreativeDetails[i % 4],
          );

          final bgColor = _kPhaseColors[i % 4];
          final borderColor = _kPhaseBorders[i % 4];
          final textColor = _kPhaseText[i % 4];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        target['emoji'] as String? ?? '🌸',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          creativeMeta['stepTitle'] ?? (target['label'] as String? ?? ''),
                          style: GoogleFonts.nunito(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                      ),
                      Icon(Icons.check_circle_rounded, size: 16, color: borderColor),
                    ],
                  ),
                ),

                // Reduced Text Content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creativeMeta['creativeDesc'] ??
                            (target['description'] as String? ?? ''),
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          color: AppColors.textDark,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: bgColor.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Superpower: ',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                creativeMeta['superpower'] ?? '',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: (i * 100).ms, duration: 400.ms)
              .slideY(begin: 0.08, curve: Curves.easeOutCubic);
        }),
      ],
    );
  }

  // ── Primary Dark Purple CTA: Collect XP button ─────────────────────────────
  Widget _buildCollectButton() {
    return GestureDetector(
      onTap: _isCompleting
          ? null
          : () {
              AppSoundService.instance.playPop();
              HapticFeedback.selectionClick();
              setState(() => _isCompleting = true);
              widget.onCompleted();
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _kDarkPurpleCTA, // Solid Dark Purple Main CTA Color
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _kDarkPurpleCTA.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _isCompleting
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue Journey • Collect 🪙 Coins',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── Custom painter — draws 4 coloured arc segments + connecting arrows ───────
class _CyclePainter extends CustomPainter {
  final Map<int, Map<String, dynamic>> placed;
  final bool revealed;

  const _CyclePainter({required this.placed, required this.revealed});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.46;
    final innerR = size.width * 0.155;
    final trackR = size.width * 0.32;

    for (int i = 0; i < 4; i++) {
      final startAngle = -math.pi / 2 + i * math.pi / 2;
      final sweepAngle = math.pi / 2;
      final gapRad = 0.045;

      final fillColor = _kPhaseColors[i].withValues(alpha: placed.containsKey(i) ? 0.85 : 0.3);
      final strokeColor = _kPhaseBorders[i].withValues(alpha: placed.containsKey(i) ? 0.6 : 0.2);

      final paint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(
        cx + innerR * math.cos(startAngle + gapRad),
        cy + innerR * math.sin(startAngle + gapRad),
      );
      path.arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: innerR),
        startAngle + gapRad,
        sweepAngle - 2 * gapRad,
        false,
      );
      path.arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: outerR),
        startAngle + sweepAngle - gapRad,
        -(sweepAngle - 2 * gapRad),
        false,
      );
      path.close();

      canvas.drawPath(path, paint);

      canvas.drawPath(
        path,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = placed.containsKey(i) ? 2.0 : 1.0,
      );

      final arrowAngle = startAngle + sweepAngle / 2;
      final ax = cx + trackR * math.cos(arrowAngle);
      final ay = cy + trackR * math.sin(arrowAngle);

      final arrowPaint = Paint()
        ..color = _kPhaseBorders[i].withValues(alpha: placed.containsKey(i) ? 0.55 : 0.18)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final tangentAngle = arrowAngle + math.pi / 2;
      const arrowLen = 7.0;
      canvas.drawLine(
        Offset(ax - arrowLen * math.cos(tangentAngle - 0.4), ay - arrowLen * math.sin(tangentAngle - 0.4)),
        Offset(ax, ay),
        arrowPaint,
      );
      canvas.drawLine(
        Offset(ax, ay),
        Offset(ax - arrowLen * math.cos(tangentAngle + 0.4), ay - arrowLen * math.sin(tangentAngle + 0.4)),
        arrowPaint,
      );
    }

    final dashPaint = Paint()
      ..color = const Color(0xFFE9D5FF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dashCount = 48;
    for (int d = 0; d < dashCount; d++) {
      if (d % 2 == 0) continue;
      final a1 = 2 * math.pi * d / dashCount;
      final a2 = 2 * math.pi * (d + 0.85) / dashCount;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: outerR + 6),
        a1,
        a2 - a1,
        false,
        dashPaint,
      );
    }

    canvas.drawCircle(
      Offset(cx, cy),
      innerR,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_CyclePainter old) =>
      old.placed != placed || old.revealed != revealed;
}

// ── Draggable label chip ─────────────────────────────────────────────────────
class _LabelChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final bool isDragging;

  const _LabelChip({
    required this.emoji,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDragging ? bgColor : bgColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: borderColor.withValues(alpha: isDragging ? 0.9 : 0.5),
          width: isDragging ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: isDragging ? 0.28 : 0.1),
            blurRadius: isDragging ? 18 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 17)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.drag_indicator_rounded, size: 15, color: textColor.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
