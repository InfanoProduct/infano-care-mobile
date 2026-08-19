library;

/// Creative Journey v2 — plain Dart models (no code generation required).
/// These models are intentionally separate from the existing LearningJourney models.

class CreativeJourney {
  final String id;
  final String title;
  final String description;
  final String? ageBand;
  final String? icon;
  final bool isActive;
  final List<CreativeEpisode> episodes;

  const CreativeJourney({
    required this.id,
    required this.title,
    required this.description,
    this.ageBand,
    this.icon,
    this.isActive = true,
    this.episodes = const [],
  });

  factory CreativeJourney.fromJson(Map<String, dynamic> json) {
    return CreativeJourney(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      ageBand: json['ageBand'] as String?,
      icon: json['icon'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      episodes: (json['episodes'] as List<dynamic>?)
              ?.map((e) => CreativeEpisode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CreativeEpisode {
  final String id;
  final String journeyId;
  final String title;
  final String? description;
  final String? episodeIcon;
  final int order;
  final List<CreativeNode> nodes;
  final int totalXP;
  final bool isActive;

  const CreativeEpisode({
    required this.id,
    required this.journeyId,
    required this.title,
    this.description,
    this.episodeIcon,
    this.order = 0,
    this.nodes = const [],
    this.totalXP = 145,
    this.isActive = true,
  });

  factory CreativeEpisode.fromJson(Map<String, dynamic> json) {
    return CreativeEpisode(
      id: json['id'] as String,
      journeyId: json['journeyId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      episodeIcon: json['episodeIcon'] as String?,
      order: json['order'] as int? ?? 0,
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((n) => CreativeNode.fromJson(n as Map<String, dynamic>))
              .toList() ??
          [],
      totalXP: json['totalCoins'] as int? ?? json['totalXP'] as int? ?? 83,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class CreativeNode {
  final String nodeId;
  final String type;
  final String title;
  final String position; // fixed_start | random_pool | fixed_end
  final String? energyTag; // active | reflective
  final int xpReward;
  final Map<String, dynamic>? content;

  const CreativeNode({
    required this.nodeId,
    required this.type,
    required this.title,
    required this.position,
    this.energyTag,
    this.xpReward = 10,
    this.content,
  });

  factory CreativeNode.fromJson(Map<String, dynamic> json) {
    return CreativeNode(
      nodeId: json['nodeId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      position: json['position'] as String,
      energyTag: json['energyTag'] as String?,
      xpReward: json['xpReward'] as int? ?? 10,
      content: json['content'] as Map<String, dynamic>?,
    );
  }

  String get emoji {
    switch (type) {
      case 'story':
        return '📖';
      case 'mystery_task_box':
        return '🎁';
      case 'quiz':
        return '❓';
      case 'watch_video':
        return '🎬';
      case 'identify_image':
        return '🔍';
      case 'myth_busters':
        return '🚫';
      case 'timeline_builder':
        return '🧩';
      case 'spot_the_change':
        return '🕵️';
      case 'mirror_reflection_flip':
        return '🪞';
      case 'comparison_filter_unmask':
        return '🔍';
      case 'body_appreciation_jar':
        return '🫙';
      case 'reflection_reward':
        return '🏆';
      default:
        return '⭐';
    }
  }
}

// ── Node Progress ──────────────────────────────────────────────────────────────

enum NodeStatus { locked, unlocked, inProgress, completed }

class CreativeNodeProgress {
  final String nodeId;
  final String status;
  final int xpEarned;
  final String? lastScreen;

  const CreativeNodeProgress({
    required this.nodeId,
    this.status = 'LOCKED',
    this.xpEarned = 0,
    this.lastScreen,
  });

  factory CreativeNodeProgress.fromJson(Map<String, dynamic> json) {
    return CreativeNodeProgress(
      nodeId: json['nodeId'] as String,
      status: json['status'] as String? ?? 'LOCKED',
      xpEarned: json['xpEarned'] as int? ?? 0,
      lastScreen: json['lastScreen'] as String?,
    );
  }

  CreativeNodeProgress copyWith({String? status, int? xpEarned, String? lastScreen}) {
    return CreativeNodeProgress(
      nodeId: nodeId,
      status: status ?? this.status,
      xpEarned: xpEarned ?? this.xpEarned,
      lastScreen: lastScreen ?? this.lastScreen,
    );
  }

  bool get isLocked => status == 'LOCKED';
  bool get isUnlocked => status == 'UNLOCKED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isCompleted => status == 'COMPLETED';
  bool get isTappable => status == 'UNLOCKED' || status == 'IN_PROGRESS' || status == 'COMPLETED';
}

typedef NodeProgress = CreativeNodeProgress;

// ── Episode Progress (aggregate) ───────────────────────────────────────────────

class EpisodeProgress {
  final String episodeId;
  final List<String> nodeOrder;
  final Map<String, CreativeNodeProgress> nodeProgresses;

  const EpisodeProgress({
    required this.episodeId,
    this.nodeOrder = const [],
    this.nodeProgresses = const {},
  });

  int get totalXpEarned =>
      nodeProgresses.values.fold(0, (sum, p) => sum + p.xpEarned);

  int get completedCount =>
      nodeProgresses.values.where((p) => p.isCompleted).length;

  bool get isFullyCompleted =>
      nodeOrder.isNotEmpty &&
      completedCount == nodeOrder.length;

  CreativeNodeProgress progressForNode(String nodeId) {
    return nodeProgresses[nodeId] ?? CreativeNodeProgress(nodeId: nodeId);
  }

  EpisodeProgress copyWithNodeProgress(CreativeNodeProgress progress) {
    final updated = Map<String, CreativeNodeProgress>.from(nodeProgresses);
    updated[progress.nodeId] = progress;
    return EpisodeProgress(
      episodeId: episodeId,
      nodeOrder: nodeOrder,
      nodeProgresses: updated,
    );
  }
}
