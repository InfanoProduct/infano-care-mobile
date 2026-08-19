import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';
import 'package:page_flip/page_flip.dart';

/// Modern Flip Book Story Reader (Node 1 — Story Book)
class StoryComicScreen extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const StoryComicScreen({
    super.key,
    required this.content,
    required this.onCompleted,
  });

  @override
  State<StoryComicScreen> createState() => _StoryComicScreenState();
}

class _StoryComicScreenState extends State<StoryComicScreen> {
  final GlobalKey<PageFlipWidgetState> _pageFlipKey = GlobalKey<PageFlipWidgetState>();
  int _currentPage = 0;

  List<Map<String, dynamic>> get pages =>
      List<Map<String, dynamic>>.from(widget.content['pages'] as List? ?? []);

  bool get isLastPage => _currentPage >= pages.length - 1;

  void _nextPage() {
    if (_currentPage == pages.length - 1) {
      AppSoundService.instance.playBunchOfCoinsSound();
      widget.onCompleted();
    } else {
      _pageFlipKey.currentState?.nextPage();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageFlipKey.currentState?.previousPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) {
      return Center(
        child: GestureDetector(
          onTap: widget.onCompleted,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Story coming soon!',
              style: GoogleFonts.nunito(fontSize: 18, color: AppColors.textMedium),
            ),
          ),
        ),
      );
    }

    final bookPages = pages.asMap().entries.map((e) {
      return _BookPageItem(
        page: e.value,
        pageIndex: e.key,
      );
    }).toList();

    return Column(
      children: [
        // ── TOP PAGE INDICATOR DOTS ──────────────────────────────────────────
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pages.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 24 : 7,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.purple : AppColors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),

        // ── FLIP BOOK CONTAINER (Supports Horizontal & Vertical Flipping) ───
        Expanded(
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < -200) {
                  // Drag UP -> Flip Next Page
                  _nextPage();
                } else if (details.primaryVelocity! > 200) {
                  // Drag DOWN -> Flip Previous Page
                  _previousPage();
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8E2D5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: PageFlipWidget(
                  key: _pageFlipKey,
                  backgroundColor: Colors.white,
                  cutoffForward: 0.8,
                  cutoffPrevious: 0.1,
                  duration: const Duration(milliseconds: 450),
                  onPageFlipped: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: bookPages,
                ),
              ),
            ),
          ),
        ),

        // ── BOTTOM NAVIGATION BAR ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              // Previous Page Button
              if (_currentPage > 0)
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: _previousPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.purple, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            'Prev',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_currentPage > 0) const SizedBox(width: 10),

              // Next Page / Collect XP Button
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastPage ? 'Collect 🪙 Coins' : 'Turn Page',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isLastPage ? Icons.stars_rounded : Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── BOOK PAGE ITEM (Full Edge-to-Edge Image or Panel Content) ───────────────

class _BookPageItem extends StatelessWidget {
  final Map<String, dynamic> page;
  final int pageIndex;

  const _BookPageItem({
    required this.page,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = page['image'] as String?;
    final panels = List<Map<String, dynamic>>.from(page['panels'] as List? ?? []);

    if (imagePath != null && imagePath.isNotEmpty) {
      return SizedBox.expand(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 2.5,
          child: Image.asset(
            imagePath,
            fit: BoxFit.fill,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  'Page ${pageIndex + 1}',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...panels.asMap().entries.map((e) {
            final panel = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _ComicPanel(panel: panel),
            ).animate().fadeIn(delay: (e.key * 100).ms, duration: 350.ms);
          }),
        ],
      ),
    );
  }
}

// ── COMIC PANEL COMPONENT ───────────────────────────────────────────────────

class _ComicPanel extends StatelessWidget {
  final Map<String, dynamic> panel;
  const _ComicPanel({required this.panel});

  @override
  Widget build(BuildContext context) {
    final description = panel['description'] as String? ?? '';
    final dialogue = panel['dialogue'] as List? ?? [];
    final letter = panel['letter'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                description,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMedium,
                  height: 1.4,
                ),
              ),
            ),

          if (letter != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.5)),
              ),
              child: Text(
                '"$letter"',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF92400E),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          if (dialogue.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...dialogue.map((d) => _DialogueBubble(dialogue: d as Map<String, dynamic>)),
          ],
        ],
      ),
    );
  }
}

class _DialogueBubble extends StatelessWidget {
  final Map<String, dynamic> dialogue;
  const _DialogueBubble({required this.dialogue});

  @override
  Widget build(BuildContext context) {
    final character = dialogue['character'] as String? ?? '';
    final text = dialogue['text'] as String? ?? '';
    final type = dialogue['type'] as String? ?? 'speech';
    final isGigi = character == 'Gigi';
    final isThought = type == 'thought';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isGigi
                    ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
                    : [AppColors.pink, AppColors.purple],
              ),
            ),
            child: Center(
              child: Text(
                isGigi ? '✨' : character.isNotEmpty ? character[0] : '?',
                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character,
                  style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textLight),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isGigi ? const Color(0xFFFEF9C3) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: isGigi
                          ? const Color(0xFFFBBF24).withValues(alpha: 0.4)
                          : AppColors.purple.withValues(alpha: 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
                    ],
                  ),
                  child: Text(
                    isThought ? '💭 $text' : text,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textDark,
                      height: 1.45,
                      fontStyle: isThought ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
