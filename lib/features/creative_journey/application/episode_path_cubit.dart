import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/creative_journey_models.dart';
import '../repositories/creative_journey_repository.dart';

// ── State ──────────────────────────────────────────────────────────────────────

sealed class EpisodePathState {
  const EpisodePathState();
}

class EpisodePathInitial extends EpisodePathState {}

class EpisodePathLoading extends EpisodePathState {}

class EpisodePathLoaded extends EpisodePathState {
  final CreativeEpisode episode;
  final CreativeEpisode? nextEpisode;
  final List<CreativeNode> orderedNodes;
  final Map<String, CreativeNodeProgress> nodeProgressMap;
  final List<ChestReward> pendingRewards;
  final bool showBadgeCeremony;

  const EpisodePathLoaded({
    required this.episode,
    this.nextEpisode,
    required this.orderedNodes,
    required this.nodeProgressMap,
    this.pendingRewards = const [],
    this.showBadgeCeremony = false,
  });

  EpisodePathLoaded copyWith({
    CreativeEpisode? episode,
    CreativeEpisode? nextEpisode,
    List<CreativeNode>? orderedNodes,
    Map<String, CreativeNodeProgress>? nodeProgressMap,
    List<ChestReward>? pendingRewards,
    bool? showBadgeCeremony,
  }) {
    return EpisodePathLoaded(
      episode: episode ?? this.episode,
      nextEpisode: nextEpisode ?? this.nextEpisode,
      orderedNodes: orderedNodes ?? this.orderedNodes,
      nodeProgressMap: nodeProgressMap ?? this.nodeProgressMap,
      pendingRewards: pendingRewards ?? this.pendingRewards,
      showBadgeCeremony: showBadgeCeremony ?? this.showBadgeCeremony,
    );
  }

  CreativeNodeProgress progressForNode(String nodeId) =>
      nodeProgressMap[nodeId] ?? CreativeNodeProgress(nodeId: nodeId);

  int get completedCount =>
      nodeProgressMap.values.where((p) => p.status == 'COMPLETED').length;

  double get progressFraction =>
      orderedNodes.isEmpty ? 0 : completedCount / orderedNodes.length;

  int get totalXPEarned =>
      nodeProgressMap.values.fold(0, (sum, p) => sum + p.xpEarned);

  int get totalXpEarned => totalXPEarned;
}

class EpisodePathError extends EpisodePathState {
  final String message;
  EpisodePathError(this.message);
}

// ── Chest Badge Asset Reward ──────────────────────────────────────────────────

class ChestReward {
  final String assetName;
  final String assetEmoji;
  final String assetDescription;
  final int currentPieceIndex;
  final int totalPieces;
  final int nodeIndex;
  final String badgeTitle;

  const ChestReward({
    required this.assetName,
    required this.assetEmoji,
    required this.assetDescription,
    required this.currentPieceIndex,
    required this.totalPieces,
    required this.nodeIndex,
    required this.badgeTitle,
  });

  double get assemblyProgress => currentPieceIndex / totalPieces;
}

// ── Cubit ──────────────────────────────────────────────────────────────────────

class EpisodePathCubit extends Cubit<EpisodePathState> {
  final CreativeJourneyRepository _repo;

  static const List<Map<String, String>> _badgeAssetTemplates = [
    {
      'name': 'Mystery Letter Scroll',
      'emoji': '📜',
      'desc': 'Discovered Mira\'s future letter — first piece of the Episode Badge!',
    },
    {
      'name': 'Doorframe Ruler',
      'emoji': '📐',
      'desc': 'Measured puberty milestones — second piece snapped into place!',
    },
    {
      'name': 'Growth Compass',
      'emoji': '🧭',
      'desc': 'Mastered growth spurt timing — third piece collected!',
    },
    {
      'name': 'Confidence Star',
      'emoji': '⭐',
      'desc': 'Built your unique timeline — fourth piece unlocked!',
    },
    {
      'name': 'Timeline Crest',
      'emoji': '🏆',
      'desc': 'Final piece acquired! The Master Badge is ready for assembly!',
    },
  ];

