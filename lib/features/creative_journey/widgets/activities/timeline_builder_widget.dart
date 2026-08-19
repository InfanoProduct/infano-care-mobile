import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

class TimelineBuilderWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const TimelineBuilderWidget({super.key, required this.content, required this.onCompleted});

  @override
  State<TimelineBuilderWidget> createState() => _TimelineBuilderWidgetState();
}

class _TimelineBuilderWidgetState extends State<TimelineBuilderWidget> {
  late List<Map<String, dynamic>> _cards;
  late List<Map<String, dynamic>?> _slots;
  bool _revealed = false;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    final raw = List<Map<String, dynamic>>.from(widget.content['cards'] as List? ?? []);
    _cards = List.from(raw)..shuffle();
    _slots = List.filled(raw.length, null);
  }

  bool get _allPlaced => _slots.every((s) => s != null);

  @override
  Widget build(BuildContext context) {
    if (_revealed) return _buildReveal();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
            ),
            child: Column(children: [
              const Text('🧩', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                widget.content['instruction'] as String? ?? 'Build your own timeline!',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark, height: 1.4),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Draggable source cards (2-column square tile format)
          Text('Cards to place:', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textMedium)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _cards.asMap().entries.map((e) {
                  final card = e.value;
                  final index = e.key;
                  final isPlaced = _slots.contains(card);

                  return SizedBox(
                    width: itemWidth,
                    child: Opacity(
                      opacity: isPlaced ? 0.35 : 1.0,
                      child: isPlaced
                          ? _CardChip(card: card, index: index, width: itemWidth)
                          : Draggable<Map<String, dynamic>>(
                              data: card,
                              feedback: Material(
                                color: Colors.transparent,
                                child: Transform.scale(
                                  scale: 1.05,
                                  child: _CardChip(card: card, index: index, isDragging: true, width: itemWidth),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.35,
                                child: _CardChip(card: card, index: index, width: itemWidth),
                              ),
                              child: _CardChip(card: card, index: index, width: itemWidth),
                            ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // Drop slots
          Text('Your Timeline:', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textMedium)),
          const SizedBox(height: 12),
          ...List.generate(_slots.length, (i) {
            final slot = _slots[i];
            final theme = _PastelTheme.getTheme(i);

            return DragTarget<Map<String, dynamic>>(
              onAcceptWithDetails: (details) {
                AppSoundService.instance.playPop();
                setState(() {
                  // Remove from any existing slot
                  final existingIdx = _slots.indexOf(details.data);
                  if (existingIdx != -1) _slots[existingIdx] = null;
                  // Place in new slot
                  _slots[i] = details.data;
                });
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return GestureDetector(
                  onTap: slot != null
                      ? () => setState(() => _slots[i] = null)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: const BoxConstraints(minHeight: 64),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: isHovering
                          ? theme.bg
                          : slot != null
                              ? theme.bg.withValues(alpha: 0.6)
                              : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isHovering
                            ? theme.accent
                            : slot != null
                                ? theme.border
                                : Colors.grey.shade200,
                        width: isHovering || slot != null ? 1.8 : 1.0,
                        style: slot == null && !isHovering ? BorderStyle.none : BorderStyle.solid,
                      ),
                      boxShadow: slot != null
                          ? [
                              BoxShadow(
                                color: theme.accent.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: slot != null
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: Center(child: Text(slot['emoji'] as String? ?? '⭐', style: const TextStyle(fontSize: 18))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  (slot['label'] as String? ?? '').replaceAll(RegExp(r'^STEP\s*\d+:\s*', caseSensitive: false), '').trim(),
                                  style: GoogleFonts.nunito(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textDark, height: 1.3),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.close_rounded, color: theme.accent, size: 18),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textLight),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(width: 60, height: 2, color: Colors.grey.shade200),
                                    const SizedBox(width: 8),
                                    Text(
                                      isHovering ? 'Drop card here!' : 'Drag a card here',
                                      style: GoogleFonts.nunito(fontSize: 12, color: isHovering ? AppColors.purple : AppColors.textLight, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            );
          }),

          const SizedBox(height: 20),
          if (_allPlaced)
            GestureDetector(
              onTap: () {
                AppSoundService.instance.playCorrect();
                setState(() => _revealed = true);
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
                child: Text('Reveal the Secret 🎉', textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, curve: Curves.elasticOut),
        ],
      ),
    );
  }

  Widget _buildReveal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 20),
        const Text('🎉', style: TextStyle(fontSize: 64))
            .animate().scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        Text('Any order works!', style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
          ),
          child: Text(
            widget.content['revealMessage'] as String? ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark, height: 1.6, fontWeight: FontWeight.w600),
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
        const SizedBox(height: 24),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isCompleting
                ? null
                : () {
                    setState(() => _isCompleting = true);
                    widget.onCompleted();
                  },
            borderRadius: BorderRadius.circular(20),
            child: Ink(
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
                  if (_isCompleting) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Unlocking Discovery Chest... 🗝️',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Collect 🪙 Coins',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
      ]),
    );
  }
}

// ── Pastel Card Theme ─────────────────────────────────────────────────────────

class _PastelTheme {
  final Color bg;
  final Color border;
  final Color accent;

  const _PastelTheme({
    required this.bg,
    required this.border,
    required this.accent,
  });

  static const List<_PastelTheme> themes = [
    _PastelTheme(
      bg: Color(0xFFEDE9FE), // Soft Lavender
      border: Color(0xFFA78BFA),
      accent: Color(0xFF7C3AED),
    ),
    _PastelTheme(
      bg: Color(0xFFFCE7F3), // Soft Rose
      border: Color(0xFFF472B6),
      accent: Color(0xFFDB2777),
    ),
    _PastelTheme(
      bg: Color(0xFFD1FAE5), // Soft Mint
      border: Color(0xFF34D399),
      accent: Color(0xFF059669),
    ),
    _PastelTheme(
      bg: Color(0xFFFEF3C7), // Soft Peach
      border: Color(0xFFFBBF24),
      accent: Color(0xFFD97706),
    ),
    _PastelTheme(
      bg: Color(0xFFDBEAFE), // Soft Sky Blue
      border: Color(0xFF60A5FA),
      accent: Color(0xFF2563EB),
    ),
  ];

  static _PastelTheme getTheme(int index) => themes[index % themes.length];
}

class _CardChip extends StatelessWidget {
  final Map<String, dynamic> card;
  final int index;
  final bool isDragging;
  final double? width;

  const _CardChip({
    required this.card,
    required this.index,
    this.isDragging = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _PastelTheme.getTheme(index);
    final String rawLabel = card['label'] as String? ?? '';
    final String label = rawLabel.replaceAll(RegExp(r'^STEP\s*\d+:\s*', caseSensitive: false), '').trim();

    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDragging ? theme.bg : theme.bg.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDragging ? theme.accent : theme.border,
          width: isDragging ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDragging
                ? theme.accent.withValues(alpha: 0.3)
                : theme.accent.withValues(alpha: 0.08),
            blurRadius: isDragging ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji circle badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.accent.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                card['emoji'] as String? ?? '⭐',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Complete Untruncated Card Label
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
