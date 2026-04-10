import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../models/learning_models.dart';
import '../application/episode_player_bloc.dart';
import '../../../core/theme/app_theme.dart';

// ────────────────────────────────────────────────────────────
//  Segment metadata – used by nav bar and header
// ────────────────────────────────────────────────────────────
const _kSegments = [
  _SegmentMeta('🪝', 'Hook'),
  _SegmentMeta('📖', 'Story'),
  _SegmentMeta('✅', 'Check'),
  _SegmentMeta('💭', 'Reflect'),
  _SegmentMeta('⚡', 'Quest'),
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
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EpisodePlayerBloc>().add(EpisodePlayerEvent.loadEpisode(widget.episode.id));
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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
                onPressed: () => context.go('/home'),
                child: const Text('Back to Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          loaded: (episode, index, correct, answered, mode, content, isCompleting, completedSegmentIndices, segmentPoints) {
            if (_pageController.hasClients && _pageController.page?.round() != index) {
              _pageController.animateToPage(index, duration: 600.ms, curve: Curves.easeInOutCubic);
            }
          },
          completed: (points, breakdown) => _showCompletionDialog(context, points),
          error: (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))),
          orElse: () {},
        );
      },
      builder: (context, state) {
        return state.when(
          initial: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (msg) => Scaffold(body: Center(child: Text(msg))),
          completed: (_, __) => const Scaffold(body: SizedBox.shrink()),
          loaded: (episode, index, correct, answered, mode, content, isCompleting, completedIndices, segmentPoints) {
            final isHook = index == 0;
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
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _HookSegment(episode: episode),
                      _StorySegment(episode: episode),
                      _KnowledgeCheckSegment(episode: episode),
                      _ReflectionSegment(episode: episode),
                      _SummarySegment(episode: episode),
                    ],
                  ),
                  // Top bar — shown on Story / Check / Reflect only (Hook has its own)
                  if (index > 0 && index < 4)
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
//  Top bar (all segments except Quest)
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
              onPressed: () => context.go('/home'),
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

  static const _pointKeys = ['', 'story', 'knowledgeCheck', 'reflection', 'quest'];

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
                  'EPISODES',
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
                    final isLocked = i > currentIndex;
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

class _HookSegmentState extends State<_HookSegment> {
  static const int _totalSeconds = 30;
  static const int _skipAfterSeconds = 10;
  // TODO: Wire to user profile (true = returning user, skip is available)
  static const bool _isReturningUser = true;

  int _elapsed = 0;
  Timer? _timer;
  bool _timerDone = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _elapsed++;
        if (_elapsed >= _totalSeconds) {
          _timerDone = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _advance() {
    context.read<EpisodePlayerBloc>().add(const EpisodePlayerEvent.nextSegment());
  }

  @override
  Widget build(BuildContext context) {
    final hook = widget.episode.content['hook'] as Map<String, dynamic>? ?? {};
    final showSkip = _isReturningUser && _elapsed >= _skipAfterSeconds && !_timerDone;
    final progress = (_elapsed / _totalSeconds).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.brandDiagonal),
      child: Stack(
        children: [
          // Full-screen content
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎬', style: TextStyle(fontSize: 80)).animate().scale(delay: 200.ms),
                const SizedBox(height: 48),
                Text(
                  hook['text'] as String? ?? 'Every journey starts with a single step...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.4),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 60),
                // Progress bar
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timerDone ? 'Ready to continue!' : '${_totalSeconds - _elapsed}s',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Skip button (top-right, returning users only, after 10s)
          if (showSkip)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 20,
              child: ActionChip(
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                side: BorderSide.none,
                label: const Text('Skip Intro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: _advance,
              ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.2),
            ),

          // Back button (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.go('/home'),
            ),
          ),

          // Continue button — appears when timer is done
          if (_timerDone)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 110,
              left: 32,
              right: 32,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _advance,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Let's Start", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Segment 2: Story
// ────────────────────────────────────────────────────────────
class _StorySegment extends StatefulWidget {
  final Episode episode;
  const _StorySegment({required this.episode});

  @override
  State<_StorySegment> createState() => _StorySegmentState();
}

class _StorySegmentState extends State<_StorySegment> {
  bool _factRevealed = false;

  @override
  Widget build(BuildContext context) {
    final story = widget.episode.content['story'] as Map<String, dynamic>? ?? {};
    final topPadding = MediaQuery.of(context).padding.top + 80;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, topPadding, 24, 40),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row + audio
            Row(
              children: [
                Expanded(
                  child: Text(
                    story['title'] as String? ?? 'The Story',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.purple),
                  ).animate().fadeIn().slideX(begin: -0.1),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.volume_up, color: AppColors.purple),
                  style: IconButton.styleFrom(backgroundColor: AppColors.purple.withValues(alpha: 0.1)),
                ).animate().scale(delay: 200.ms),
              ],
            ),
            const SizedBox(height: 20),

            // Narrative text
            Text(
              story['text'] as String? ?? 'The story begins here...',
              style: const TextStyle(fontSize: 18, height: 1.8, color: AppColors.textMedium),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 28),

            // Character Speech Bubble
            Container(
              margin: const EdgeInsets.only(right: 48),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(
                story['character_speech'] as String? ?? '"I can feel my heart racing... am I the only one?\"',
                style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textDark, fontStyle: FontStyle.italic),
              ),
            ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
            const SizedBox(height: 8),

            // Thought Cloud (internal monologue)
            Container(
              margin: const EdgeInsets.only(left: 16, right: 56),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                story['character_thought'] as String? ?? '(Inside: Please just let this day end...)',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontStyle: FontStyle.italic, height: 1.4),
              ),
            ).animate().fadeIn(delay: 900.ms),
            const SizedBox(height: 28),

            // Tap-to-Reveal Micro-Moment
            GestureDetector(
              onTap: () => setState(() => _factRevealed = true),
              child: AnimatedContainer(
                duration: 400.ms,
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _factRevealed ? AppColors.success.withValues(alpha: 0.07) : AppColors.purple.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _factRevealed ? AppColors.success.withValues(alpha: 0.4) : AppColors.purple.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(
                        _factRevealed ? Icons.lightbulb : Icons.touch_app_rounded,
                        color: _factRevealed ? AppColors.success : AppColors.purple,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _factRevealed ? 'Did you know?' : 'Tap to reveal a fact',
                        style: TextStyle(
                          color: _factRevealed ? AppColors.success : AppColors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ]),
                    if (_factRevealed) ...[
                      const SizedBox(height: 10),
                      Text(
                        story['tap_fact'] as String? ?? 'Your brain produces over 100,000 chemical reactions per day, many triggered by emotion.',
                        style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textDark),
                      ).animate().fadeIn().slideY(begin: 0.1),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 1200.ms),
            const SizedBox(height: 28),

            // Gigi Framing Voice Card
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(left: 32),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.07),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20), topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20), bottomRight: Radius.circular(5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        story['gigi_frame'] as String? ?? "It's totally normal to feel like everything is changing. You're right where you need to be.",
                        style: const TextStyle(color: AppColors.textDark, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, height: 1.5, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Text('🧬', style: TextStyle(fontSize: 22)),
                    ),
                  ],
                ),
              ).animate().slideX(begin: 1.0, delay: 1800.ms).fadeIn(),
            ),
            const SizedBox(height: 32),

            // Continue CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => context.read<EpisodePlayerBloc>().add(const EpisodePlayerEvent.nextSegment()),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('CONTINUE TO CHECK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
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
//  Segment 3: Knowledge Check
// ────────────────────────────────────────────────────────────
class _KnowledgeCheckSegment extends StatefulWidget {
  final Episode episode;
  const _KnowledgeCheckSegment({required this.episode});

