import 'package:freezed_annotation/freezed_annotation.dart';

part 'learning_models.freezed.dart';
part 'learning_models.g.dart';

@freezed
class LearningJourney with _$LearningJourney {
  const factory LearningJourney({
    required String id,
    required String title,
    required String slug,
    required String description,
    String? thumbnailUrl,
    String? bannerImage,
    @Default(0) int totalXP,
    String? category,
    @Default(true) bool isActive,
    String? ageBand,
    @Default([]) List<String> topics,
    @Default([]) List<String> goals,
    @Default([]) List<String> tags,
    @Default('moderate') String contentTone,
    @Default('TEEN_EARLY') String minContentTier,
    @Default([]) List<Episode> episodes,
  }) = _LearningJourney;

  factory LearningJourney.fromJson(Map<String, dynamic> json) =>
      _$LearningJourneyFromJson(json);
}

@freezed
class Episode with _$Episode {
  const factory Episode({
    required String id,
    required String journeyId,
    required String title,
    required String slug,
    String? description,
    @Default(0) int order,
    required dynamic content, // Structured map of 5 segments
    @Default(50) int points,
    @Default(true) bool isActive,
  }) = _Episode;

  factory Episode.fromJson(Map<String, dynamic> json) =>
      _$EpisodeFromJson(json);
}

@freezed
class UserProgress with _$UserProgress {
  const factory UserProgress({
    required String id,
    required String userId,
    required String episodeId,
    @Default(false) bool completed,
    String? lastViewedItemId,
    required dynamic completedItems,
    required DateTime updatedAt,
    Episode? episode,
  }) = _UserProgress;

  factory UserProgress.fromJson(Map<String, dynamic> json) =>
      _$UserProgressFromJson(json);
}
