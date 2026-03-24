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
    @Default([]) List<Summary> summaries,
  }) = _LearningJourney;

  factory LearningJourney.fromJson(Map<String, dynamic> json) =>
      _$LearningJourneyFromJson(json);
}

@freezed
class Summary with _$Summary {
  const factory Summary({
    required String id,
    required String journeyId,
    required String title,
    required String slug,
    String? description,
    @Default(0) int order,
    required dynamic content, // JSON Array of SummaryItems
    @Default(50) int points,
    @Default(true) bool isActive,
  }) = _Summary;

  factory Summary.fromJson(Map<String, dynamic> json) =>
      _$SummaryFromJson(json);
}

@freezed
class UserProgress with _$UserProgress {
  const factory UserProgress({
    required String id,
    required String userId,
    required String summaryId,
    @Default(false) bool completed,
    String? lastViewedItemId,
    required dynamic completedItems,
    required DateTime updatedAt,
    Summary? summary,
  }) = _UserProgress;

  factory UserProgress.fromJson(Map<String, dynamic> json) =>
      _$UserProgressFromJson(json);
}
