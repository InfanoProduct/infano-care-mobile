import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/journal/application/journal_cubit.dart';
import 'package:infano_care_mobile/features/journal/application/journal_state.dart';
import 'package:infano_care_mobile/features/journal/data/models/journal_entry.dart';
import 'package:infano_care_mobile/features/journal/data/models/video_diary_data.dart';
import 'package:infano_care_mobile/features/journal/screens/journal_lock_screen.dart';
import 'package:infano_care_mobile/features/journal/screens/widgets/abstract_mood_tile_painter.dart';
import 'package:infano_care_mobile/features/journal/screens/widgets/app_video_player.dart';
import 'package:infano_care_mobile/features/journal/screens/widgets/share_to_community_sheet.dart';

// ─── Mood Options ─────────────────────────────────────────────────────────────
const _moodOptions = [
  ('🌟', 'Amazing', Color(0xFFFBBF24)),
  ('😊', 'Happy', Color(0xFF34D399)),
  ('😌', 'Calm', Color(0xFF60A5FA)),
  ('🤔', 'Thoughtful', Color(0xFF818CF8)),
  ('😔', 'Sad', Color(0xFF93C5FD)),
  ('😤', 'Frustrated', Color(0xFFF87171)),
  ('😰', 'Anxious', Color(0xFFA78BFA)),
  ('😴', 'Tired', Color(0xFF94A3B8)),
  ('🔥', 'Energized', Color(0xFFFB923C)),
  ('💫', 'Mixed', Color(0xFFEC4899)),
];

class JournalHomeScreen extends StatefulWidget {
  const JournalHomeScreen({super.key});

  @override
  State<JournalHomeScreen> createState() => _JournalHomeScreenState();
}

