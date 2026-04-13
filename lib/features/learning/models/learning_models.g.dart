// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LearningJourneyImpl _$$LearningJourneyImplFromJson(
  Map<String, dynamic> json,
) => _$LearningJourneyImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  slug: json['slug'] as String,
  description: json['description'] as String,
  thumbnailUrl: json['thumbnailUrl'] as String?,
  bannerImage: json['bannerImage'] as String?,
  totalXP: (json['totalXP'] as num?)?.toInt() ?? 0,
  category: json['category'] as String?,
  isActive: json['isActive'] as bool? ?? true,
  ageBand: json['ageBand'] as String?,
  topics:
      (json['topics'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  goals:
      (json['goals'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  contentTone: json['contentTone'] as String? ?? 'moderate',
  minContentTier: json['minContentTier'] as String? ?? 'TEEN_EARLY',
  episodes:
      (json['episodes'] as List<dynamic>?)
          ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$LearningJourneyImplToJson(
  _$LearningJourneyImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'slug': instance.slug,
  'description': instance.description,
  'thumbnailUrl': instance.thumbnailUrl,
  'bannerImage': instance.bannerImage,
  'totalXP': instance.totalXP,
  'category': instance.category,
  'isActive': instance.isActive,
  'ageBand': instance.ageBand,
  'topics': instance.topics,
  'goals': instance.goals,
  'tags': instance.tags,
  'contentTone': instance.contentTone,
  'minContentTier': instance.minContentTier,
  'episodes': instance.episodes,
};

_$EpisodeImpl _$$EpisodeImplFromJson(Map<String, dynamic> json) =>
    _$EpisodeImpl(
      id: json['id'] as String,
      journeyId: json['journeyId'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      content: json['content'],
      points: (json['points'] as num?)?.toInt() ?? 50,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$$EpisodeImplToJson(_$EpisodeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'journeyId': instance.journeyId,
      'title': instance.title,
      'slug': instance.slug,
      'description': instance.description,
      'order': instance.order,
      'content': instance.content,
      'points': instance.points,
      'isActive': instance.isActive,
    };

_$UserProgressImpl _$$UserProgressImplFromJson(Map<String, dynamic> json) =>
    _$UserProgressImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      episodeId: json['episodeId'] as String,
      completed: json['completed'] as bool? ?? false,
      lastViewedItemId: json['lastViewedItemId'] as String?,
      completedItems: json['completedItems'],
      history: json['history'],
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      episode: json['episode'] == null
          ? null
          : Episode.fromJson(json['episode'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$UserProgressImplToJson(_$UserProgressImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'episodeId': instance.episodeId,
      'completed': instance.completed,
      'lastViewedItemId': instance.lastViewedItemId,
      'completedItems': instance.completedItems,
      'history': instance.history,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'episode': instance.episode,
    };
