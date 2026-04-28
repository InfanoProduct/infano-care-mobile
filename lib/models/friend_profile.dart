import 'package:json_annotation/json_annotation.dart';

part 'friend_profile.g.dart';

@JsonSerializable()
class FriendProfile {
  final String id;
  final String userId;
  final String? nickname;
  final List<String> vibeTags;
  final List<String> intent;
  final String? photoUrl;
  final String? status;
  final bool? isActive;
  final String? ageBand;
  final String? locationLabel;
  final int? compatibilityScore;
  final String? compatibilityLabel;
  final int? sharedCircles;
  final int? sharedEvents;
  final String? discoveryRadius;

  FriendProfile({
    required this.id,
    required this.userId,
    this.nickname,
    this.vibeTags = const [],
    this.intent = const [],
    this.photoUrl,
    this.status,
    this.isActive,
    this.ageBand,
    this.locationLabel,
    this.compatibilityScore,
    this.compatibilityLabel,
    this.sharedCircles,
    this.sharedEvents,
    this.discoveryRadius,
  });

  factory FriendProfile.fromJson(Map<String, dynamic> json) =>
      _$FriendProfileFromJson(json);

  Map<String, dynamic> toJson() => _$FriendProfileToJson(this);
}