class _JournalHomeScreenState extends State<JournalHomeScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedMood;
  Color? _selectedMoodColor;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<JournalCubit>().loadFeed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          JournalLockScreen.lockSession();
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF4FF),
        body: BlocBuilder<JournalCubit, JournalState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => context.read<JournalCubit>().loadFeed(forceRefresh: true),
              color: AppColors.purple,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
              _buildSliverAppBar(context, state),
              SliverToBoxAdapter(child: _buildMoodWheel()),
              SliverToBoxAdapter(child: _buildDailyPromptCard(state)),
              if (state is JournalLoaded && state.onThisDay.isNotEmpty)
                SliverToBoxAdapter(child: _buildOnThisDayCard(state.onThisDay.first)),
              if (state is JournalLoaded && state.entries.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('📖', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Scrapbook Feed',
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Scroll through your personal memories',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMedium,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showMoodWeather(context, state),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.purple),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Mood Weather',
                                    style: GoogleFonts.nunito(
                                      color: AppColors.purple,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (state is JournalLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              if (state is JournalError)
                SliverFillRemaining(child: _buildErrorState(state.message)),
              if (state is JournalLoaded && state.entries.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: _buildEmptyState(),
                  ),
                ),
              if (state is JournalLoaded && state.entries.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == state.entries.length) {
                          return state.currentPage < state.totalPages
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: ElevatedButton(
                                    onPressed: () => context.read<JournalCubit>().loadMore(),
                                    child: const Text('Load More'),
                                  ),
                                )
                              : const SizedBox(height: 100);
                        }
                        return _buildEntryCard(context, state.entries[index], index);
                      },
                      childCount: state.entries.length + 1,
                    ),
                  ),
                ),
            ],
          ),
        );
        },
      ),
      floatingActionButton: _buildNewEntryFab(context),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, JournalState state) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      JournalLockScreen.lockSession();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('My Journal', style: GoogleFonts.nunito(
                        fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text('Your private sanctuary ✨', style: GoogleFonts.nunito(
                        fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodWheel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you feeling? 💭', style: GoogleFonts.nunito(
            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _moodOptions.map((mood) {
              final isSelected = _selectedMood == mood.$1;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedMood = mood.$1;
                  _selectedMoodColor = mood.$3;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? mood.$3.withValues(alpha: 0.15) : const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? mood.$3 : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(mood.$1, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(mood.$2, style: GoogleFonts.nunito(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: isSelected ? mood.$3 : AppColors.textMedium)),
                  ]),
                ),
              );
            }).toList(),
          ),
          if (_selectedMood != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await context.push('/journal/new', extra: {
                    'moodTag': _selectedMood,
                    'moodColor': _selectedMoodColor != null
                        ? '#${(_selectedMoodColor!.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}'
                        : null,
                  });
                  if (mounted) context.read<JournalCubit>().loadFeed();
                },
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Journal about it'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildDailyPromptCard(JournalState state) {
    if (state is! JournalLoaded) return const SizedBox.shrink();
    final prompt = state.dailyPrompt;
    if (prompt == null) return const SizedBox.shrink();

    final targetMode = prompt.bestModes.isNotEmpty ? prompt.bestModes.first : 'guided_prompt';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('💡 Daily Prompt', style: GoogleFonts.nunito(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Text(prompt.category, style: GoogleFonts.nunito(
                  color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 10),
              Text(prompt.text, style: GoogleFonts.nunito(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4)),
              const SizedBox(height: 12),
              Row(children: [
                GestureDetector(
                  onTap: () async {
                    await context.push('/journal/compose', extra: {
                      'promptId': prompt.id,
                      'promptText': prompt.text,
                      'promptOptions': prompt.options,
                      'mode': targetMode,
                    });
                    if (mounted) context.read<JournalCubit>().loadFeed();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Answer this ✨', style: GoogleFonts.nunito(
                      color: AppColors.purple, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    await context.read<JournalCubit>().shakePromptJar();
                    if (mounted) context.read<JournalCubit>().loadFeed();
                  },
                  icon: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 16),
                  label: Text('Next prompt', style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildOnThisDayCard(JournalEntry entry) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('🕰️', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('On this day, ${DateFormat('yyyy').format(entry.createdAt)}',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13, color: const Color(0xFF92400E))),
                Text(entry.preview, style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFFB45309)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFB45309)),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildEntryCard(BuildContext context, JournalEntry entry, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () async {
          await context.push('/journal/${entry.id}');
          if (context.mounted) context.read<JournalCubit>().loadFeed();
        },
        child: _ScrapbookEntryCard(entry: entry),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * (index % 5))).slideY(begin: 0.08);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📖', style: TextStyle(fontSize: 48))
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 12),
          Text(
            'Your journal is waiting',
            style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Start your first entry — pick any mode that feels right today.',
            style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await context.push('/journal/new');
              if (mounted) context.read<JournalCubit>().loadFeed();
            },
            icon: const Icon(Icons.add),
            label: const Text('Start journaling'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text('Couldn\'t load your journal', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => context.read<JournalCubit>().loadFeed(), child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildNewEntryFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        await context.push('/journal/new');
        if (context.mounted) context.read<JournalCubit>().loadFeed();
      },
      backgroundColor: AppColors.purple,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.auto_awesome_rounded),
      label: Text('New Entry', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
      elevation: 6,
    ).animate().scale(begin: const Offset(0.8, 0.8), delay: 400.ms, duration: 500.ms, curve: Curves.elasticOut);
  }

  void _showMoodWeather(BuildContext context, JournalLoaded state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoodWeatherSheet(heatmap: state.moodWeather),
    );
  }
}

// ─── Scrapbook Entry Card ──────────────────────────────────────────────────────

// ─── Social Media Feed Scrapbook Card ────────────────────────────────────────

class _ScrapbookEntryCard extends StatelessWidget {
  final JournalEntry entry;

  const _ScrapbookEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return _ScrapbookSocialFeedCard(entry: entry);
  }
}

class _ScrapbookSocialFeedCard extends StatelessWidget {
  final JournalEntry entry;

  const _ScrapbookSocialFeedCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final mode = entry.mode;
    final gradient = mode.gradient;

    // Header Title / Question extraction
    String headerTitle = '';
    if (mode == JournalMode.guidedPrompt) {
      headerTitle = (entry.content['question'] as String?) ??
          (entry.content['promptText'] as String?) ??
          'What is something you appreciate about yourself today?';
    } else if (entry.title != null && entry.title!.isNotEmpty) {
      headerTitle = entry.title!;
    } else {
      switch (mode) {
        case JournalMode.moodColor:
          final tileData = AbstractMoodTileData.fromJson(entry.content);
          headerTitle = tileData.label ?? 'Today\'s Mood Canvas ✨';
          break;
        case JournalMode.videoDiary:
          final videoData = VideoDiaryData.fromJson(entry.content);
          headerTitle = videoData.vibeTag ?? 'Daily Video Memory 🎬';
          break;
        case JournalMode.voiceNote:
          headerTitle = 'Voice Reflection 🎙️';
          break;
        case JournalMode.photoBoard:
          headerTitle = 'Photo Memories Board 📸';
          break;
        case JournalMode.blackoutPoetry:
          headerTitle = 'Poetry Reflection ✒️';
          break;
        default:
          headerTitle = 'Personal Reflection ✍️';
      }
    }