  EpisodePathCubit(this._repo) : super(EpisodePathInitial());

  Future<void> loadEpisode(String episodeId) async {
    emit(EpisodePathLoading());
    try {
      final episode = await _repo.getEpisode(episodeId);
      final nodeOrderIds = await _repo.getOrCreateNodeOrder(episodeId);
      final progressList = await _repo.getEpisodeProgress(episodeId);

      CreativeEpisode? nextEpisode;
      try {
        final journey = await _repo.getJourney(episode.journeyId);
        final sortedEpisodes = List<CreativeEpisode>.from(journey.episodes)
          ..sort((a, b) => a.order.compareTo(b.order));
        final currIndex = sortedEpisodes.indexWhere((e) => e.id == episodeId);
        if (currIndex != -1 && currIndex + 1 < sortedEpisodes.length) {
          nextEpisode = sortedEpisodes[currIndex + 1];
        }
      } catch (_) {}

      final rawProgressMap = <String, CreativeNodeProgress>{};
      for (final p in progressList) {
        rawProgressMap[p.nodeId] = p;
      }

      final orderedNodes = <CreativeNode>[];
      for (final id in nodeOrderIds) {
        final match = episode.nodes.where((n) => n.nodeId == id);
        if (match.isNotEmpty) {
          orderedNodes.add(match.first);
        }
      }
      for (final n in episode.nodes) {
        if (!nodeOrderIds.contains(n.nodeId)) {
          orderedNodes.add(n);
        }
      }

      // Enforce strict sequential unlocking: Node 0 is at least UNLOCKED.
      // Node i (i > 0) is UNLOCKED/COMPLETED only if Node i-1 is COMPLETED.
      final computedProgressMap = <String, CreativeNodeProgress>{};
      bool previousCompleted = true;

      for (int i = 0; i < orderedNodes.length; i++) {
        final node = orderedNodes[i];
        final raw = rawProgressMap[node.nodeId];

        if (previousCompleted) {
          if (raw != null && raw.status == 'COMPLETED') {
            computedProgressMap[node.nodeId] = raw;
            previousCompleted = true;
          } else {
            computedProgressMap[node.nodeId] = CreativeNodeProgress(
              nodeId: node.nodeId,
              status: 'UNLOCKED',
              xpEarned: raw?.xpEarned ?? 0,
              lastScreen: raw?.lastScreen,
            );
            previousCompleted = false;
          }
        } else {
          computedProgressMap[node.nodeId] = CreativeNodeProgress(
            nodeId: node.nodeId,
            status: 'LOCKED',
            xpEarned: 0,
          );
          previousCompleted = false;
        }
      }

      emit(EpisodePathLoaded(
        episode: episode,
        nextEpisode: nextEpisode,
        orderedNodes: orderedNodes,
        nodeProgressMap: computedProgressMap,
      ));
    } catch (e) {
      emit(EpisodePathError(e.toString()));
    }
  }

  Future<void> startNode(String episodeId, String nodeId) async {
    final curr = state;
    if (curr is! EpisodePathLoaded) return;

    try {
      final existing = curr.nodeProgressMap[nodeId];
      if (existing == null || existing.status == 'LOCKED') {
        await _repo.updateNodeProgress(
          episodeId: episodeId,
          nodeId: nodeId,
          status: 'UNLOCKED',
        );
        final updatedList = await _repo.getEpisodeProgress(episodeId);
        final updatedMap = <String, CreativeNodeProgress>{};
        for (final p in updatedList) {
          updatedMap[p.nodeId] = p;
        }
        emit(curr.copyWith(nodeProgressMap: updatedMap));
      }
    } catch (_) {}
  }

