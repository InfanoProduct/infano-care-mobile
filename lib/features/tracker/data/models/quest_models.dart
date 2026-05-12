import 'package:json_annotation/json_annotation.dart';

part 'quest_models.g.dart';

@JsonSerializable()
class QuestTemplate {
  final String id;
  final String type;
  final String category;
  final String title;
  final String description;
  final int pointsBase;
  final int? pointsMax;
  final String difficulty;
  final int estimatedMinutes;
  final Map<String, dynamic>? completionCondition;
  final String? badgeRewardId;

  QuestTemplate({
    required this.id,
    this.type = 'daily',
    this.category = 'wildcard',
    this.title = 'New Quest',
    this.description = '',
    this.pointsBase = 0,
    this.pointsMax,
    this.difficulty = 'standard',
    this.estimatedMinutes = 5,
    this.completionCondition,
    this.badgeRewardId,
  });

  factory QuestTemplate.fromJson(Map<String, dynamic> json) => _$QuestTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$QuestTemplateToJson(this);
}

@JsonSerializable()
class UserQuest {
  final String id;
  final String userId;
  final String questTemplateId;
  final DateTime questDate;
  final String status; // 'available'|'accepted'|'completed'|'expired'
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final int? pointsAwarded;
  final QuestTemplate questTemplate;

  UserQuest({
    required this.id,
    required this.userId,
    required this.questTemplateId,
    required this.questDate,
    required this.status,
    this.acceptedAt,
    this.completedAt,
    this.pointsAwarded,
    required this.questTemplate,
  });

  factory UserQuest.fromJson(Map<String, dynamic> json) => _$UserQuestFromJson(json);
  Map<String, dynamic> toJson() => _$UserQuestToJson(this);
}

@JsonSerializable()
class Badge {
  final String id;
  final String? slug;
  final String name;
  final String? description;
  final String? collection;
  final String? rarity;
  final String? illustrationUrl;
  final bool isAnimated;
  final bool isEarned;
  final DateTime? awardedAt;

  Badge({
    required this.id,
    this.slug,
    this.name = 'New Badge',
    this.description,
    this.collection,
    this.rarity = 'common',
    this.illustrationUrl,
    this.isAnimated = false,
    this.isEarned = false,
    this.awardedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);
  Map<String, dynamic> toJson() => _$BadgeToJson(this);
}

@JsonSerializable()
class UserQuestProgress {
  final int pointsTotal;
  final int currentLevel;
  final DateTime? lastLevelUpAt;
  final int logStreak;
  final int badgesEarned;

  UserQuestProgress({
    this.pointsTotal = 0,
    this.currentLevel = 1,
    this.lastLevelUpAt,
    this.logStreak = 0,
    this.badgesEarned = 0,
  });

  factory UserQuestProgress.fromJson(Map<String, dynamic> json) => _$UserQuestProgressFromJson(json);
  Map<String, dynamic> toJson() => _$UserQuestProgressToJson(this);
}
