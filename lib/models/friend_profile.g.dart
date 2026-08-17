// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendProfile _$FriendProfileFromJson(
  Map<String, dynamic> json,
) => FriendProfile(
  id: json['id'] as String,
  userId: json['userId'] as String,
  nickname: json['nickname'] as String?,
  vibeTags:
      (json['vibeTags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  intent:
      (json['intent'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  photoUrl: json['photoUrl'] as String?,
  status: json['status'] as String?,
  isActive: json['isActive'] as bool?,
  ageBand: json['ageBand'] as String?,
  locationLabel: json['locationLabel'] as String?,
  compatibilityScore: (json['compatibilityScore'] as num?)?.toInt(),
  compatibilityLabel: json['compatibilityLabel'] as String?,
  sharedCircles: (json['sharedCircles'] as num?)?.toInt(),
  sharedEvents: (json['sharedEvents'] as num?)?.toInt(),
  discoveryRadius: json['discoveryRadius'] as String?,
);

Map<String, dynamic> _$FriendProfileToJson(FriendProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'nickname': instance.nickname,
      'vibeTags': instance.vibeTags,
      'intent': instance.intent,
      'photoUrl': instance.photoUrl,
      'status': instance.status,
      'isActive': instance.isActive,
      'ageBand': instance.ageBand,
      'locationLabel': instance.locationLabel,
      'compatibilityScore': instance.compatibilityScore,
      'compatibilityLabel': instance.compatibilityLabel,
      'sharedCircles': instance.sharedCircles,
      'sharedEvents': instance.sharedEvents,
      'discoveryRadius': instance.discoveryRadius,
    };
