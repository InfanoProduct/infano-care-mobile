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
  summaries:
      (json['summaries'] as List<dynamic>?)
          ?.map((e) => Summary.fromJson(e as Map<String, dynamic>))
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
  'summaries': instance.summaries,
};

_$SummaryImpl _$$SummaryImplFromJson(Map<String, dynamic> json) =>
    _$SummaryImpl(
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

Map<String, dynamic> _$$SummaryImplToJson(_$SummaryImpl instance) =>
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
      summaryId: json['summaryId'] as String,
      completed: json['completed'] as bool? ?? false,
      lastViewedItemId: json['lastViewedItemId'] as String?,
      completedItems: json['completedItems'],
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      summary: json['summary'] == null
          ? null
          : Summary.fromJson(json['summary'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$UserProgressImplToJson(_$UserProgressImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'summaryId': instance.summaryId,
      'completed': instance.completed,
      'lastViewedItemId': instance.lastViewedItemId,
      'completedItems': instance.completedItems,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'summary': instance.summary,
    };
