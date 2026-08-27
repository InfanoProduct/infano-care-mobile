// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestTemplate _$QuestTemplateFromJson(Map<String, dynamic> json) =>
    QuestTemplate(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'daily',
      category: json['category'] as String? ?? 'wildcard',
      title: json['title'] as String? ?? 'New Quest',
      description: json['description'] as String? ?? '',
      pointsBase: (json['pointsBase'] as num?)?.toInt() ?? 0,
      pointsMax: (json['pointsMax'] as num?)?.toInt(),
      difficulty: json['difficulty'] as String? ?? 'standard',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 5,
      completionCondition: json['completionCondition'] as Map<String, dynamic>?,
      badgeRewardId: json['badgeRewardId'] as String?,
    );

Map<String, dynamic> _$QuestTemplateToJson(QuestTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'category': instance.category,
      'title': instance.title,
      'description': instance.description,
      'pointsBase': instance.pointsBase,
      'pointsMax': instance.pointsMax,
      'difficulty': instance.difficulty,
      'estimatedMinutes': instance.estimatedMinutes,
      'completionCondition': instance.completionCondition,
      'badgeRewardId': instance.badgeRewardId,
    };

UserQuest _$UserQuestFromJson(Map<String, dynamic> json) => UserQuest(
  id: json['id'] as String,
  userId: json['userId'] as String,
  questTemplateId: json['questTemplateId'] as String,
  questDate: DateTime.parse(json['questDate'] as String),
  status: json['status'] as String,
  acceptedAt: json['acceptedAt'] == null
      ? null
      : DateTime.parse(json['acceptedAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  pointsAwarded: (json['pointsAwarded'] as num?)?.toInt(),
  questTemplate: QuestTemplate.fromJson(
    json['questTemplate'] as Map<String, dynamic>,
  ),
  progressJson: json['progressJson'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$UserQuestToJson(UserQuest instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'questTemplateId': instance.questTemplateId,
  'questDate': instance.questDate.toIso8601String(),
  'status': instance.status,
  'acceptedAt': instance.acceptedAt?.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'pointsAwarded': instance.pointsAwarded,
  'questTemplate': instance.questTemplate,
  'progressJson': instance.progressJson,
};

BadgeQuestLink _$BadgeQuestLinkFromJson(Map<String, dynamic> json) =>
    BadgeQuestLink(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'wildcard',
      pointsBase: (json['pointsBase'] as num?)?.toInt() ?? 0,
      difficulty: json['difficulty'] as String? ?? 'standard',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 5,
      completionCondition: json['completionCondition'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$BadgeQuestLinkToJson(BadgeQuestLink instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'pointsBase': instance.pointsBase,
      'difficulty': instance.difficulty,
      'estimatedMinutes': instance.estimatedMinutes,
      'completionCondition': instance.completionCondition,
    };

Badge _$BadgeFromJson(Map<String, dynamic> json) => Badge(
  id: json['id'] as String,
  slug: json['slug'] as String?,
  name: json['name'] as String? ?? 'New Badge',
  description: json['description'] as String?,
  collection: json['collection'] as String?,
  rarity: json['rarity'] as String? ?? 'common',
  illustrationUrl: json['illustrationUrl'] as String?,
  isAnimated: json['isAnimated'] as bool? ?? false,
  isEarned: json['isEarned'] as bool? ?? false,
  awardedAt: json['awardedAt'] == null
      ? null
      : DateTime.parse(json['awardedAt'] as String),
  isSeasonal: json['isSeasonal'] as bool? ?? false,
  availableFrom: json['availableFrom'] == null
      ? null
      : DateTime.parse(json['availableFrom'] as String),
  availableUntil: json['availableUntil'] == null
      ? null
      : DateTime.parse(json['availableUntil'] as String),
  sourceQuestId: json['sourceQuestId'] as String?,
  rewardForQuests:
      (json['rewardForQuests'] as List<dynamic>?)
          ?.map((e) => BadgeQuestLink.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0,
  currentStep: (json['currentStep'] as num?)?.toInt() ?? 0,
  totalSteps: (json['totalSteps'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$BadgeToJson(Badge instance) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'name': instance.name,
  'description': instance.description,
  'collection': instance.collection,
  'rarity': instance.rarity,
  'illustrationUrl': instance.illustrationUrl,
  'isAnimated': instance.isAnimated,
  'isEarned': instance.isEarned,
  'awardedAt': instance.awardedAt?.toIso8601String(),
  'isSeasonal': instance.isSeasonal,
  'availableFrom': instance.availableFrom?.toIso8601String(),
  'availableUntil': instance.availableUntil?.toIso8601String(),
  'sourceQuestId': instance.sourceQuestId,
  'rewardForQuests': instance.rewardForQuests,
  'progressPercentage': instance.progressPercentage,
  'currentStep': instance.currentStep,
  'totalSteps': instance.totalSteps,
};

UserQuestProgress _$UserQuestProgressFromJson(Map<String, dynamic> json) =>
    UserQuestProgress(
      pointsTotal: (json['pointsTotal'] as num?)?.toInt() ?? 0,
      coinsBalance: (json['coinsBalance'] as num?)?.toInt() ?? 0,
      coinsTotal: (json['coinsTotal'] as num?)?.toInt() ?? 0,
      currentLevel: (json['currentLevel'] as num?)?.toInt() ?? 1,
      nextLevelXP: (json['nextLevelXP'] as num?)?.toInt() ?? 3000,
      lastLevelUpAt: json['lastLevelUpAt'] == null
          ? null
          : DateTime.parse(json['lastLevelUpAt'] as String),
      logStreak: (json['logStreak'] as num?)?.toInt() ?? 0,
      badgesEarned: (json['badgesEarned'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UserQuestProgressToJson(UserQuestProgress instance) =>
    <String, dynamic>{
      'pointsTotal': instance.pointsTotal,
      'coinsBalance': instance.coinsBalance,
      'coinsTotal': instance.coinsTotal,
      'currentLevel': instance.currentLevel,
      'nextLevelXP': instance.nextLevelXP,
      'lastLevelUpAt': instance.lastLevelUpAt?.toIso8601String(),
      'logStreak': instance.logStreak,
      'badgesEarned': instance.badgesEarned,
    };

WeeklyChallenge _$WeeklyChallengeFromJson(Map<String, dynamic> json) =>
    WeeklyChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetTotal: (json['targetTotal'] as num).toInt(),
      rewardPoints: (json['rewardPoints'] as num).toInt(),
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      category: json['category'] as String? ?? 'wellbeing',
      isActive: json['isActive'] as bool? ?? true,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$WeeklyChallengeToJson(WeeklyChallenge instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'targetTotal': instance.targetTotal,
      'rewardPoints': instance.rewardPoints,
      'startsAt': instance.startsAt.toIso8601String(),
      'endsAt': instance.endsAt.toIso8601String(),
      'category': instance.category,
      'isActive': instance.isActive,
      'progress': instance.progress,
      'isCompleted': instance.isCompleted,
      'completedAt': instance.completedAt?.toIso8601String(),
    };
