import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

/// MatchPairsWidget — "Match Terms & Solutions"
/// A gamified, interactive product-to-description matching activity with
/// side-by-side tap-to-connect layout, match animations, particle effects & sound feedback.
class MatchPairsWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const MatchPairsWidget({super.key, required this.content, required this.onCompleted});

  @override
  State<MatchPairsWidget> createState() => _MatchPairsWidgetState();
}

class _MatchPairsWidgetState extends State<MatchPairsWidget> {
  late ConfettiController _confettiController;
  late List<_ProductItem> _terms;
  late List<_DefinitionItem> _definitions;

  String? _selectedTermId;
  String? _selectedDefId;
  final Set<String> _matchedPairIds = {};

  bool _isChecking = false;
  String? _mismatchedTermId;
  String? _mismatchedDefId;
  String? _lastMatchedPairId;

  // Secondary layout option (false = Side-by-side Connect mode, true = Flip Card Grid)
  bool _isFlipMode = false;
  late List<_MatchCard> _cards;
  String? _firstSelectedCardUid;

  List<Map<String, dynamic>> get _pairs =>
      List<Map<String, dynamic>>.from(widget.content['pairs'] as List? ?? []);

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initMatcher();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _getAccurateEmoji(String term, String rawEmoji) {
    final t = term.toLowerCase();
    if (t.contains('regular pad') || t.contains('day pad')) return '🌸';
    if (t.contains('night pad') || t.contains('overnight')) return '🌙';
    if (t.contains('tampon')) return '🧵';
    if (t.contains('menstrual cup') || (t.contains('cup') && !t.contains('coffee'))) return '🍷';
    if (t.contains('period underwear') || t.contains('underwear')) return '🩲';
    if (t.contains('panty liner') || t.contains('liner')) return '🪶';
    return (rawEmoji.isNotEmpty && rawEmoji != '❓' && rawEmoji != '☕' && rawEmoji != '🔵' && rawEmoji != '🩹')
        ? rawEmoji
        : '🩸';
  }

  void _initMatcher() {
    // 1. Build terms & definitions lists for Connect mode
    final termsList = <_ProductItem>[];
    final defsList = <_DefinitionItem>[];

    for (final pair in _pairs) {
      final id = pair['id'] as String? ?? '';
      final rawEmoji = pair['emoji'] as String? ?? '';
      final term = (pair['term'] ?? pair['left'] ?? '') as String;
      final definition = (pair['definition'] ?? pair['right'] ?? '') as String;
      final accurateEmoji = _getAccurateEmoji(term, rawEmoji);

      termsList.add(_ProductItem(id: id, emoji: accurateEmoji, term: term));
      defsList.add(_DefinitionItem(id: id, definition: definition));
    }

    termsList.shuffle();
    defsList.shuffle();

    _terms = termsList;
    _definitions = defsList;

    // 2. Build cards list for Flip Grid mode
    final cards = <_MatchCard>[];
    for (final pair in _pairs) {
      final id = pair['id'] as String? ?? '';
      final rawEmoji = pair['emoji'] as String? ?? '';
      final term = (pair['term'] ?? pair['left'] ?? '') as String;
      final definition = (pair['definition'] ?? pair['right'] ?? '') as String;
      final accurateEmoji = _getAccurateEmoji(term, rawEmoji);

      cards.add(_MatchCard(
        uid: '${id}_term',
        pairId: id,
        text: term,
        emoji: accurateEmoji,
        isDefinition: false,
      ));
      cards.add(_MatchCard(
        uid: '${id}_def',
        pairId: id,
        text: definition,
        emoji: '💡',
        isDefinition: true,
      ));
    }
    cards.shuffle();
    _cards = cards;
  }

  // ── Tap Handlers for Side-by-Side Connect Mode ────────────────────────────

  void _onTermTap(_ProductItem item) {
    if (_isChecking || _matchedPairIds.contains(item.id)) return;
    AppSoundService.instance.playPop();

    setState(() {
      if (_selectedTermId == item.id) {
        _selectedTermId = null;
      } else {
        _selectedTermId = item.id;
        _mismatchedTermId = null;
        _mismatchedDefId = null;
      }
    });

    _checkConnectMatch();
  }

