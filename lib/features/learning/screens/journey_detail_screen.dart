import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../application/journey_detail_bloc.dart';
import '../models/learning_models.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class JourneyDetailScreen extends StatefulWidget {
  final String journeyId;

  const JourneyDetailScreen({super.key, required this.journeyId});

  @override
  State<JourneyDetailScreen> createState() => _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends State<JourneyDetailScreen> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    context.read<JourneyDetailBloc>().add(JourneyDetailEvent.loadJourney(widget.journeyId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<JourneyDetailBloc, JourneyDetailState>(
        builder: (context, state) {
          return state.maybeWhen(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (msg) => Center(child: Text('Error: $msg')),
            loaded: (journey, userProgress) {
              // Calculate overall journey progress
              final episodeIds = journey.episodes.map((e) => e.id).toList();
              final completedIds = userProgress
                  .where((p) => episodeIds.contains(p.episodeId) && p.completed)
                  .map((p) => p.episodeId)
                  .toSet();
              
              final completedCount = completedIds.length;
              final totalCount = journey.episodes.length;
              final progressPercent = totalCount > 0 ? completedCount / totalCount : 0.0;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(journey, progressPercent),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About this Journey',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ).animate().fadeIn(delay: 100.ms).moveX(begin: -10),
                          const SizedBox(height: 12),
                          Text(
                            journey.description,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Path to Mastery',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '$completedCount / $totalCount Completed',
                                style: TextStyle(
                                  color: Colors.deepPurple.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 300.ms),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final episode = journey.episodes[index];
                          
                          // LOCKING LOGIC:
                          // 1. First episode is always unlocked
                          // 2. Subsequent episodes are unlocked if the PREVIOUS one is completed
                          // 3. Or if the current one is already marked completed
                          final isCompleted = completedIds.contains(episode.id);
                          final isFirst = index == 0;
                          final prevCompleted = index > 0 && completedIds.contains(journey.episodes[index - 1].id);
                          final isUnlocked = isFirst || prevCompleted || isCompleted;

                          return _EpisodeListItem(
                            episode: episode,
                            index: index,
                            isUnlocked: isUnlocked,
                            isCompleted: isCompleted,
                            onTap: () async {
                              if (isUnlocked) {
                                final result = await context.push(
                                  '/journey/${journey.id}/episode/${episode.id}',
                                  extra: episode,
                                );
                                // If player returns with 'true', refresh the list to show new completion
                                if (result == true) {
                                  _refresh();
                                } else {
                                  // Always refresh for now to be safe with progress tracking
                                  _refresh();
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Complete previous episodes to unlock this activity!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ).animate().fadeIn(delay: (400 + index * 100).ms).moveY(begin: 20);
                        },
                        childCount: journey.episodes.length,
                      ),
                    ),
                  ),
                ],
              );
            },
            orElse: () => const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(LearningJourney journey, double progress) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.deepPurple,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (journey.bannerImage != null || journey.thumbnailUrl != null)
              Image.network(
                journey.bannerImage ?? journey.thumbnailUrl!,
                fit: BoxFit.cover,
              )
            else
              Container(color: Colors.deepPurple.shade300),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Title and Progress info in the expanded area
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      journey.category ?? 'Journey',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    journey.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 8,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeListItem extends StatelessWidget {
  final Episode episode;
  final int index;
  final bool isUnlocked;
  final bool isCompleted;
  final VoidCallback onTap;

  const _EpisodeListItem({
    required this.episode,
    required this.index,
    required this.isUnlocked,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isUnlocked ? Colors.deepPurple.withOpacity(0.1) : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Activity Number or Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _getStatusIcon(),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Title and Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity ${index + 1}',
                        style: TextStyle(
                          color: isUnlocked ? Colors.deepPurple : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        episode.title,
                        style: TextStyle(
                          color: isUnlocked ? Colors.black87 : Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isUnlocked) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${episode.points} Points',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Action Icon
                if (isUnlocked)
                   Icon(
                    isCompleted ? Icons.check_circle : Icons.play_arrow_rounded,
                    color: isCompleted ? Colors.green : Colors.deepPurple,
                    size: 30,
                  )
                else
                   Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (isCompleted) return Colors.green;
    if (isUnlocked) return Colors.deepPurple;
    return Colors.grey;
  }

  Widget _getStatusIcon() {
    if (isCompleted) return const Icon(Icons.check, color: Colors.green, size: 24);
    if (isUnlocked) return Text('${index + 1}', style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 18));
    return const Icon(Icons.lock, color: Colors.grey, size: 20);
  }
}
