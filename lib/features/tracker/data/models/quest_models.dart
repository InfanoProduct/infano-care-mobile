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
  final Map<String, dynamic>? progressJson;

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
    this.progressJson,
  });

  factory UserQuest.fromJson(Map<String, dynamic> json) => _$UserQuestFromJson(json);
  Map<String, dynamic> toJson() => _$UserQuestToJson(this);
}

@JsonSerializable()
class BadgeQuestLink {
  final String id;
  final String title;
  final String description;
  final String category;
  final int pointsBase;
  final String difficulty;
  final int estimatedMinutes;
  final Map<String, dynamic>? completionCondition;

  BadgeQuestLink({
    required this.id,
    this.title = '',
    this.description = '',
    this.category = 'wildcard',
    this.pointsBase = 0,
    this.difficulty = 'standard',
    this.estimatedMinutes = 5,
    this.completionCondition,
  });

  factory BadgeQuestLink.fromJson(Map<String, dynamic> json) =>
      _$BadgeQuestLinkFromJson(json);
  Map<String, dynamic> toJson() => _$BadgeQuestLinkToJson(this);
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
  final bool isSeasonal;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final String? sourceQuestId;
  final List<BadgeQuestLink> rewardForQuests;
  final double progressPercentage;
  final int currentStep;
  final int totalSteps;

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
    this.isSeasonal = false,
    this.availableFrom,
    this.availableUntil,
    this.sourceQuestId,
    this.rewardForQuests = const [],
    this.progressPercentage = 0,
    this.currentStep = 0,
    this.totalSteps = 0,
  });

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);
  Map<String, dynamic> toJson() => _$BadgeToJson(this);
}

@JsonSerializable()
class UserQuestProgress {
  final int pointsTotal;
  final int coinsBalance;
  final int coinsTotal;
  final int currentLevel;
  final int nextLevelXP;
  final DateTime? lastLevelUpAt;
  final int logStreak;
  final int badgesEarned;

  UserQuestProgress({
    this.pointsTotal = 0,
    this.coinsBalance = 0,
    this.coinsTotal = 0,
    this.currentLevel = 1,
    this.nextLevelXP = 3000,
    this.lastLevelUpAt,
    this.logStreak = 0,
    this.badgesEarned = 0,
  });

  factory UserQuestProgress.fromJson(Map<String, dynamic> json) => _$UserQuestProgressFromJson(json);
  Map<String, dynamic> toJson() => _$UserQuestProgressToJson(this);
}

@JsonSerializable()
class WeeklyChallenge {
  final String id;
  final String title;
  final String description;
  final int targetTotal;
  final int rewardPoints;
  final DateTime startsAt;
  final DateTime endsAt;
  final String category;
  final bool isActive;
  final int progress;
  final bool isCompleted;
  final DateTime? completedAt;

  WeeklyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetTotal,
    required this.rewardPoints,
    required this.startsAt,
    required this.endsAt,
    this.category = 'wellbeing',
    this.isActive = true,
    this.progress = 0,
    this.isCompleted = false,
    this.completedAt,
  });

  factory WeeklyChallenge.fromJson(Map<String, dynamic> json) => _$WeeklyChallengeFromJson(json);
  Map<String, dynamic> toJson() => _$WeeklyChallengeToJson(this);
}