  void _onDefinitionTap(_DefinitionItem item) {
    if (_isChecking || _matchedPairIds.contains(item.id)) return;
    AppSoundService.instance.playPop();

    setState(() {
      if (_selectedDefId == item.id) {
        _selectedDefId = null;
      } else {
        _selectedDefId = item.id;
        _mismatchedTermId = null;
        _mismatchedDefId = null;
      }
    });

    _checkConnectMatch();
  }

  void _checkConnectMatch() {
    if (_selectedTermId == null || _selectedDefId == null) return;

    final termId = _selectedTermId!;
    final defId = _selectedDefId!;

    if (termId == defId) {
      // Correct Match!
      AppSoundService.instance.playCorrect();
      HapticFeedback.mediumImpact();

      setState(() {
        _matchedPairIds.add(termId);
        _lastMatchedPairId = termId;
        _selectedTermId = null;
        _selectedDefId = null;
      });

      // Synchronize flip grid cards state if matched
      for (final card in _cards) {
        if (card.pairId == termId) {
          card.isMatched = true;
          card.isFlipped = true;
        }
      }

      _checkAllCompleted();
    } else {
      // Mismatch!
      AppSoundService.instance.playIncorrect();
      HapticFeedback.heavyImpact();

      _isChecking = true;
      setState(() {
        _mismatchedTermId = termId;
        _mismatchedDefId = defId;
      });

      Future.delayed(650.ms, () {
        if (!mounted) return;
        setState(() {
          _selectedTermId = null;
          _selectedDefId = null;
          _mismatchedTermId = null;
          _mismatchedDefId = null;
          _isChecking = false;
        });
      });
    }
  }

  // ── Tap Handlers for Flip Grid Mode ───────────────────────────────────────

  void _onFlipCardTap(_MatchCard card) {
    if (_isChecking || card.isFlipped || card.isMatched) return;

    AppSoundService.instance.playPop();
    setState(() => card.isFlipped = true);

    if (_firstSelectedCardUid == null) {
      _firstSelectedCardUid = card.uid;
      return;
    }

    final first = _cards.firstWhere((c) => c.uid == _firstSelectedCardUid);
    _firstSelectedCardUid = null;

    if (first.pairId == card.pairId && first.uid != card.uid) {
      // Match!
      AppSoundService.instance.playCorrect();
      HapticFeedback.mediumImpact();

      setState(() {
        first.isMatched = true;
        card.isMatched = true;
        _matchedPairIds.add(card.pairId);
        _lastMatchedPairId = card.pairId;
      });

      _checkAllCompleted();
    } else {
      // No match — flip back with sound & shake
      AppSoundService.instance.playIncorrect();
      HapticFeedback.heavyImpact();

      _isChecking = true;
      Future.delayed(750.ms, () {
        if (!mounted) return;
        setState(() {
          first.isFlipped = false;
          card.isFlipped = false;
          _isChecking = false;
        });
      });
    }
  }