    // Selected options extraction
    final rawOptions = entry.content['selectedOptions'] ?? entry.content['options'];
    List<String> selectedOptions = [];
    if (rawOptions is List) {
      selectedOptions = rawOptions.map((e) => e.toString()).toList();
    }

    // Date formatting
    final formattedDate = DateFormat('EEEE, MMM d • h:mm a').format(entry.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.purple.withValues(alpha: 0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Gradient Social Header Banner ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode Badge Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(mode.emoji, style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Text(
                              mode.displayName,
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (entry.isSealedTimeCapsule)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 4),
                              Text(
                                'Sealed',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Large Question / Title Header Text
                  Text(
                    headerTitle,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom Card Body Section ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected Options Section (Matching attached mockup!)
                  if (selectedOptions.isNotEmpty) ...[
                    Text(
                      'Selected Options:',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: selectedOptions.map((opt) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_rounded, color: AppColors.purple, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                opt,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Specialized Body Content per Mode
                  _buildModeSpecificBody(context),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 12),

                  // Bottom Social Feed Footer Bar
                  Row(
                    children: [
                      // User Feed Avatar & Timestamp
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
                        ),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person_rounded, size: 15, color: AppColors.purple),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You • Journal Feed',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Mood Tag Pill
                      if (entry.moodTag != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF2F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFBCFE8)),
                          ),
                          child: Text(
                            entry.moodTag!,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.pink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Share to Community Button
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => ShareToCommunitySheet(entry: entry),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE9D5FF), width: 1),
                          ),
                          child: const Icon(
                            Icons.share_rounded,
                            color: Color(0xFF7C3AED),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSpecificBody(BuildContext context) {
    switch (entry.mode) {
      case JournalMode.videoDiary:
        final videoData = VideoDiaryData.fromJson(entry.content);
        return Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: videoData.videoPath != null
                      ? AppVideoPlayer(
                          videoPath: videoData.videoPath!,
                          autoPlay: true,
                          loop: true,
                          showControls: false,
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1F2937), Color(0xFF111827)],
                            ),
                          ),
                        ),
                ),
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: videoData.filterOverlayGradient,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFF7C3AED)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                  ),
                ),
                if (videoData.caption != null && videoData.caption!.isNotEmpty)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFBBF24), width: 1.2),
                      ),
                      child: Text(
                        videoData.caption!,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

      case JournalMode.moodColor:
        final tileData = AbstractMoodTileData.fromJson(entry.content);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AbstractMoodTileWidget(
                data: tileData,
                width: double.infinity,
                height: 180,
                borderRadius: 20,
              ),
            ),
            if (tileData.caption != null && tileData.caption!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Your Reflection:',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF4FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF5D0FE)),
                ),
                child: Text(
                  '“${tileData.caption!}”',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ],
        );

      case JournalMode.doodle:
        final rawStrokes = entry.content['strokes'] as List? ?? [];
        final strokes = rawStrokes
            .map((s) => DoodleStroke.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList();

        return Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: strokes.isNotEmpty
                ? CustomPaint(
                    painter: DoodlePainter(strokes: strokes),
                    size: Size.infinite,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎨', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        Text(
                          'Creative Doodle Page',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );

      case JournalMode.blackoutPoetry:
        final poem = (entry.content['poem'] as String?) ?? entry.preview;
        final selectedWords = (entry.content['selectedWords'] as List? ?? []).map((e) => e.toString()).toList();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B4B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF818CF8).withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('✒️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    'Blackout Poetry',
                    style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (selectedWords.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: selectedWords.map((w) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      w,
                      style: GoogleFonts.nunito(color: const Color(0xFF1E1B4B), fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                '“$poem”',
                style: GoogleFonts.nunito(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );

      case JournalMode.voiceNote:
        return _WaveformCard(entry: entry);

      default:
        final rawBody = (entry.content['text'] as String?) ??
            (entry.content['body'] as String?) ??
            (entry.content['answer'] as String?) ??
            entry.preview;

        final rawOptions = entry.content['selectedOptions'] ?? entry.content['options'];
        final hasOptions = rawOptions is List && rawOptions.isNotEmpty;

        if (rawBody.isEmpty && hasOptions) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Answer:',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              rawBody.isEmpty ? 'Recorded personal journal entry ✨' : rawBody,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ],
        );
    }
  }
}

class _WaveformCard extends StatefulWidget {
  final JournalEntry entry;
  const _WaveformCard({required this.entry});

