import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

/// DragToSortWidget — "Good Fit or Fit Problem?"
///
/// Center-aligned layout:
/// Vertically and horizontally centers all 3 segments (Header/Progress, Statement Card, Bins)
/// so that the entire experience sits balanced in the middle of the screen.
class DragToSortWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const DragToSortWidget({
    super.key,
    required this.content,
    required this.onCompleted,
  });

  @override
  State<DragToSortWidget> createState() => _DragToSortWidgetState();
}

class _DragToSortWidgetState extends State<DragToSortWidget>
    with TickerProviderStateMixin {
  late final ConfettiController _confettiCtrl;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;
  late final AnimationController _xpCtrl;
  late final AnimationController _hintCtrl;
  late final Animation<double> _hintAnim;

  late final List<_SortBin> _bins;
  late final List<_SortItem> _deck;
  final Map<String, List<String>> _sorted = {};
  final Map<String, int> _count = {};

  int _index = 0;
  int _xp = 0;
  bool _isDragging = false;
  Offset _drag = Offset.zero;
  String? _hovBin;
  bool _wrongFlash = false;
  bool _showHint = true;
  bool _showResults = false;
  bool _completing = false;

  // Curated pastel brand color gradients for cards
  static const List<List<Color>> _pastelGradients = [
    [Color(0xFFF3E8FF), Color(0xFFF9F0FF)], // Brand Pastel Purple / Lavender
    [Color(0xFFFCE7F3), Color(0xFFFDF2F8)], // Brand Pastel Pink
    [Color(0xFFE0F2FE), Color(0xFFF0F9FF)], // Soft Pastel Blue
    [Color(0xFFFEF3C7), Color(0xFFFFFBEB)], // Soft Pastel Gold
    [Color(0xFFCCFBF1), Color(0xFFF0FDFA)], // Soft Pastel Mint
  ];

  List<Map<String, dynamic>> get _rawBins =>
      List<Map<String, dynamic>>.from(widget.content['bins'] as List? ?? []);
  List<Map<String, dynamic>> get _rawItems =>
      List<Map<String, dynamic>>.from(widget.content['items'] as List? ?? []);

  bool get _done => _index >= _deck.length;
  _SortItem? get _card => _done ? null : _deck[_index];
  int get _remaining => _deck.length - _index;

  Color _col(_SortBin b) => Color(int.parse('FF${b.colorHex}', radix: 16));

  @override
  void initState() {
    super.initState();

    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 4));

    _shakeCtrl = AnimationController(vsync: this, duration: 480.ms);
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _xpCtrl = AnimationController(vsync: this, duration: 500.ms);
    _hintCtrl = AnimationController(vsync: this, duration: 1100.ms)
      ..repeat(reverse: true);
    _hintAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _hintCtrl, curve: Curves.easeInOut));

    _bins = _rawBins.map(_SortBin.fromMap).toList();
    _deck = (_rawItems.map(_SortItem.fromMap).toList())..shuffle();

    for (final b in _bins) {
      _sorted[b.id] = [];
      _count[b.id] = 0;
    }
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _shakeCtrl.dispose();
    _xpCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  void _sortInto(String binId) {
    final card = _card;
    if (card == null || _shakeCtrl.isAnimating) return;

    if (card.correctBinId == binId) {
      AppSoundService.instance.playCorrect();
      HapticFeedback.mediumImpact();
      _hintCtrl.stop();
      _xpCtrl.forward(from: 0);
      setState(() {
        _sorted[binId]!.add(card.id);
        _count[binId] = (_count[binId] ?? 0) + 1;
        _xp += 3;
        _index++;
        _hovBin = null;
        _isDragging = false;
        _drag = Offset.zero;
        _showHint = false;
      });
      if (_done) {
        Future.delayed(400.ms, () {
          AppSoundService.instance.playFanfare();
          _confettiCtrl.play();
          setState(() => _showResults = true);
        });
      }
    } else {
      AppSoundService.instance.playIncorrect();
      HapticFeedback.heavyImpact();
      setState(() {
        _wrongFlash = true;
        _isDragging = false;
        _drag = Offset.zero;
        _hovBin = null;
      });
      _shakeCtrl.forward(from: 0).then((_) {
        if (mounted) setState(() => _wrongFlash = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) return _results(context);

    return Stack(
      children: [
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _header(),
                      _progressBar(),
                      const SizedBox(height: 24),
                      if (!_done) ...[
                        _cardArea(),
                        const SizedBox(height: 18),
                        if (_showHint) _hintRow(),
                        const SizedBox(height: 18),
                        _animatedBinsRow(),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 35,
            gravity: 0.25,
            colors: const [
              Color(0xFF7C3AED), Color(0xFFEC4899),
              Color(0xFFFBBF24), Color(0xFF10B981), Color(0xFF60A5FA),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Text('🗂️', style: TextStyle(fontSize: 26))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.12, duration: 1400.ms, curve: Curves.easeInOut),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.content['title'] as String? ?? 'Sort It Out!',
                  style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
                Text(
                  'Swipe or drag card into the bins below',
                  style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _xpCtrl,
            builder: (context, child) {
              final s = 1.0 + _xpCtrl.value * 0.35;
              return Transform.scale(
                scale: s,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24)
                            .withValues(alpha: _xpCtrl.value > 0.2 ? 0.55 : 0.25),
                        blurRadius: _xpCtrl.value > 0.2 ? 12 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '+$_xp Coins 🪙',
                    style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08);
  }

  Widget _progressBar() {
    final pct = _deck.isEmpty ? 0.0 : (_index / _deck.length).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$_index / ${_deck.length}',
            style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.purple),
          ),
        ],
      ),
    );
  }

  Widget _cardArea() {
    final card = _card!;
    final pastelGradient = _pastelGradients[_index % _pastelGradients.length];

    final cardWidget = AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) => Transform.translate(
        offset: _isDragging ? _drag : Offset(_shakeAnim.value, 0),
        child: Transform.rotate(
          angle: _isDragging ? _drag.dx * 0.0025 : 0,
          child: child,
        ),
      ),
      child: _compactPastelCard(card, pastelGradient),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Draggable<String>(
          data: card.id,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 320,
              child: _compactPastelCard(card, pastelGradient),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _compactPastelCard(card, pastelGradient),
          ),
          onDragStarted: () {
            setState(() {
              _isDragging = true;
            });
          },
          onDragEnd: (details) {
            setState(() {
              _isDragging = false;
              _drag = Offset.zero;
              _hovBin = null;
            });
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (d) {
              setState(() {
                _isDragging = true;
                _drag += d.delta;
                _hovBin = _drag.dx > 40
                    ? _bins.last.id
                    : _drag.dx < -40
                        ? _bins.first.id
                        : null;
              });
            },
            onPanEnd: (d) {
              if (_drag.dx > 40) {
                _sortInto(_bins.last.id);
              } else if (_drag.dx < -40) {
                _sortInto(_bins.first.id);
              } else if (_drag.dy > 50) {
                final targetBin = _drag.dx >= 0 ? _bins.last.id : _bins.first.id;
                _sortInto(targetBin);
              } else {
                setState(() {
                  _isDragging = false;
                  _drag = Offset.zero;
                  _hovBin = null;
                });
              }
            },
            child: cardWidget,
          ),
        ),
      ),
    );
  }

  Widget _compactPastelCard(_SortItem card, List<Color> gradient) {
    return Container(
      key: ValueKey('card_${card.id}'),
      constraints: const BoxConstraints(maxWidth: 340),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _wrongFlash
              ? [const Color(0xFFFEE2E2), const Color(0xFFFECACA)]
              : gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _wrongFlash
              ? const Color(0xFFEF4444)
              : _isDragging
                  ? AppColors.purple
                  : AppColors.purple.withValues(alpha: 0.25),
          width: (_isDragging || _wrongFlash) ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDragging
                ? AppColors.purple.withValues(alpha: 0.22)
                : _wrongFlash
                    ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                    : AppColors.purple.withValues(alpha: 0.08),
            blurRadius: _isDragging ? 20 : 10,
            spreadRadius: _isDragging ? 2 : 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_remaining > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  (_remaining - 1).clamp(0, 5),
                  (i) => Container(
                    width: 5 - i * 0.5,
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.25 - i * 0.04),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

          Text(card.emoji, style: const TextStyle(fontSize: 42))
              .animate(key: ValueKey('e_${card.id}'))
              .scale(begin: const Offset(0.7, 0.7), duration: 320.ms, curve: Curves.elasticOut),

          const SizedBox(height: 14),

          Text(
            card.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: _wrongFlash ? const Color(0xFFDC2626) : AppColors.textDark,
              height: 1.4,
            ),
          ).animate(key: ValueKey('t_${card.id}')).fadeIn(duration: 250.ms),

          if (_wrongFlash) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
              ),
              child: Text(
                '❌ Try the other bin!',
                style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626)),
              ),
            ).animate().fadeIn(duration: 150.ms),
          ],
        ],
      ),
    )
        .animate(key: ValueKey('wrap_${card.id}'))
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.06, end: 0, duration: 280.ms, curve: Curves.easeOut);
  }

  Widget _hintRow() {
    return AnimatedBuilder(
      animation: _hintAnim,
      builder: (context, child) => Opacity(
        opacity: 0.45 + _hintAnim.value * 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: Offset(-4 * _hintAnim.value, 0),
                child: const Text('⬅️', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 6),
              Text(
                'Drag or tap a bin below',
                style: GoogleFonts.nunito(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMedium),
              ),
              const SizedBox(width: 6),
              Transform.translate(
                offset: Offset(4 * _hintAnim.value, 0),
                child: const Text('➡️', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _animatedBinsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _bins.asMap().entries.map((e) {
          final bin = e.value;
          final col = _col(bin);
          final hov = _hovBin == bin.id;
          final cnt = _count[bin.id] ?? 0;

          final binIcon = hov ? '📂' : (cnt > 0 ? '📦' : '📁');

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: e.key == 0 ? 0 : 12),
              child: DragTarget<String>(
                onWillAcceptWithDetails: (d) {
                  setState(() => _hovBin = bin.id);
                  return true;
                },
                onLeave: (_) => setState(() => _hovBin = null),
                onAcceptWithDetails: (_) => _sortInto(bin.id),
                builder: (context, candidateData, rejectedData) {
                  return GestureDetector(
                    onTap: () => _sortInto(bin.id),
                    child: AnimatedContainer(
                      duration: 180.ms,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: hov ? col : col.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hov ? col : col.withValues(alpha: 0.4),
                          width: hov ? 2.5 : 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: col.withValues(alpha: hov ? 0.35 : 0.08),
                            blurRadius: hov ? 16 : 6,
                            offset: Offset(0, hov ? 4 : 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedRotation(
                                turns: hov ? (e.key == 0 ? -0.06 : 0.06) : 0,
                                duration: 180.ms,
                                child: Text(
                                  binIcon,
                                  style: TextStyle(fontSize: hov ? 26 : 22),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                bin.emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bin.label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: hov ? Colors.white : col,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (cnt > 0)
                            Text(
                              '$cnt sorted ✓',
                              style: GoogleFonts.nunito(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: hov ? Colors.white.withValues(alpha: 0.9) : col,
                              ),
                            )
                          else
                            Text(
                              hov ? 'Release to Drop!' : 'Tap or Drag here',
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: hov ? FontWeight.w800 : FontWeight.w500,
                                color: hov ? Colors.white.withValues(alpha: 0.85) : col.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _results(BuildContext context) {
    final msg = widget.content['completionMessage'] as String? ?? 'All sorted!';
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 52))
                        .animate()
                        .scale(begin: const Offset(0, 0), duration: 600.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 10),
                    Text(
                      'Perfectly Sorted!',
                      style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDark),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 8),
                    Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(fontSize: 13.5, color: AppColors.textMedium, height: 1.5),
                    ).animate().fadeIn(delay: 600.ms),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            '+10 Coins earned!',
                            style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF9A3412)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 800.ms).scaleXY(begin: 0.8),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),

              const SizedBox(height: 24),

              ..._bins.map((bin) {
                final col = _col(bin);
                final ids = _sorted[bin.id] ?? [];
                final items = ids.map((id) => _deck.firstWhere((i) => i.id == id)).toList();
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: col.withValues(alpha: 0.28), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: col.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            Text(bin.emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Text(bin.label,
                                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: col)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: col.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${items.length} items',
                                  style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: col)),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: items.asMap().entries.map((e) {
                            final itm = e.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: col.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(itm.emoji, style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(itm.text,
                                            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                                      ),
                                      Icon(Icons.check_circle_rounded, size: 16, color: col),
                                    ],
                                  ),
                                  if (itm.learningNote != null && itm.learningNote!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: col.withValues(alpha: 0.07),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(itm.learningNote!,
                                          style: GoogleFonts.nunito(fontSize: 11.5, color: AppColors.textMedium, height: 1.4)),
                                    ),
                                  ],
                                ],
                              ),
                            ).animate().fadeIn(delay: Duration(milliseconds: e.key * 80)).slideX(begin: 0.05);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.08);
              }),

              const SizedBox(height: 8),

              GestureDetector(
                onTap: () {
                  if (!_completing) {
                    setState(() => _completing = true);
                    widget.onCompleted();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Text('Collect 🪙 Coins & Continue!',
                          style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 1000.ms).scaleXY(begin: 0.9, curve: Curves.elasticOut),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 50,
            gravity: 0.2,
            colors: const [
              Color(0xFF7C3AED), Color(0xFFEC4899),
              Color(0xFFFBBF24), Color(0xFF10B981), Color(0xFF60A5FA),
            ],
          ),
        ),
      ],
    );
  }
}

class _SortBin {
  final String id, label, emoji, colorHex;
  const _SortBin({required this.id, required this.label, required this.emoji, required this.colorHex});
  factory _SortBin.fromMap(Map<String, dynamic> m) => _SortBin(
        id: m['id'] as String? ?? '',
        label: m['label'] as String? ?? '',
        emoji: m['emoji'] as String? ?? '📦',
        colorHex: m['colorHex'] as String? ?? '7C3AED',
      );
}

class _SortItem {
  final String id, text, emoji, correctBinId;
  final String? learningNote;
  const _SortItem({required this.id, required this.text, required this.emoji, required this.correctBinId, this.learningNote});
  factory _SortItem.fromMap(Map<String, dynamic> m) => _SortItem(
        id: m['id'] as String? ?? '',
        text: m['text'] as String? ?? '',
        emoji: m['emoji'] as String? ?? '📌',
        correctBinId: m['correctBinId'] as String? ?? '',
        learningNote: m['learningNote'] as String?,
      );
}