  void _checkAllCompleted() {
    if (_matchedPairIds.length == _pairs.length) {
      _confettiController.play();
      AppSoundService.instance.playFanfare();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _matchedPairIds.length == _pairs.length;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with gradient and mode toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF1F2), Color(0xFFFDF2F8), Color(0xFFF5F3FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFBCFE8), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCE7F3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF472B6)),
                          ),
                          child: const Text('✨', style: TextStyle(fontSize: 26)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.content['title'] as String? ?? 'Match Skin Terms & Solutions 🧩',
                                style: GoogleFonts.nunito(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF9D174D),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _isFlipMode
                                    ? 'Tap a card to flip and find its matching pair!'
                                    : (widget.content['instruction'] as String? ??
                                        'Tap a term on the left, then tap its solution on the right!'),
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: AppColors.textMedium,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Layout Mode Switcher pill button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            AppSoundService.instance.playPop();
                            setState(() => _isFlipMode = !_isFlipMode);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isFlipMode ? const Color(0xFF7C3AED) : const Color(0xFFDB2777),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isFlipMode ? const Color(0xFF7C3AED) : const Color(0xFFDB2777))
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isFlipMode ? Icons.grid_view_rounded : Icons.swap_horiz_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isFlipMode ? 'Switch to Connect' : 'Switch to Memory',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Progress Bar Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Matched ${_matchedPairIds.length} of ${_pairs.length}',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Text('💖', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '${_pairs.length - _matchedPairIds.length} left',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _pairs.isNotEmpty ? _matchedPairIds.length / _pairs.length : 0,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFFBCFE8),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDB2777)),
                ),
              ),
              const SizedBox(height: 18),

              // Main Activity Body: Side-by-Side Matcher OR Flip Card Grid
              if (!_isFlipMode)
                _buildSideBySideConnectView()
              else
                _buildFlipCardGridView(),

              // Completion Card Banner
              if (isCompleted) ...[
                const SizedBox(height: 24),
                _buildCompletionCard(),
              ],
            ],
          ),
        ),

        // Confetti Overlay
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 35,
          gravity: 0.25,
        ),
      ],
    );
  }

  // ── 1. Side-by-Side Connect View ───────────────────────────────────────────

  Widget _buildSideBySideConnectView() {
    return Column(
      children: [
        // Helper hint strip
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👉', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                _selectedTermId != null && _selectedDefId == null
                    ? 'Now tap a matching description on the right!'
                    : (_selectedDefId != null && _selectedTermId == null
                        ? 'Now tap a matching product on the left!'
                        : 'Tap a Product card and its Description card to connect!'),
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6D28D9),
                ),
              ),
            ],
          ),
        ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Product Terms
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE7F3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'PRODUCT',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF9D174D),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ..._terms.map((item) {
                    final isMatched = _matchedPairIds.contains(item.id);
                    final isSelected = _selectedTermId == item.id;
                    final isMismatched = _mismatchedTermId == item.id;

                    return _buildProductTile(
                      item: item,
                      isMatched: isMatched,
                      isSelected: isSelected,
                      isMismatched: isMismatched,
                      onTap: () => _onTermTap(item),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Right Column: Definitions
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'DESCRIPTION',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF5B21B6),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ..._definitions.map((item) {
                    final isMatched = _matchedPairIds.contains(item.id);
                    final isSelected = _selectedDefId == item.id;
                    final isMismatched = _mismatchedDefId == item.id;

                    return _buildDefinitionTile(
                      item: item,
                      isMatched: isMatched,
                      isSelected: isSelected,
                      isMismatched: isMismatched,
                      onTap: () => _onDefinitionTap(item),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductTile({
    required _ProductItem item,
    required bool isMatched,
    required bool isSelected,
    required bool isMismatched,
    required VoidCallback onTap,
  }) {
    Color bgColor = isMatched
        ? const Color(0xFFECFDF5)
        : (isMismatched
            ? const Color(0xFFFEE2E2)
            : (isSelected ? const Color(0xFFFCE7F3) : Colors.white));

    Color borderColor = isMatched
        ? const Color(0xFF10B981)
        : (isMismatched
            ? const Color(0xFFEF4444)
            : (isSelected ? const Color(0xFFDB2777) : const Color(0xFFFBCFE8)));

    Widget child = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isSelected || isMatched ? 2.5 : 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: isSelected ? 0.3 : 0.1),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.term,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isMatched ? const Color(0xFF047857) : AppColors.textDark,
                    ),
                  ),
                ),
                if (isMatched)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                  )
                else if (isSelected)
                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFFDB2777), size: 16),
              ],
            ),
            if (isMatched && _lastMatchedPairId == item.id) ...[
              const SizedBox(height: 4),
              Text(
                '✨ MATCHED!',
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF059669),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isMismatched) {
      return child.animate().shake(duration: 450.ms, hz: 6).tint(color: const Color(0xFFEF4444), duration: 200.ms);
    }
    if (isMatched && _lastMatchedPairId == item.id) {
      return child.animate().scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 250.ms,
            curve: Curves.easeOutBack,
          );
    }
    if (isSelected) {
      return child.animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.03, 1.03),
            duration: 600.ms,
          );
    }
    return child;
  }

  Widget _buildDefinitionTile({
    required _DefinitionItem item,
    required bool isMatched,
    required bool isSelected,
    required bool isMismatched,
    required VoidCallback onTap,
  }) {
    Color bgColor = isMatched
        ? const Color(0xFFECFDF5)
        : (isMismatched
            ? const Color(0xFFFEE2E2)
            : (isSelected ? const Color(0xFFEDE9FE) : Colors.white));

    Color borderColor = isMatched
        ? const Color(0xFF10B981)
        : (isMismatched
            ? const Color(0xFFEF4444)
            : (isSelected ? const Color(0xFF7C3AED) : const Color(0xFFDDD6FE)));

    Widget child = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isSelected || isMatched ? 2.5 : 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: isSelected ? 0.3 : 0.1),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.definition,
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: isMatched ? FontWeight.w700 : FontWeight.w600,
                      color: isMatched ? const Color(0xFF047857) : AppColors.textMedium,
                      height: 1.3,
                    ),
                  ),
                ),
                if (isMatched) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    if (isMismatched) {
      return child.animate().shake(duration: 450.ms, hz: 6).tint(color: const Color(0xFFEF4444), duration: 200.ms);
    }
    if (isMatched && _lastMatchedPairId == item.id) {
      return child.animate().scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 250.ms,
            curve: Curves.easeOutBack,
          );
    }
    if (isSelected) {
      return child.animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.03, 1.03),
            duration: 600.ms,
          );
    }
    return child;
  }

  // ── 2. Flip Card Grid View ──────────────────────────────────────────────────

  Widget _buildFlipCardGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemCount: _cards.length,
      itemBuilder: (context, i) {
        final card = _cards[i];
        return _MatchCardWidget(
          card: card,
          onTap: () => _onFlipCardTap(card),
          delay: i * 50,
        );
      },
    );
  }

  // ── 3. Completion Celebration Card ─────────────────────────────────────────

  Widget _buildCompletionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDF2F8), Color(0xFFFFF1F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFBCFE8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDB2777).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          Text(
            'All Pairs Matched!',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.content['completionMessage'] as String? ??
                'You matched them all! Now you know exactly what each period product does!',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              color: const Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              AppSoundService.instance.playPop();
              HapticFeedback.selectionClick();
              widget.onCompleted();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE7F3),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFBCFE8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDB2777).withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue Journey • Collect 🪙 Coins',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFDB2777),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFFBE185D), size: 19),
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.02, 1.02),
                duration: 800.ms,
              ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.elasticOut);
  }
}