  @override
  State<_KnowledgeCheckSegment> createState() => _KnowledgeCheckSegmentState();
}

class _KnowledgeCheckSegmentState extends State<_KnowledgeCheckSegment> {
  bool _showingTrueFalse = false;
  bool _allCorrectConfetti = false;

  void _handleAnswer(BuildContext ctx, bool isCorrect, int answered, int correct) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isCorrect ? '💚' : '🌱', style: const TextStyle(fontSize: 60))
                .animate().scale(curve: Curves.elasticOut),
            const SizedBox(height: 12),
            Text(
              isCorrect ? 'You got it!' : "Not quite — here's the thing:",
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold,
                color: isCorrect ? AppColors.success : AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            if (isCorrect) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('+5 XP earned', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              isCorrect
                  ? 'That is exactly right. Your body is doing what it is supposed to do.'
                  : "It's completely natural. Everyone goes through this at their own pace.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMedium, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  ctx.read<EpisodePlayerBloc>().add(EpisodePlayerEvent.answerQuestion(isCorrect: isCorrect));
                  final newAnswered = answered + 1;
                  final newCorrect = isCorrect ? correct + 1 : correct;
                  if (newAnswered >= 3) {
                    if (newCorrect == 3) setState(() => _allCorrectConfetti = true);
                    Future.delayed(600.ms, () {
                      if (ctx.mounted) ctx.read<EpisodePlayerBloc>().add(const EpisodePlayerEvent.nextSegment());
                    });
                  }
                },
                child: const Text('CONTINUE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EpisodePlayerBloc, EpisodePlayerState>(
      builder: (context, state) {
        final answered = state.maybeWhen(loaded: (_e, _i, _c, a, _m, _c2, _cm, _ci, _sp) => a, orElse: () => 0);
        final correct = state.maybeWhen(loaded: (_e, _i, c, _a, _m, _c2, _cm, _ci, _sp) => c, orElse: () => 0);
        final gigiEmoji = answered == 0 ? '🤔' : (correct == answered && answered > 0 ? '🤩' : '🥺');
        final topPad = MediaQuery.of(context).padding.top + 80.0;

        return Stack(
          children: [
            SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, topPad, 24, 40),
                child: Column(
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Knowledge Check', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.purple)),
                              Text('Retrieval Practice', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.08), shape: BoxShape.circle),
                          child: Text(gigiEmoji, style: const TextStyle(fontSize: 26)),
                        ).animate(key: ValueKey(gigiEmoji)).scale(curve: Curves.elasticOut),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Question card
                    Card(
                      elevation: 0,
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Is it normal to experience mood swings during puberty?',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.textDark),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ).animate().scale(delay: 200.ms),
                    const SizedBox(height: 8),

                    // Toggle question type
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showingTrueFalse = !_showingTrueFalse),
                        icon: const Icon(Icons.swap_horiz, size: 14),
                        label: Text(_showingTrueFalse ? 'Single Choice' : 'True / False', style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Answer options
                    Expanded(
                      child: _showingTrueFalse
                          ? _buildTrueFalse(context, answered, correct)
                          : _buildSingleChoice(context, answered, correct),
                    ),

                    // Completion banner
                    if (answered >= 3) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppColors.purple.withValues(alpha: 0.12),
                            AppColors.success.withValues(alpha: 0.08),
                          ]),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🌸', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('+20 Knowledge Points!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.purple)),
                                if (correct == 3)
                                  const Text('+10 Accuracy Bonus 🎯', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ).animate().scale(curve: Curves.elasticOut),
                    ],

                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.read<EpisodePlayerBloc>().add(const EpisodePlayerEvent.nextSegment()),
                      child: const Text('Skip this time', style: TextStyle(color: AppColors.textLight)),
                    ),
                  ],
                ),
              ),
            ),
            // Confetti overlay
            if (_allCorrectConfetti)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: const Text('🌸🎉🌸🎉🌸', style: TextStyle(fontSize: 60))
                        .animate().fadeIn().then().fadeOut(delay: 2.seconds),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTrueFalse(BuildContext ctx, int answered, int correct) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _handleAnswer(ctx, true, answered, correct),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF81C784), width: 2),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🌿', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 10),
                  Text('True', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF388E3C))),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => _handleAnswer(ctx, false, answered, correct),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFB74D), width: 2),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🌸', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 10),
                  Text('False', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFF57C00))),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().scale(delay: 300.ms);
  }

  Widget _buildSingleChoice(BuildContext ctx, int answered, int correct) {
    const options = ["It's natural and okay", "It's scary", "Ignore it", "Only some people do"];
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _handleAnswer(ctx, i == 0, answered, correct),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.4), width: 2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(options[i], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
            ],
          ),
        ),
      ).animate(delay: (i * 60).ms).slideX(begin: 0.1).fadeIn(),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Segment 4: Reflection
