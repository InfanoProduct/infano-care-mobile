import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import '../application/episode_path_cubit.dart';
import '../models/creative_journey_models.dart';
import '../repositories/creative_journey_repository.dart';
import '../widgets/node_bubble_widget.dart';
import '../widgets/badge_ceremony_widget.dart';
import '../widgets/journey_path_painter.dart';
import 'node_activity_screen.dart';

class EpisodePathScreen extends StatelessWidget {
  final String episodeId;
  const EpisodePathScreen({super.key, required this.episodeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => EpisodePathCubit(
        CreativeJourneyRepository(ApiService.instance.dio),
      )..loadEpisode(episodeId),
      child: _EpisodePathView(episodeId: episodeId),
    );
  }
}

class _EpisodePathView extends StatelessWidget {
  final String episodeId;
  const _EpisodePathView({required this.episodeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: BlocConsumer<EpisodePathCubit, EpisodePathState>(
        listener: (context, state) {
          if (state is EpisodePathLoaded) {
            // Show master badge ceremony as overlay when episode is fully completed and no dialog is active
            if (state.showBadgeCeremony && state.pendingRewards.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ModalRoute.of(context)?.isCurrent ?? false) {
                  _showBadgeCeremonyModal(context, state);
                }
              });
            }
          }
        },
        builder: (context, state) {
          return switch (state) {
            EpisodePathLoading() || EpisodePathInitial() => _buildLoading(),
            EpisodePathError(message: final msg) => _buildError(msg),
            EpisodePathLoaded() => _buildPath(context, state),
          };
        },
      ),
    );
  }

  void _showBadgeCeremonyModal(BuildContext context, EpisodePathLoaded state) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (ctx, a1, a2) => BadgeCeremonyWidget(
          episodeTitle: state.episode.title,
          nextEpisode: state.nextEpisode,
          onExploreNextEpisode: (nextEp) {
            Navigator.of(ctx).pop();
            context.read<EpisodePathCubit>().clearBadgeCeremony();
            context.read<EpisodePathCubit>().clearPendingRewards();
            context.go('/creative-journey/journey/${state.episode.journeyId}');
          },
          onDismiss: () {
            Navigator.of(ctx).pop();
            context.read<EpisodePathCubit>().clearBadgeCeremony();
            context.read<EpisodePathCubit>().clearPendingRewards();
            context.go('/creative-journey/journey/${state.episode.journeyId}');
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🗺️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text('Building your path...', style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMedium)),
      ]),
    );
  }

  Widget _buildError(String msg) {
    return Center(child: Text('Error: $msg'));
  }

  Widget _buildPath(BuildContext context, EpisodePathLoaded state) {
    final totalNodes = state.orderedNodes.length;
    final totalItems = totalNodes > 0 ? totalNodes * 2 - 1 : 0;

    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppColors.purple,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildEpisodeHeader(context, state),
          ),
        ),

        // Path nodes & dotted connectors
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, itemIndex) {
                if (itemIndex.isEven) {
                  final nodeIndex = itemIndex ~/ 2;
                  return _buildNodeRow(context, state, nodeIndex);
                } else {
                  final fromNodeIndex = itemIndex ~/ 2;
                  final fromNode = state.orderedNodes[fromNodeIndex];
                  final toNode = state.orderedNodes[fromNodeIndex + 1];
                  final fromProgress = state.progressForNode(fromNode.nodeId);
                  final toProgress = state.progressForNode(toNode.nodeId);

                  return NodeConnectorWidget(
                    startFromLeft: fromNodeIndex.isEven,
                    isCompleted: fromProgress.isCompleted && toProgress.isCompleted,
                    isUnlocked: toProgress.isUnlocked || toProgress.isInProgress || toProgress.isCompleted,
                  );
                }
              },
              childCount: totalItems,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeHeader(BuildContext context, EpisodePathLoaded state) {
    final isAllDone = state.orderedNodes.isNotEmpty &&
        state.completedCount >= state.orderedNodes.length;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(state.episode.episodeIcon ?? '🗺️', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.episode.title,
                    style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark),
                  ),
                ),
                // XP counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🪙', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text('${state.totalXpEarned} Coins', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF92400E))),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: state.orderedNodes.isEmpty
                      ? 0
                      : state.completedCount / state.orderedNodes.length,
                  backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(AppColors.purple),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.completedCount} of ${state.orderedNodes.length} nodes completed',
                    style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w700),
                  ),
                  if (isAllDone)
                    GestureDetector(
                      onTap: () => _showBadgeCeremonyModal(context, state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.purple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🏆', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(
                              'View Badge',
                              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
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
      ),
    );
  }

  Widget _buildNodeRow(BuildContext context, EpisodePathLoaded state, int index) {
    final node = state.orderedNodes[index];
    final progress = state.progressForNode(node.nodeId);

    // Alternating left-right layout for winding path feel
    final isLeft = index.isEven;

    return Container(
      child: Row(
        children: [
          if (!isLeft) const Spacer(),

          // Node bubble
          SizedBox(
            width: 200,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLeft) ...[
                  NodeBubbleWidget(
                    node: node,
                    progress: progress,
                    index: index,
                    onTap: () => _openActivity(context, state, node, progress),
                  ).animate(target: progress.isUnlocked ? 1 : 0)
                      .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildNodeLabel(node, progress, isLeft: true)),
                ] else ...[
                  Expanded(child: _buildNodeLabel(node, progress, isLeft: false)),
                  const SizedBox(width: 12),
                  NodeBubbleWidget(
                    node: node,
                    progress: progress,
                    index: index,
                    onTap: () => _openActivity(context, state, node, progress),
                  ).animate(target: progress.isUnlocked ? 1 : 0)
                      .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.3)),
                ],
              ],
            ),
          ),

          if (isLeft) const Spacer(),
        ],
      ).animate().fadeIn(delay: (index * 60).ms, duration: 400.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildNodeLabel(CreativeNode node, NodeProgress progress, {required bool isLeft}) {
    final title = node.title;
    final typeLabel = node.type.replaceAll('_', ' ').toUpperCase();

    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          typeLabel,
          style: GoogleFonts.nunito(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: progress.isCompleted
                ? AppColors.purple
                : progress.isUnlocked
                    ? AppColors.pink
                    : AppColors.textLight,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          textAlign: isLeft ? TextAlign.left : TextAlign.right,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: progress.isLocked ? AppColors.textLight : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  ChestReward _buildChestRewardForNode(EpisodePathLoaded state, String nodeId) {
    final idx = state.orderedNodes.indexWhere((n) => n.nodeId == nodeId);
    final safeIdx = idx >= 0 ? idx : 0;

    const templates = [
      {'name': 'Mystery Letter Scroll', 'emoji': '📜', 'desc': 'Discovered Meera\'s letter — first piece of the Episode Badge!'},
      {'name': 'Fit Check Compass', 'emoji': '🧭', 'desc': 'Mastered fit clues — second piece snapped into place!'},
      {'name': 'Bra Matcher Trophy', 'emoji': '👚', 'desc': 'Matched every bra type — third piece collected!'},
      {'name': 'Timeline Star', 'emoji': '⭐', 'desc': 'Built your unique timeline — fourth piece unlocked!'},
      {'name': 'Confidence Crest', 'emoji': '🏆', 'desc': 'Final piece acquired! The Master Badge is ready for assembly!'},
    ];

    final template = templates[safeIdx % templates.length];
    final totalNodes = state.orderedNodes.length;
    final totalPieces = totalNodes > 0 ? totalNodes : 5;
    final pieceIndex = safeIdx + 1;

    return ChestReward(
      assetName: template['name']!,
      assetEmoji: template['emoji']!,
      assetDescription: template['desc']!,
      currentPieceIndex: pieceIndex,
      totalPieces: totalPieces,
      nodeIndex: safeIdx,
      badgeTitle: '${state.episode.title.replaceAll(RegExp(r'^\d+\.\s*'), '')} Master Badge',
    );
  }

  void _openActivity(BuildContext context, EpisodePathLoaded state, CreativeNode node, NodeProgress progress) {
    if (!progress.isTappable) return;

    context.read<EpisodePathCubit>().startNode(episodeId, node.nodeId);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (activityContext) => BlocProvider.value(
          value: context.read<EpisodePathCubit>(),
          child: NodeActivityScreen(
            node: node,
            episodeId: episodeId,
            isAlreadyCompleted: progress.isCompleted,
            episodeTitle: state.episode.title.replaceAll(RegExp(r'^\d+\.\s*'), ''),
            onCompleted: (xpEarned) async {
              final cubit = context.read<EpisodePathCubit>();

              // 1. Build reward & start background sync immediately
              ChestReward? reward;
              final currentState = cubit.state;
              if (currentState is EpisodePathLoaded) {
                reward = _buildChestRewardForNode(currentState, node.nodeId);
              }

              // Fire network sync asynchronously in background — DO NOT AWAIT!
              cubit.completeNode(episodeId, node.nodeId, xpEarned);

              // 2. Open Discovery Chest modal immediately
              if (reward != null && activityContext.mounted) {
                await showGeneralDialog(
                  context: activityContext,
                  barrierDismissible: false,
                  barrierLabel: 'Discovery Chest',
                  barrierColor: Colors.black.withValues(alpha: 0.78),
                  transitionDuration: const Duration(milliseconds: 350),
                  pageBuilder: (dialogCtx, anim1, anim2) => DiscoveryChestScreen(
                    reward: reward!,
                    onClose: () {
                      // Smoothly dismiss both dialog AND activity screen in one seamless transition!
                      Navigator.of(dialogCtx).pop();
                      if (activityContext.mounted) {
                        Navigator.of(activityContext).pop();
                      }
                      cubit.clearPendingRewards();
                    },
                  ),
                  transitionBuilder: (context, animation, secondaryAnimation, child) {
                    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
                    return ScaleTransition(
                      scale: curved,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                );
              } else if (activityContext.mounted) {
                Navigator.of(activityContext).pop();
              }

              // 3. AFTER ActivityScreen pops, check if episode is completed or if final node finished!
              if (context.mounted) {
                final endState = cubit.state;
                if (endState is EpisodePathLoaded) {
                  final isFinalNode = node.nodeId == 'bb_reflection' ||
                      node.type == 'reflection_reward' ||
                      node.position == 'fixed_end' ||
                      (endState.orderedNodes.isNotEmpty &&
                          endState.orderedNodes.last.nodeId == node.nodeId);

                  final isEpisodeDone = endState.showBadgeCeremony ||
                      isFinalNode ||
                      (endState.orderedNodes.isNotEmpty &&
                          endState.completedCount >= endState.orderedNodes.length);
                  if (isEpisodeDone) {
                    _showBadgeCeremonyModal(context, endState);
                  }
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
