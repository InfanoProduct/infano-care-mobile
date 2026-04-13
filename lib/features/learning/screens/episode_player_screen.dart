import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:page_flip/page_flip.dart';
import '../models/learning_models.dart';

import '../application/episode_player_bloc.dart';
import '../../../core/theme/app_theme.dart';

// ────────────────────────────────────────────────────────────
//  Segment metadata – used by nav bar and header
// ────────────────────────────────────────────────────────────
const _kSegments = [
  _SegmentMeta('🪝', 'Hook'),
  _SegmentMeta('📖', 'Story'),
  _SegmentMeta('✅', 'Quiz'),
  _SegmentMeta('💭', 'Learning Journal'),
  _SegmentMeta('🎯', 'Summary'),
];

class _SegmentMeta {
  final String icon;
  final String label;
  const _SegmentMeta(this.icon, this.label);
}

// ────────────────────────────────────────────────────────────
//  Root screen
// ────────────────────────────────────────────────────────────
class EpisodePlayerScreen extends StatefulWidget {
  final Episode episode;
  const EpisodePlayerScreen({super.key, required this.episode});

  @override
  State<EpisodePlayerScreen> createState() => _EpisodePlayerScreenState();
}

class _EpisodePlayerScreenState extends State<EpisodePlayerScreen> {
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    // Defer PageController creation until loaded state to set correct initialPage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EpisodePlayerBloc>().add(EpisodePlayerEvent.loadEpisode(widget.episode.id));
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _showCompletionDialog(BuildContext context, int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)).animate().scale(curve: Curves.elasticOut),
            const SizedBox(height: 16),
            const Text('Episode Complete!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('+$points XP earned', style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  // First close the dialog
                  Navigator.of(context).pop();
                  // Then close the player screen and return 'true' to trigger refresh
                  context.pop(true);
                },
                child: const Text('Continue to Path', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EpisodePlayerBloc, EpisodePlayerState>(
      listener: (context, state) {
        state.maybeWhen(
          loaded: (episode, index, correct, answered, mode, content, isCompleting, completedSegmentIndices, history, segmentPoints) {
            final controller = _pageController;
            if (controller != null && controller.hasClients && controller.page?.round() != index) {
              controller.animateToPage(index, duration: 600.ms, curve: Curves.easeInOutCubic);
            }
          },
          completed: (points, breakdown) => _showCompletionDialog(context, points),
          error: (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))),
          orElse: () {},
        );
      },
      builder: (context, state) {
        return state.when(
          initial: () {
            // Trigger load if we're in initial state (e.g. after hot reload)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<EpisodePlayerBloc>().add(EpisodePlayerEvent.loadEpisode(widget.episode.id));
            });
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (msg) => Scaffold(body: Center(child: Text(msg))),
          completed: (_, __) => const Scaffold(body: SizedBox.shrink()),
          loaded: (Episode episode, int index, int correct, int answered, String mode, String? content, bool isCompleting, List<int> completedIndices, Map<String, dynamic> history, Map<String, int> segmentPoints) {
            final isHook = index == 0;
            final activePageController = _pageController ??= PageController(initialPage: index);
            
            return Scaffold(
              backgroundColor: isHook ? Colors.transparent : AppColors.background,
              endDrawerEnableOpenDragGesture: false,
              endDrawer: _SegmentDrawer(
                episode: episode,
                currentIndex: index,
                completedIndices: completedIndices,
                segmentPoints: segmentPoints,
              ),
              body: Stack(
                children: [
                  PageView(
                    controller: activePageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _HookSegment(episode: episode),
                      _StorySegment(episode: episode),
                      _QuizSegment(episode: episode),
                      _ReflectionSegment(episode: episode),
                      _SummarySegment(episode: episode),
                    ],
                  ),
                  // Global TopBar providing escape and menu for all segments
                  _TopBar(
                    episode: episode,
                    index: index,
                    isHook: isHook,
                    completedIndices: completedIndices,
                    segmentPoints: segmentPoints,
                  ),
                  // Loading overlay
                  if (isCompleting)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Top bar (all segments except Summary)
// ────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final Episode episode;
  final int index;
  final bool isHook;
  final List<int> completedIndices;
  final Map<String, int> segmentPoints;
  const _TopBar({
    required this.episode,
    required this.index,
    required this.isHook,
    required this.completedIndices,
    required this.segmentPoints,
  });

  int get _earnedXP {
    final keys = ['story', 'knowledgeCheck', 'reflection'];
    int total = 0;
    for (int i = 0; i < completedIndices.length; i++) {
      final idx = completedIndices[i];
      if (idx >= 1 && idx <= 3) total += segmentPoints[keys[idx - 1]] ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final onDark = isHook;
    final bgColor = onDark ? Colors.transparent : Colors.white;
    final iconColor = onDark ? Colors.white : AppColors.textDark;
    final titleColor = onDark ? Colors.white : AppColors.textDark;
    final subtitleColor = onDark ? Colors.white70 : AppColors.purple;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 120, // Explicit height to prevent hit-test blocking
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 6,
          left: 4,
          right: 12,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: onDark
              ? []
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 20, color: iconColor),
              onPressed: () => context.pop(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: titleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _kSegments[index].label,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Live XP pill
            if (_earnedXP > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: onDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.bloom.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(
                      '$_earnedXP XP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: onDark ? Colors.white : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
            // Hamburger menu
            Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openEndDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: onDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.menu_rounded, color: iconColor, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Side Segment Drawer
// ────────────────────────────────────────────────────────────
class _SegmentDrawer extends StatelessWidget {
  final Episode episode;
  final int currentIndex;
  final List<int> completedIndices;
  final Map<String, int> segmentPoints;

  const _SegmentDrawer({
    required this.episode,
    required this.currentIndex,
    required this.completedIndices,
    required this.segmentPoints,
  });

  static const _pointKeys = ['', 'story', 'knowledgeCheck', 'reflection', 'summary'];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF4C1D95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🧬', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Gigi',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      episode.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bloom.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.bloom.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '⚡ ${episode.points} XP total',
                        style: const TextStyle(
                          color: AppColors.bloom,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: Colors.white.withValues(alpha: 0.15), height: 24),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 8),
                child: Text(
                  'ACTIVITIES',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: _kSegments.length,
                  itemBuilder: (ctx, i) {
                    final meta = _kSegments[i];
                    final isActive = i == currentIndex;
                    final isCompleted = completedIndices.contains(i);
                    final isUnlocked = i == 0 || completedIndices.contains(i - 1);
                    final isLocked = !isUnlocked;
                    final pts = i > 0 ? (segmentPoints[_pointKeys[i]] ?? 0) : 0;

                    return GestureDetector(
                      onTap: () {
                        if (!isLocked) {
                          Navigator.of(context).pop();
                          context.read<EpisodePlayerBloc>().add(
                                EpisodePlayerEvent.jumpToSegment(i),
                              );
                        }
                      },
                      child: AnimatedContainer(
                        duration: 200.ms,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.18)
                              : isCompleted
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: isActive
                              ? Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Status icon
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.purple
                                    : isCompleted
                                        ? AppColors.success.withValues(alpha: 0.25)
                                        : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: isLocked
                                    ? Icon(Icons.lock_rounded,
                                        size: 16, color: Colors.white.withValues(alpha: 0.3))
                                    : isCompleted && !isActive
                                        ? const Icon(Icons.check_rounded,
                                            size: 18, color: AppColors.success)
                                        : Text(meta.icon,
                                            style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meta.label,
                                    style: TextStyle(
                                      color: isLocked
                                          ? Colors.white38
                                          : Colors.white,
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (pts > 0)
                                    Text(
                                      '+$pts XP',
                                      style: TextStyle(
                                        color: isCompleted
                                            ? AppColors.success.withValues(alpha: 0.8)
                                            : Colors.white38,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isLocked)
                              Icon(Icons.lock_outline_rounded,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.25))
                            else if (isCompleted && !isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Done',
                                    style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_rounded,
                            size: 18, color: Colors.white.withValues(alpha: 0.6)),
                        const SizedBox(width: 8),
                        Text(
                          'Back to Dashboard',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Segment 1: Hook
// ────────────────────────────────────────────────────────────
class _HookSegment extends StatefulWidget {
  final Episode episode;
  const _HookSegment({required this.episode});

  @override
  State<_HookSegment> createState() => _HookSegmentState();
}

class _HookSegmentState extends State<_HookSegment> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _showCTA = false;
  late final AnimationController _progressController;

  static const _secondsPerPhrase = 5;

  final List<String> _narrativeTexts = [
    "Meera just grew 4 centimeters in three months.\nHer best friend Nadia hasn’t changed in eight.",
    "Same age. Same life. Same everything… so why does it suddenly feel like they’re on completely different paths?",
    "Is something wrong with Meera? Or is Nadia falling behind?\nOr… is there something no one ever explained about growing up?",
    "What if puberty doesn’t follow one timeline but many?",
    "In this story, you’ll uncover what’s really happening inside your body, why changes feel confusing, and why comparing yourself might be the biggest mistake of all.",
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _narrativeTexts.length * _secondsPerPhrase),
    );

    _progressController.addListener(() {
      final newIndex = (_progressController.value * _narrativeTexts.length).floor().clamp(0, _narrativeTexts.length - 1);
      if (newIndex != _currentIndex) {
        setState(() => _currentIndex = newIndex);
      }
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showCTA = true);
      }
    });

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }



  void _skip() {
    _progressController.stop();
    setState(() {
      _currentIndex = _narrativeTexts.length - 1;
      _showCTA = true;
    });
  }

  void _advance() {
    context.read<EpisodePlayerBloc>().add(const EpisodePlayerEvent.nextSegment());
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-screen Background Image
          Image.asset(
            'assets/images/hook.jpeg',
            fit: BoxFit.cover,
          ),

          // 2. Bottom Gradient Shadow for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          // 3. Top Section (Phrase Progress) — Moved down to avoid global TopBar clash
          Positioned(
            top: 130, // Clear of TopBar (height: 120)
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) => LinearProgressIndicator(
                        value: _showCTA ? 1.0 : _progressController.value,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (!_showCTA)
                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          // 4. Narrative Text or CTA
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 100,
            left: 32,
            right: 32,
            child: AnimatedSwitcher(
              duration: 1500.ms,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.center,
                children: [...previous, if (current != null) current],
              ),
              transitionBuilder: (child, animation) {
                final isIncoming = child.key == ValueKey(_showCTA ? 'cta' : _narrativeTexts[_currentIndex]);
                
                // Sequential interval: Phase 1 (Exit 0-0.4), Phase 2 (Gap 0.4-0.6), Phase 3 (Entry 0.6-1.0)
                final sequence = CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.6, 1.0, curve: Curves.easeInOutQuart),
                );

                return FadeTransition(
                  opacity: sequence,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      // Entry: slide from bottom (0.5) to center (0)
                      // Exit: slide from center (0) to top (-0.5) due to AnimatedSwitcher reversal
                      begin: isIncoming ? const Offset(0, 0.5) : const Offset(0, -0.5),
                      end: Offset.zero,
                    ).animate(sequence),
                    child: child,
                  ),
                );
              },
              child: _showCTA
                  ? _buildCTA(context)
                  : _buildNarrativeText(_narrativeTexts[_currentIndex]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrativeText(String text) {
    return Container(
      key: ValueKey(text),
      constraints: const BoxConstraints(minHeight: 180),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.4,
          letterSpacing: 0.3,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
            Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildCTA(BuildContext context) {
    return Column(
      key: const ValueKey('cta'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF4C1D95).withValues(alpha: 0.9), // Deep purple like design
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _advance,
              borderRadius: BorderRadius.circular(30),
              child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Flexible(
                  child: Text(
                    'Tap to continue—and discover the truth about your timeline.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ).animate().scale(curve: Curves.elasticOut, duration: 800.ms).shimmer(delay: 2.seconds, duration: 2.seconds),
      ],
    );
  }
}


// ────────────────────────────────────────────────────────────
//  Segment 2: Story (Flip Book Format)
// ────────────────────────────────────────────────────────────
class _StorySegment extends StatefulWidget {
  final Episode episode;
  const _StorySegment({required this.episode});

  @override
  State<_StorySegment> createState() => _StorySegmentState();
}

class _StorySegmentState extends State<_StorySegment> {
  final _controller = GlobalKey<PageFlipWidgetState>();
  int _currentPage = 0;
  late final List<String> _pageAssets;

  @override
  void initState() {
    super.initState();
    _pageAssets = _parsePages();
  }

  List<String> _parsePages() {
    try {
      final content = widget.episode.content as Map<String, dynamic>?;
      final pages = content?['story']?['pages'] as List<dynamic>?;
      if (pages != null && pages.isNotEmpty) {
        return List<String>.from(pages);
      }
    } catch (_) {}
    // Fallback
    return List.generate(7, (i) => 'assets/images/book/page (${i + 1}).png');
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 100;
    final pageCount = _pageAssets.length;
    
    final pages = List.generate(pageCount, (index) {
      return _buildImagePage(_pageAssets[index], topPadding);
    });

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF1E1B4B)],
        ),
      ),
      child: Stack(
        children: [
          // The Book
          Center(
            child: PageFlipWidget(
              key: _controller,
              backgroundColor: Colors.transparent,
              onPageFlipped: (index) {
                setState(() => _currentPage = index);
              },
              children: pages,
            ),
          ),
          
          // Page Indicators
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pages.length, (index) {
                    final active = index == _currentPage;
                    return AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: active ? 20 : 6,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  'Page ${_currentPage + 1} of $pageCount',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          
          // Swipe Hint
          if (_currentPage == 0)
            Positioned(
              right: 30,
              bottom: 120,
              child: const Column(
                children: [
                  Icon(Icons.swipe_left_rounded, color: Colors.white70, size: 32),
                  SizedBox(height: 8),
                  Text('Swipe to flip', 
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ).animate(onPlay: (controller) => controller.repeat())
               .shimmer(duration: 2.seconds)
               .moveX(begin: 0, end: -15, curve: Curves.easeInOutSine),
            ),

          // Continue Button (Only on last page)
          if (_currentPage == pageCount - 1)
            Positioned(
              bottom: 100,
              left: 40,
              right: 40,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4C1D95),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 10,
                    shadowColor: Colors.black45,
                  ),
                  onPressed: () => context.read<EpisodePlayerBloc>().add(const EpisodePlayerEvent.nextSegment()),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('CONTINUE TO CHECK', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePage(String assetPath, double topPadding) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ────────────────────────────────────────────────────────────
//  Segment 3: Quiz (Gamified & Thoughtful)
// ────────────────────────────────────────────────────────────
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String feedback;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.feedback,
  });
}

class _QuizSegment extends StatefulWidget {
  final Episode episode;
  const _QuizSegment({required this.episode});

  @override
  State<_QuizSegment> createState() => _QuizSegmentState();
}

class _QuizSegmentState extends State<_QuizSegment> {
  int _currentQuestionIndex = 0;
  bool _allCorrectConfetti = false;
  late final List<QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _questions = _parseQuestions();
    
    // 1050: Removed resume logic to satisfy user request: "always show 1st quiz"
    _currentQuestionIndex = 0;
    
    final state = context.read<EpisodePlayerBloc>().state;
    state.maybeMap(
      loaded: (s) {
        if (s.questionsAnswered >= _questions.length) {
          if (s.correctAnswers == _questions.length) {
            _allCorrectConfetti = true;
          }
        }
      },
      orElse: () {},
    );
  }

  List<QuizQuestion> _parseQuestions() {
    try {
      final content = widget.episode.content as Map<String, dynamic>?;
      final qData = content?['knowledgeCheck']?['questions'] as List<dynamic>?;
      if (qData != null && qData.isNotEmpty) {
        return qData.map((q) => QuizQuestion(
          question: q['question'] ?? '',
          options: List<String>.from(q['options'] ?? []),
          correctIndex: q['correctIndex'] ?? 0,
          feedback: q['feedback'] ?? '',
        )).toList();
      }
    } catch (e) {
      debugPrint('Error parsing quiz questions: $e');
    }
    
    // Fallback to original hardcoded questions if backend data is missing or malformed
    return const [
      QuizQuestion(
        question: "Which of the following best describes puberty?",
        options: [
          "It starts at the same age for everyone.",
          "It begins only after age 12.",
          "It happens within a wide age range, unique to each person.",
          "It depends only on lifestyle choices.",
        ],
        correctIndex: 2,
        feedback: "Puberty is a range (8–16), not a fixed timeline.",
      ),
      QuizQuestion(
        question: "Meera starts noticing body changes at 12, while her friend hasn’t yet. What is the most accurate interpretation?",
        options: [
          "Meera is developing too early",
          "Her friend is developing too late",
          "One of them may have a health issue",
          "They are on different but normal timelines",
        ],
        correctIndex: 3,
        feedback: "Different timelines = normal variation, not a problem.",
      ),
      QuizQuestion(
        question: "Which thought pattern is most likely to create unnecessary stress during puberty?",
        options: [
          "“Bodies change at different times”",
          "“I wonder why this is happening”",
          "“Everyone else is normal except me”",
          "“This might be part of growing up”",
        ],
        correctIndex: 2,
        feedback: "Isolation thinking increases anxiety—even when things are normal.",
      ),
    ];
  }

  void _handleAnswer(int index, bool alreadyAnswered) {
    if (alreadyAnswered) return;

    final isCorrect = index == _questions[_currentQuestionIndex].correctIndex;
    
    // Send a single atomic event for both history tracking and scoring
    context.read<EpisodePlayerBloc>().add(EpisodePlayerEvent.answerQuestion(
      isCorrect: isCorrect,
      questionIndex: _currentQuestionIndex,
      answerIndex: index,
    ));
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Quiz complete
      final state = context.read<EpisodePlayerBloc>().state;
      state.maybeMap(
        loaded: (s) {
          if (s.correctAnswers == _questions.length) {
            setState(() => _allCorrectConfetti = true);
          }
        },
        orElse: () {},
      );

      Future.delayed(800.ms, () {
        if (mounted) {
          context.read<EpisodePlayerBloc>().add(const EpisodePlayerEvent.nextSegment());
        }
      });
    }
  }

  void _prevQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];
    // Compacted top padding
    final topPad = MediaQuery.of(context).padding.top + 100.0;

    return BlocBuilder<EpisodePlayerBloc, EpisodePlayerState>(
      builder: (context, state) {
        final correctCount = state.maybeWhen(loaded: (_, __, c, ___, ____, _____, ______, _______, ________, _________) => c, orElse: () => 0);
        
        final history = state.maybeWhen(loaded: (_, __, ___, ____, _____, ______, _______, ________, h, _________) => h, orElse: () => {});
        final quizAnswersRaw = history['quiz_answers'] as Map<String, dynamic>? ?? {};
        
        // Robust parsing of keys and values
        final Map<int, int> quizAnswers = {};
        quizAnswersRaw.forEach((k, v) {
          final idx = int.tryParse(k);
          if (idx != null) {
            quizAnswers[idx] = v is int ? v : int.tryParse(v.toString()) ?? 0;
          }
        });
        
        final hasAnswered = quizAnswers.containsKey(_currentQuestionIndex);
        
        return Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, topPad, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row (Reduced sizes)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🧠 QUIZ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.purple, letterSpacing: 0.5)),
                            Text('Phase ${_currentQuestionIndex + 1} of ${_questions.length}', style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                          child: Text('Score: $correctCount', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purple, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentQuestionIndex + 1) / _questions.length,
                        backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Question card (Reduced size)
                    Text(
                      currentQuestion.question,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3, color: AppColors.textDark),
                      textAlign: TextAlign.left,
                    ).animate(key: ValueKey(_currentQuestionIndex)).fadeIn().slideX(begin: 0.05),
                    
                    const SizedBox(height: 16),

                    // Answer options
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: currentQuestion.options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _buildOption(i, currentQuestion, quizAnswers, hasAnswered),
                      ),
                    ),

                    // Feedback Reveal
                    // Feedback Reveal (Reduced padding)
                    if (hasAnswered) 
                      _buildFeedbackPanel(currentQuestion)
                    else 
                      const SizedBox(height: 12),

                    const SizedBox(height: 16),

                    // Persistent Navigation Controls
                    _buildNavigationControls(hasAnswered),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            
            // Confetti overlay
            if (_allCorrectConfetti)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: const Text('🧠🎯🔥🎯🧠', style: TextStyle(fontSize: 60))
                        .animate().fadeIn().then().fadeOut(delay: 2.seconds),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOption(int index, QuizQuestion question, Map<int, int> userAnswers, bool hasAnswered) {
    final isSelected = userAnswers[_currentQuestionIndex] == index;
    final isCorrect = index == question.correctIndex;
    
    Color bgColor = Colors.white;
    Color borderColor = AppColors.purple.withValues(alpha: 0.15);
    Widget? trailing;

    if (hasAnswered) {
      if (isCorrect) {
        bgColor = AppColors.success.withValues(alpha: 0.08);
        borderColor = AppColors.success;
        trailing = const Icon(Icons.check_circle, color: AppColors.success, size: 20);
      } else if (isSelected) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade300;
        trailing = Icon(Icons.cancel, color: Colors.red.shade400, size: 20);
      }
    } else if (isSelected) {
      borderColor = AppColors.purple;
    }

    return GestureDetector(
      onTap: () => _handleAnswer(index, hasAnswered),
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (isSelected && !hasAnswered)
              BoxShadow(color: AppColors.purple.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Text(
              String.fromCharCode(65 + index), // A, B, C, D
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.purple : AppColors.textLight,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question.options[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.textDark : AppColors.textMedium,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1);
  }

  Widget _buildFeedbackPanel(QuizQuestion question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Feedback: ${question.feedback}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark, height: 1.4),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildNavigationControls(bool hasAnswered) {
    return Row(
      children: [
        // Left Button: Back to Story OR Previous Question
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: AppColors.purple.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _currentQuestionIndex == 0 
                ? () => context.read<EpisodePlayerBloc>().add(const EpisodePlayerEvent.previousSegment())
                : _prevQuestion,
            child: Text(
              _currentQuestionIndex == 0 ? 'BACK TO STORY' : 'PREVIOUS',
              style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Right Button: Next Question OR Continue to Journal
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              disabledBackgroundColor: AppColors.purple.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: hasAnswered ? 2 : 0,
            ),
            onPressed: hasAnswered ? _nextQuestion : null,
            child: Text(
              _currentQuestionIndex < _questions.length - 1 ? 'NEXT QUESTION' : 'TO JOURNAL',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }
}

// ────────────────────────────────────────────────────────────
//  Segment 4: Reflection
// ────────────────────────────────────────────────────────────
// ────────────────────────────────────────────────────────────
//  Segment 4: Reflection Journal
// ────────────────────────────────────────────────────────────
class _ReflectionSegment extends StatefulWidget {
  final Episode episode;
  const _ReflectionSegment({super.key, required this.episode});

  @override
  State<_ReflectionSegment> createState() => _ReflectionSegmentState();
}

class _ReflectionSegmentState extends State<_ReflectionSegment> {
  final PageController _stepsController = PageController();
  int _currentStep = 0;
  int _totalSteps = 5;
  List<dynamic> _sections = [];

  // Journal State
  final Map<String, String> _textAnswers = {};
  final List<String> _selectedEmotions = [];
  String? _comparisonChoice; // 'Yes', 'No', 'Not sure'
  String _mode = 'private';

  @override
  void initState() {
    super.initState();
    _parseSectionsSafe();
    
    // Restore state from history
    final state = context.read<EpisodePlayerBloc>().state;
    state.maybeMap(
      loaded: (s) {
        if (s.history.containsKey('reflection_state')) {
          final rs = s.history['reflection_state'] as Map<String, dynamic>;
          _textAnswers.addAll(Map<String, String>.from(rs['textAnswers'] ?? {}));
          _selectedEmotions.addAll(List<String>.from(rs['selectedEmotions'] ?? []));
          _comparisonChoice = rs['comparisonChoice'];
          _mode = rs['mode'] ?? 'private';
          _currentStep = rs['currentStep'] ?? 0;
          
          // Move PageController to correct step
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_stepsController.hasClients) {
              _stepsController.jumpToPage(_currentStep);
            }
          });
        }
      },
      orElse: () {},
    );
  }

  void _syncState() {
    final updatedHistory = Map<String, dynamic>.from(
      context.read<EpisodePlayerBloc>().state.maybeWhen(
            loaded: (_, __, ___, ____, _____, ______, _______, ________, history, _________) => history,
            orElse: () => {},
          ),
    );
    
    updatedHistory['reflection_state'] = {
      'textAnswers': _textAnswers,
      'selectedEmotions': _selectedEmotions,
      'comparisonChoice': _comparisonChoice,
      'mode': _mode,
      'currentStep': _currentStep,
    };

    // We don't have a specific event for this, but we can reuse UpdateReflection or just update progress
    // For now, I'll just update the local history and rely on the next progress sync, 
    // but better to add a dedicated event.
    // Actually, I'll just update the reflection content draft too.
    context.read<EpisodePlayerBloc>().add(
      EpisodePlayerEvent.updateReflection(
        mode: _mode,
        content: _generateBuffer(), // Generate intermediate buffer as draft
      ),
    );
  }

  String _generateBuffer() {
    final buffer = StringBuffer();
    buffer.writeln("Draft Journal Entry");
    if (_textAnswers.isNotEmpty) buffer.writeln("Answers: $_textAnswers");
    if (_selectedEmotions.isNotEmpty) buffer.writeln("Emotions: $_selectedEmotions");
    return buffer.toString();
  }

  void _parseSectionsSafe() {
    try {
      final dynContent = widget.episode.content;
      Map<String, dynamic>? content;
      
      if (dynContent is Map) {
        content = Map<String, dynamic>.from(dynContent);
      } else if (dynContent is String) {
        // Maybe it's double-encoded string?
      }

      final sections = content?['reflectionJournal']?['sections'] as List<dynamic>?;
      if (sections != null && sections.isNotEmpty) {
        setState(() {
          _sections = sections;
          _totalSteps = sections.length;
        });
        return;
      }
    } catch (e) {
      debugPrint("Reflection Parse Error: $e");
    }
    
    // Fallback
    setState(() {
      _totalSteps = 5;
      _sections = [];
    });
  }

  @override
  void dispose() {
    _stepsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
      _syncState();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _syncState();
    }
  }

  void _completeJournal() {
    // Collect and format the final reflection
    final buffer = StringBuffer();
    buffer.writeln("Journal: My Timeline, My Story");
    buffer.writeln("1. Noticed: ${_textAnswers['notice'] ?? 'N/A'}");
    buffer.writeln("2. Feelings: ${_selectedEmotions.join(', ')} (${_textAnswers['emotion_why'] ?? ''})");
    buffer.writeln("3. Comparison: $_comparisonChoice (${_textAnswers['comparison_who'] ?? ''})");
    buffer.writeln("4. Reframe: ${_textAnswers['reframe'] ?? 'N/A'}");
    buffer.writeln("5. Statement: My body is not late or early. It is ${_textAnswers['statement'] ?? 'N/A'}.");

    context.read<EpisodePlayerBloc>().add(
      EpisodePlayerEvent.updateReflection(
        mode: _mode,
        content: buffer.toString(),
      ),
    );
    context.read<EpisodePlayerBloc>().add(const EpisodePlayerEvent.nextSegment());
  }

  @override
  Widget build(BuildContext context) {
    // ATOMIC SIMPLIFICATION:
    // 1. No Row for buttons (source of infinite width crash)
    // 2. No ElevatedButton (source of complex constraint failure)
    // 3. Simple ListView (source of bounded constraints)
    
    final topPad = MediaQuery.of(context).padding.top + 130.0;
    
    return Container(
      color: Colors.white,
      child: ListView(
        padding: EdgeInsets.fromLTRB(24, topPad, 24, 100),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📓 JOURNAL', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    Text('“My Timeline, My Story”', style: TextStyle(color: Colors.black54, fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              _buildModeToggle(),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_totalSteps > 0) ? (_currentStep + 1) / (_totalSteps + 1) : 0.2,
            backgroundColor: Colors.indigo.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
            minHeight: 4,
          ),
          const SizedBox(height: 32),

          // Content
          _sections.isNotEmpty 
            ? _buildDynamicSection(_sections[_currentStep.clamp(0, _sections.length - 1)])
            : _buildStaticSection(_currentStep),
          
          const SizedBox(height: 48),

          // Navigation (Stacked vertically for absolute width safety)
          _buildSimplifiedNavigation(),
        ],
      ),
    );
  }

  Widget _buildSimplifiedNavigation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Continue Button (Primary)
        GestureDetector(
          onTap: _nextStep,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.purple,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Text(
              'CONTINUE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        
        // Back Button (Secondary)
        if (_currentStep > 0) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: _prevStep,
            child: Text(
              'BACK',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  // Helper to show static sections if backend is empty
  Widget _buildStaticSection(int step) {
    switch (step) {
      case 0: return _buildSection1();
      case 1: return _buildSection2();
      case 2: return _buildSection3();
      case 3: return _buildSection4();
      case 4: return _buildSection5();
      case 5: return _buildClosingScreen();
      default: return const SizedBox.shrink();
    }
  }


  Widget _buildModeToggle() {
    return GestureDetector(
      onTap: () {
        setState(() => _mode = _mode == 'private' ? 'community' : 'private');
        _syncState();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _mode == 'private' ? Colors.grey.shade100 : AppColors.purple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _mode == 'private' ? Colors.grey.shade300 : AppColors.purple.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(_mode == 'private' ? Icons.lock_outline : Icons.public, size: 14, color: _mode == 'private' ? Colors.grey : AppColors.purple),
            const SizedBox(width: 4),
            Text(
              _mode == 'private' ? 'Private' : 'Community',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _mode == 'private' ? Colors.grey : AppColors.purple),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRow() {
    if (_currentStep == 5) return const SizedBox.shrink(); // Closing screen handles its own

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          TextButton(
            onPressed: _prevStep,
            child: const Text('BACK', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
          )
        else
          const SizedBox.shrink(),
        
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _nextStep,
          child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDynamicSection(dynamic section) {
    final String type = section['type'] ?? 'text';
    final String prompt = section['prompt'] ?? '';
    final String id = section['id'] ?? '';
    final String hint = section['hint'] ?? '';
    final List<String> options = List<String>.from(section['options'] ?? []);

    switch (type) {
      case 'text':
        return _buildStepContainer(
          prompt: prompt,
          child: Column(
            children: [
              _buildTextField(key: id, hint: hint, maxLines: 4, autofocus: true),
              if (hint.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildHint(hint),
              ],
            ],
          ),
        );
      case 'emotion-chips':
        return _buildStepContainer(
          prompt: prompt,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.map((label) {
                  final isSelected = _selectedEmotions.contains(label);
                  return FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) _selectedEmotions.add(label);
                        else _selectedEmotions.remove(label);
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.indigo.withOpacity(0.1),
                    checkmarkColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? Colors.indigo : Colors.grey.shade300),
                    ),
                  );
                }).toList(),
              ),
              if (_selectedEmotions.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Why do you think you felt this way?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 12),
                _buildTextField(key: 'emotion_why', hint: 'Short note...', maxLines: 2),
              ],
            ],
          ),
        );
      case 'choice-conditional':
        final followUp = section['followUp'];
        return _buildStepContainer(
          prompt: prompt,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: options.map((choice) {
                  final isSelected = _comparisonChoice == choice;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(choice),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _comparisonChoice = val ? choice : null),
                    ),
                  );
                }).toList(),
              ),
              if (_comparisonChoice == followUp?['trigger']) ...[
                const SizedBox(height: 24),
                Text(followUp['prompt'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 12),
                _buildTextField(key: 'comparison_followup', hint: followUp['hint'] ?? '', maxLines: 2),
              ],
            ],
          ),
        );
      case 'completion':
        return _buildStepContainer(
          prompt: prompt,
          child: Column(
            children: [
              _buildTextField(key: id, hint: hint, maxLines: 2),
              const SizedBox(height: 16),
              _buildMicroLearning("Ownership shifts your focus from what's missing to what's possible."),
            ],
          ),
        );
      default:
        return _buildStepContainer(prompt: prompt, child: const Text("Section type not supported."));
    }
  }

  // --- Core Sections (Old fallbacks preserved) ---

  Widget _buildSection1() {
    return _buildStepContainer(
      prompt: 'Think about a moment recently when you noticed a change in your body… and it confused you.',
      child: Column(
        children: [
          _buildTextField(
            key: 'notice',
            hint: 'Describe that moment...',
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          _buildHint('It could be anything—height, skin, feelings, energy, or something you didn’t expect.'),
        ],
      ),
    );
  }

  Widget _buildSection2() {
    final emotions = [
      {'label': 'Confused', 'emoji': '😕'},
      {'label': 'Worried', 'emoji': '😟'},
      {'label': 'Embarrassed', 'emoji': '😳'},
      {'label': 'Curious', 'emoji': '🤔'},
      {'label': 'Neutral', 'emoji': '😐'},
      {'label': 'Something else', 'emoji': '🌱'},
    ];

    return _buildStepContainer(
      prompt: 'How did that moment make you feel?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: emotions.map((e) {
              final isSelected = _selectedEmotions.contains(e['label']);
              return FilterChip(
                label: Text('${e['emoji']} ${e['label']}'),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    if (val) _selectedEmotions.add(e['label']!);
                    else _selectedEmotions.remove(e['label']);
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: AppColors.purple.withValues(alpha: 0.1),
                checkmarkColor: AppColors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? AppColors.purple : Colors.grey.shade300),
                ),
              );
            }).toList(),
          ),
          if (_selectedEmotions.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Why do you think you felt this way?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 12),
            _buildTextField(key: 'emotion_why', hint: 'Short note...', maxLines: 2),
          ],
        ],
      ),
    );
  }

  Widget _buildSection3() {
    return _buildStepContainer(
      prompt: 'Were you comparing yourself to someone in that moment?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ['Yes', 'No', 'Not sure'].map((choice) {
              final isSelected = _comparisonChoice == choice;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: Text(choice),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _comparisonChoice = val ? choice : null),
                ),
              );
            }).toList(),
          ),
          if (_comparisonChoice == 'Yes') ...[
            const SizedBox(height: 24),
            const Text('Who were you comparing yourself to? And what felt different?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 12),
            _buildTextField(key: 'comparison_who', hint: 'Write here...', maxLines: 2),
          ],
          if (_comparisonChoice != null) ...[
            const SizedBox(height: 24),
            _buildMicroLearning('Comparison often makes changes feel like problems—even when they’re not.'),
          ],
        ],
      ),
    );
  }

  Widget _buildSection4() {
    return _buildStepContainer(
      prompt: 'If your best friend felt the same way you did… what would you tell her?',
      child: Column(
        children: [
          _buildTextField(
            key: 'reframe',
            hint: 'A kind message to a friend...',
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          _buildHint('Try to be as kind to yourself as you are to your friends.'),
        ],
      ),
    );
  }

  Widget _buildSection5() {
    return _buildStepContainer(
      prompt: 'Complete this sentence:',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('“My body is not late or early. It is... ”', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.purple, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          _buildTextField(key: 'statement', hint: 'e.g., growing at its own pace', maxLines: 2),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Examples:', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                const SizedBox(height: 6),
                _buildHint('• growing at its own pace'),
                _buildHint('• figuring things out'),
                _buildHint('• changing in its own way'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosingScreen() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌸', style: TextStyle(fontSize: 60)).animate().scale(curve: Curves.elasticOut),
          const SizedBox(height: 32),
          const Text(
            '“Nothing about your journey is ‘behind.’\nIt’s just unfolding.”',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.purple, height: 1.5, fontStyle: FontStyle.italic),
          ).animate().fadeIn(duration: 800.ms),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _completeJournal,
              child: const Text('SAVE & COMPLETE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ).animate().fadeIn(delay: 1.seconds),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildStepContainer({required String prompt, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.4)),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
  Widget _buildTextField({required String key, required String hint, int maxLines = 1, bool autofocus = false}) {
    return TextField(
      autofocus: autofocus,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(18),
      ),
      onChanged: (val) => _textAnswers[key] = val,
    );
  }

  Widget _buildHint(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, color: Colors.black45, height: 1.4));
  }

  Widget _buildMicroLearning(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.indigo, fontWeight: FontWeight.w600, height: 1.4))),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color bgColor;
  final Color textColor;
  const _ReactionChip({required this.emoji, required this.label, required this.bgColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(28)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13)),
      ]),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Segment 5: Summary Activity – backend-driven points