// ────────────────────────────────────────────────────────────
class _ReflectionSegment extends StatelessWidget {
  final Episode episode;
  const _ReflectionSegment({required this.episode});

  static const _prompts = [
    "What's one thing from this episode you wish you'd known a year ago?",
    'If you could ask the character one question right now, what would it be?',
    "What's one thing that surprised you today?",
    'Try the technique from this episode right now — what do you notice?',
  ];

  @override
  Widget build(BuildContext context) {
    final prompt = _prompts[DateTime.now().minute % _prompts.length];
    final topPad = MediaQuery.of(context).padding.top + 80.0;

    return BlocBuilder<EpisodePlayerBloc, EpisodePlayerState>(
      builder: (context, state) {
        final mode = state.maybeWhen(loaded: (e, i, c, a, m, r, comp, ci, sp) => m, orElse: () => 'private');

        return SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, topPad, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reflection 🧘‍♀️', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.purple)),
                const SizedBox(height: 8),
                Text(prompt,
                    style: const TextStyle(fontSize: 15, color: AppColors.textMedium, fontStyle: FontStyle.italic, height: 1.4),
                    textAlign: TextAlign.left).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 20),

                // Mode toggle
                Row(children: [
                  Expanded(child: _ModeCard(
                    title: 'Private Journal',
                    subtitle: '+10 XP',
                    icon: Icons.lock_outline,
                    isSelected: mode == 'private',
                    onTap: () => context.read<EpisodePlayerBloc>().add(const EpisodePlayerEvent.updateReflection(mode: 'private')),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _ModeCard(
                    title: 'Community',
                    subtitle: '+15 XP',
                    icon: Icons.public,
                    isSelected: mode == 'community',
                    onTap: () => context.read<EpisodePlayerBloc>().add(const EpisodePlayerEvent.updateReflection(mode: 'community')),
                  )),
                ]),
                const SizedBox(height: 16),

                // Text input + mic
                Expanded(
                  child: Stack(children: [
                    TextField(
                      maxLines: null,
                      maxLength: 100,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: prompt,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(18),
                      ),
                      onChanged: (val) => context.read<EpisodePlayerBloc>().add(EpisodePlayerEvent.updateReflection(mode: mode, content: val)),
                    ),
                    Positioned(
                      right: 12, bottom: 36,
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.mic, color: AppColors.purple),
                        style: IconButton.styleFrom(backgroundColor: AppColors.purple.withValues(alpha: 0.08)),
                      ).animate().scale(delay: 400.ms),
                    ),
                  ]),
                ),