  Future<void> completeNode(String episodeId, String nodeId, int xpEarned) async {
    final curr = state;
    if (curr is! EpisodePathLoaded) return;

    try {
      await _repo.updateNodeProgress(
        episodeId: episodeId,
        nodeId: nodeId,
        status: 'COMPLETED',
        xpEarned: xpEarned,
      );

      final nodeOrderIds = await _repo.getOrCreateNodeOrder(episodeId);
      final updatedProgressList = await _repo.getEpisodeProgress(episodeId);
      final updatedMap = <String, CreativeNodeProgress>{};
      for (final p in updatedProgressList) {
        updatedMap[p.nodeId] = p;
      }

      final orderedNodes = <CreativeNode>[];
      for (final id in nodeOrderIds) {
        final match = curr.episode.nodes.where((n) => n.nodeId == id);
        if (match.isNotEmpty) {
          orderedNodes.add(match.first);
        }
      }
      for (final n in curr.episode.nodes) {
        if (!nodeOrderIds.contains(n.nodeId)) {
          orderedNodes.add(n);
        }
      }

      // Enforce strict single-node sequential unlocking:
      // Exactly ONE next node is UNLOCKED after the completed node. All subsequent nodes are LOCKED.
      final computedProgressMap = <String, CreativeNodeProgress>{};
      bool previousCompleted = true;

      for (int i = 0; i < orderedNodes.length; i++) {
        final n = orderedNodes[i];
        final raw = updatedMap[n.nodeId];

        if (previousCompleted) {
          if (raw != null && (raw.status == 'COMPLETED' || n.nodeId == nodeId)) {
            computedProgressMap[n.nodeId] = CreativeNodeProgress(
              nodeId: n.nodeId,
              status: 'COMPLETED',
              xpEarned: raw.xpEarned > 0 ? raw.xpEarned : (n.nodeId == nodeId ? xpEarned : 10),
              lastScreen: raw.lastScreen,
            );
            previousCompleted = true;
          } else {
            computedProgressMap[n.nodeId] = CreativeNodeProgress(
              nodeId: n.nodeId,
              status: 'UNLOCKED',
              xpEarned: raw?.xpEarned ?? 0,
              lastScreen: raw?.lastScreen,
            );
            previousCompleted = false;
          }
        } else {
          computedProgressMap[n.nodeId] = CreativeNodeProgress(
            nodeId: n.nodeId,
            status: 'LOCKED',
            xpEarned: 0,
          );
          previousCompleted = false;
        }
      }

      final nodeIdx = orderedNodes.indexWhere((n) => n.nodeId == nodeId);
      final totalNodes = orderedNodes.length;

      // Determine Badge Asset piece reward for this node
      final totalPieces = totalNodes > 0 ? totalNodes : 5;
      final pieceIndex = (nodeIdx >= 0 ? nodeIdx : 0) + 1;
      final template = _badgeAssetTemplates[(nodeIdx >= 0 ? nodeIdx : 0) % _badgeAssetTemplates.length];

      final reward = ChestReward(
        assetName: template['name']!,
        assetEmoji: template['emoji']!,
        assetDescription: template['desc']!,
        currentPieceIndex: pieceIndex,
        totalPieces: totalPieces,
        nodeIndex: nodeIdx,
        badgeTitle: '${curr.episode.title.replaceAll(RegExp(r'^\d+\.\s*'), '')} Master Badge',
      );

      final isAllCompleted = orderedNodes.every((n) => computedProgressMap[n.nodeId]?.status == 'COMPLETED') ||
          nodeId == 'bb_reflection' ||
          nodeId.endsWith('_reflection') ||
          (orderedNodes.isNotEmpty && orderedNodes.last.nodeId == nodeId);

      emit(curr.copyWith(
        orderedNodes: orderedNodes,
        nodeProgressMap: computedProgressMap,
        pendingRewards: [reward],
        showBadgeCeremony: isAllCompleted,
      ));
    } catch (e) {
      // Retain current view on error
    }
  }

  void clearPendingRewards() {
    final curr = state;
    if (curr is EpisodePathLoaded) {
      emit(curr.copyWith(pendingRewards: []));
    }
  }

  void clearBadgeCeremony() {
    final curr = state;
    if (curr is EpisodePathLoaded) {
      emit(curr.copyWith(showBadgeCeremony: false));
    }
  }
}