  @override
  State<_WaveformCard> createState() => _WaveformCardState();
}

class _WaveformCardState extends State<_WaveformCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      final filePath = widget.entry.content['filePath'] as String?;
      if (filePath != null) {
        File audioFile = File(filePath);
        if (!audioFile.existsSync()) {
          final appDocDir = await getApplicationDocumentsDirectory();
          final fileName = filePath.split('/').last;
          final fallback = File('${appDocDir.path}/$fileName');
          if (fallback.existsSync()) audioFile = fallback;
        }
        if (audioFile.existsSync()) {
          await _audioPlayer.play(DeviceFileSource(audioFile.path));
        } else {
          await _audioPlayer.play(AssetSource('audio/journal_demo.mp3')).catchError((_) {});
        }
      } else {
        await _audioPlayer.play(AssetSource('audio/journal_demo.mp3')).catchError((_) {});
      }
      if (mounted) setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final durationSecs = widget.entry.content['durationSeconds'] as int? ?? 15;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDA4AF).withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Voice Note 🎤 (${durationSecs}s)', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textDark)),
            const SizedBox(height: 4),
            _WaveformVisual(isPlaying: _isPlaying),
          ]),
        ),
        Column(children: [
          if (widget.entry.moodTag != null) Text(widget.entry.moodTag!, style: const TextStyle(fontSize: 18)),
          Text(DateFormat('MMM d').format(widget.entry.createdAt), style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textLight)),
        ]),
      ]),
    );
  }
}

class _WaveformVisual extends StatelessWidget {
  final bool isPlaying;

  const _WaveformVisual({this.isPlaying = false});

  @override
  Widget build(BuildContext context) {
    final heights = [0.4, 0.8, 0.5, 1.0, 0.6, 0.9, 0.3, 0.7, 0.5, 0.8, 0.4, 0.6, 0.9, 0.5, 0.7];
    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: heights.asMap().entries.map((e) {
          final h = e.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: AnimatedContainer(
              duration: Duration(milliseconds: isPlaying ? 200 + (e.key * 50) % 250 : 300),
              width: 3,
              height: isPlaying ? 24 * h : 24 * 0.4,
              decoration: BoxDecoration(
                color: isPlaying ? const Color(0xFFEF4444) : const Color(0xFFF97316).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Mood Weather Bottom Sheet ─────────────────────────────────────────────────

class _MoodWeatherSheet extends StatelessWidget {
  final Map<String, dynamic> heatmap;
  const _MoodWeatherSheet({required this.heatmap});

  @override
  Widget build(BuildContext context) {
    final activeDaysCount = heatmap.keys.map((k) => k.length >= 10 ? k.substring(0, 10) : k).toSet().length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🌤 Mood Weather', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                  Text('Your emotional landscape this season', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMedium)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$activeDaysCount Days Tracked ✨',
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.purple),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCalendarGrid(context),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(const Color(0xFF7C3AED), 'Guided Prompt'),
              const SizedBox(width: 10),
              _buildLegendDot(const Color(0xFFEC4899), 'Free Write'),
              const SizedBox(width: 10),
              _buildLegendDot(const Color(0xFFF59E0B), 'Mood Canvas'),
              const SizedBox(width: 10),
              _buildLegendDot(Colors.grey.shade200, 'No Entry'),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(84, (i) => now.subtract(Duration(days: 83 - i)));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 12, mainAxisSpacing: 5, crossAxisSpacing: 5),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final key = DateFormat('yyyy-MM-dd').format(days[i]);
        final data = heatmap[key] as Map<String, dynamic>?;
        final colorStr = data?['color'] as String?;
        final tag = data?['tag'] as String?;
        final isTracked = colorStr != null;

        final displayColor = isTracked ? _hexToColor(colorStr) : Colors.grey.shade100;
        final formattedDateStr = DateFormat('MMM d, yyyy').format(days[i]);

        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isTracked ? '📅 $formattedDateStr • $tag' : '📅 $formattedDateStr • No journal entry',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: Colors.white),
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: isTracked ? displayColor : Colors.grey.shade800,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            );
          },
          child: Tooltip(
            message: isTracked ? '$key · $tag' : key,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isTracked ? displayColor.withValues(alpha: 0.8) : Colors.grey.shade200,
                  width: isTracked ? 1 : 0.5,
                ),
                boxShadow: isTracked ? [
                  BoxShadow(
                    color: displayColor.withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _hexToColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF7C3AED);
    }
  }
}