// ── Models & Card Helpers ───────────────────────────────────────────────────

class _ProductItem {
  final String id;
  final String emoji;
  final String term;

  _ProductItem({required this.id, required this.emoji, required this.term});
}

class _DefinitionItem {
  final String id;
  final String definition;

  _DefinitionItem({required this.id, required this.definition});
}

class _MatchCard {
  final String uid;
  final String pairId;
  final String text;
  final String emoji;
  final bool isDefinition;
  bool isFlipped = false;
  bool isMatched = false;

  _MatchCard({
    required this.uid,
    required this.pairId,
    required this.text,
    required this.emoji,
    required this.isDefinition,
  });
}

class _MatchCardWidget extends StatelessWidget {
  final _MatchCard card;
  final VoidCallback onTap;
  final int delay;

  const _MatchCardWidget({required this.card, required this.onTap, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    final showFront = card.isFlipped || card.isMatched;

    Color bgColor = showFront
        ? (card.isMatched ? const Color(0xFFECFDF5) : const Color(0xFFFCE7F3))
        : const Color(0xFFF5F3FF);
    Color borderColor = showFront
        ? (card.isMatched ? const Color(0xFF10B981) : const Color(0xFFDB2777))
        : const Color(0xFFDDD6FE);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: showFront
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (card.emoji.isNotEmpty)
                    Text(card.emoji, style: const TextStyle(fontSize: 22)),
                  if (card.emoji.isNotEmpty) const SizedBox(height: 4),
                  if (card.isMatched)
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                  const SizedBox(height: 4),
                  Text(
                    card.text,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: card.isDefinition ? 10.5 : 12,
                      fontWeight: card.isDefinition ? FontWeight.w600 : FontWeight.w900,
                      color: card.isMatched ? const Color(0xFF047857) : AppColors.textDark,
                      height: 1.25,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 26)),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to reveal',
                    style: GoogleFonts.nunito(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 300.ms).slideY(begin: 0.08);
  }
}