                // Community Reactions
                if (mode == 'community') ...[
                  const SizedBox(height: 12),
                  const Text('Community Reactions', style: TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _ReactionChip(emoji: '💜', label: 'Relate', bgColor: const Color(0xFFF3E5F5), textColor: AppColors.purple),
                    const SizedBox(width: 10),
                    _ReactionChip(emoji: '💡', label: 'Good point', bgColor: const Color(0xFFFFF9C4), textColor: const Color(0xFFF57F17)),
                  ]).animate().fadeIn(delay: 200.ms),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => context.read<EpisodePlayerBloc>().add(const EpisodePlayerEvent.nextSegment()),
                    child: const Text('SAVE & CONTINUE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16), // bottom clearance
              ],
            ),
          ),
        );
      },
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
//  Segment 5: Quest Link (Summary) – backend-driven points
// ────────────────────────────────────────────────────────────
class _SummarySegment extends StatefulWidget {
  final Episode episode;
  const _SummarySegment({required this.episode});

  @override
  State<_SummarySegment> createState() => _SummarySegmentState();
}

class _SummarySegmentState extends State<_SummarySegment> {
  late DateTime _arrivedAt;
  static const _messages = [
    'You crushed it! 🌟',
    'That\'s what growth looks like 💜',
    'You showed up. That matters 💚',
    'Knowledge unlocked! 🔓',
    'One step closer 🦋',
    'You\'re building something real 🌱',
    'Gigi is proud of you! 🤩',
    'Keep going — you\'re doing great ⚡',
  ];

  @override
  void initState() {
    super.initState();
    _arrivedAt = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final message = _messages[DateTime.now().second % _messages.length];
    return BlocBuilder<EpisodePlayerBloc, EpisodePlayerState>(
      builder: (context, state) {
        final segPts = state.maybeWhen(
          loaded: (ep, i, c, a, m, rc, comp, ci, sp) => sp,
          orElse: () => <String, int>{},
        );
        final storyPts = segPts['story'] ?? 30;
        final checkPts = segPts['knowledgeCheck'] ?? 20;
        final reflectPts = segPts['reflection'] ?? 10;
        final questPts = segPts['quest'] ?? 15;
        final total = storyPts + checkPts + reflectPts + questPts;

        return Container(
          decoration: const BoxDecoration(gradient: AppGradients.brandDiagonal),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: const Text('🤩', style: TextStyle(fontSize: 64)),
                  ).animate().shimmer(duration: 1800.ms).scale(curve: Curves.elasticOut),
                  const SizedBox(height: 28),
                  const Text(
                    'Quest Link',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  // Points breakdown – values from backend via segmentPoints
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        _PointRow(label: '📖 Story Completion', pts: '+$storyPts'),
                        _PointRow(label: '✅ Knowledge Check', pts: '+$checkPts'),
                        _PointRow(label: '🧘 Reflection', pts: '+$reflectPts'),
                        _PointRow(label: '⚡ Quest Bonus', pts: '+$questPts'),
                        const Divider(color: Colors.white30, height: 20),
                        _PointRow(label: 'Total XP', pts: '+$total', isBold: true),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () {
                        final isBinge = DateTime.now().difference(_arrivedAt).inSeconds <= 10;
                        context.read<EpisodePlayerBloc>().add(
                              EpisodePlayerEvent.completeEpisode(isBingeBonus: isBinge),
                            );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('COLLECT REWARDS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(width: 8),
                          Icon(Icons.emoji_events_rounded),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                ],
              ),
            ),
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