// ────────────────────────────────────────────────────────────
class _SummarySegment extends StatefulWidget {
  final Episode episode;
  const _SummarySegment({required this.episode});

  @override
  State<_SummarySegment> createState() => _SummarySegmentState();
}

class _SummarySegmentState extends State<_SummarySegment> {
  int _internalStep = 0; // 0: Catch, 1: Name, 2: Reframe, 3: Reflect, 4: Rewards
  String? _selectedCategory;
  final TextEditingController _reframeController = TextEditingController();
  String? _selectedReflection;

  @override
  void initState() {
    super.initState();
    
    // Restore state from history
    final state = context.read<EpisodePlayerBloc>().state;
    state.maybeMap(
      loaded: (s) {
        if (s.history.containsKey('summary_state')) {
          final ss = s.history['summary_state'] as Map<String, dynamic>;
          _internalStep = ss['internalStep'] ?? 0;
          _selectedCategory = ss['selectedCategory'];
          _selectedReflection = ss['selectedReflection'];
          _reframeController.text = ss['reframeText'] ?? '';
        }
      },
      orElse: () {},
    );
  }

  void _syncState() {
    context.read<EpisodePlayerBloc>().add(
      EpisodePlayerEvent.syncHistory({
        'summary_state': {
          'internalStep': _internalStep,
          'selectedCategory': _selectedCategory,
          'selectedReflection': _selectedReflection,
          'reframeText': _reframeController.text,
        }
      }),
    );
  }

  @override
  void dispose() {
    _reframeController.dispose();
    super.dispose();
  }

  void _next() {
    setState(() => _internalStep++);
    _syncState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.background),
      child: Padding(
        padding: const EdgeInsets.only(top: 100), // Room for global TopBar (height: 120)
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: 400.ms,
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_internalStep) {
      case 0: return _buildStepCatch();
      case 1: return _buildStepName();
      case 2: return _buildStepReframe();
      case 3: return _buildStepReflect();
      case 4: return _buildRewardsScreen();
      default: return const SizedBox.shrink();
    }
  }

  // --- Step 1: Catch the Moment ---
  Widget _buildStepCatch() {
    return Padding(
      padding: const EdgeInsets.all(24),
      key: const ValueKey('step_catch'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 60)).animate().scale(),
          const SizedBox(height: 24),
          const Text(
            'SUMMARY: “Notice, Don’t Compare”',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.purple),
          ),
          const SizedBox(height: 16),
          const Text(
            'Next time you notice yourself comparing your body to someone else—pause.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textLight, height: 1.5),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _next,
              child: const Text('I NOTICED IT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Name It ---
  Widget _buildStepName() {
    final categories = ['Height', 'Skin', 'Body shape', 'Something else'];
    return Padding(
      padding: const EdgeInsets.all(24),
      key: const ValueKey('step_name'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🪜 Step 2: Name It', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('What were you comparing?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final cat = categories[i];
                final isSel = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.purple.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSel ? AppColors.purple : Colors.grey.shade300, width: isSel ? 2 : 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat, style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? AppColors.purple : Colors.black87)),
                        if (isSel) const Icon(Icons.check_circle, color: AppColors.purple),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedCategory != null ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 3: Reframe It ---
  Widget _buildStepReframe() {
    return Padding(
      padding: const EdgeInsets.all(24),
      key: const ValueKey('step_reframe'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🪜 Step 3: Reframe It', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Replace the thought:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildReframeCard('Why am I different?', 'Maybe we’re on different timelines.'),
          const SizedBox(height: 32),
          const Text('Your turn: How would you reframe it to be kinder?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _reframeController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g., My body is doing exactly what it needs to...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReframeCard(String from, String to) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('👉 From: “$from”', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Text('👉 To: “$to”', style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  // --- Step 4: Micro Reflection ---
  Widget _buildStepReflect() {
    final options = [
      {'label': 'Lighter', 'emoji': '😌'},
      {'label': 'Still unsure', 'emoji': '🤔'},
      {'label': 'Thinking about it', 'emoji': '💭'},
      {'label': 'A little better', 'emoji': '🌱'},
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      key: const ValueKey('step_reflect'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🪜 Step 4: Micro Reflection', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('How did that shift feel?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.map((opt) {
                final label = opt['label']!;
                final isSel = _selectedReflection == label;
                return GestureDetector(
                  onTap: () => setState(() => _selectedReflection = label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.purple : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSel ? AppColors.purple : Colors.grey.shade300),
                    ),
                    child: Text('${opt['emoji']} $label', style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? Colors.white : Colors.black87)),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedReflection != null ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('FINISH ACTIVITY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Final Step: Rewards Screen ---
  Widget _buildRewardsScreen() {
    return BlocBuilder<EpisodePlayerBloc, EpisodePlayerState>(
      key: const ValueKey('rewards_screen'),
      builder: (context, state) {
        final summaryPts = state.maybeWhen(
          loaded: (ep, i, c, a, m, rc, comp, ci, h, sp) => sp['summary'] ?? 25,
          orElse: () => 25,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.purple.withOpacity(0.2), width: 2),
                ),
                child: const Text('🌟', style: TextStyle(fontSize: 64)),
              ).animate().scale(curve: Curves.elasticOut),
              const SizedBox(height: 24),
              const Text(
                'Timeline Explorer', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.purple),
              ),
              const Text(
                'MASTER BADGE EARNED', 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2, color: AppColors.textLight),
              ),
              const SizedBox(height: 32),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 32),
                    const SizedBox(width: 12),
                    Text('+$summaryPts XP', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Teaser Episode 2
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B4B),
                  borderRadius: BorderRadius.circular(24),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/hook.jpeg'),
                    fit: BoxFit.cover,
                    opacity: 0.25,
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.purple.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'COMING SOON', 
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Episode 2: Growing Pains', 
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Uncovering why some changes feel late, some feel early, and all of them are normal.', 
                      style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5), 
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    context.read<EpisodePlayerBloc>().add(
                          const EpisodePlayerEvent.completeEpisode(),
                        );
                  },
                  child: const Text('BACK TO PATH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _PointRow extends StatelessWidget {
  final String label;
  final String pts;
  final bool isBold;
  const _PointRow({required this.label, required this.pts, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(pts, style: TextStyle(color: Colors.white, fontSize: isBold ? 18 : 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Mode Card (Private / Community toggle)
// ────────────────────────────────────────────────────────────
class _ModeCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({required this.title, this.subtitle, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple.withValues(alpha: 0.09) : Colors.white,
          border: Border.all(color: isSelected ? AppColors.purple : Colors.grey.shade200, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.purple : Colors.grey.shade400, size: 22),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(color: isSelected ? AppColors.purple : Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 13)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: TextStyle(color: isSelected ? AppColors.purple : Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
