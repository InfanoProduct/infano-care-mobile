import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracker_models.freezed.dart';
part 'tracker_models.g.dart';

@freezed
class CycleProfileModel with _$CycleProfileModel {
  const factory CycleProfileModel({
    required String userId,
    required String trackerMode, // 'active', 'watching_waiting', 'irregular'
    required DateTime? lastPeriodStart,
    required int avgCycleLength,
    required int avgPeriodDuration,
    required int currentLogStreak,
    required int longestLogStreak,
    required DateTime? lastLogDate,
    required String? currentPhase,
    String? nextPhase,
    int? daysUntilNextPhase,
    required int? currentCycleDay,
    required DateTime? predictedNextStart,
    required DateTime? predictionWindowEarly,
    required DateTime? predictionWindowLate,
    required String confidenceLevel,
  }) = _CycleProfileModel;

  factory CycleProfileModel.fromJson(Map<String, dynamic> json) =>
      _$CycleProfileModelFromJson(json);
}

@freezed
class CycleLogModel with _$CycleLogModel {
  const factory CycleLogModel({
    required String id,
    required DateTime date,
    String? flow, // 'none', 'light', 'medium', 'heavy', 'spotting', 'ended'
    @Default([]) List<String> symptoms,
    int? crampIntensity,
    String? moodPrimary,
    @Default([]) List<String> moodSecondary,
    int? energyLevel,
    double? sleepHours,
    int? sleepQuality,
    String? noteText,
    @Default([]) List<String> nutritionTags,
    @Default([]) List<String> activityTags,
    bool? isRetroactive,
  }) = _CycleLogModel;

  factory CycleLogModel.fromJson(Map<String, dynamic> json) =>
      _$CycleLogModelFromJson(json);
}

@freezed
class PredictionResultModel with _$PredictionResultModel {
  const factory PredictionResultModel({
    required DateTime predictedStart,
    required DateTime windowEarly,
    required DateTime windowLate,
    required DateTime ovulationDate,
    required DateTime fertilityStart,
    required DateTime fertilityEnd,
    required String confidenceLevel,
    required int daysUntilPrediction,
    required String currentPhase,
    String? nextPhase,
    int? daysUntilNextPhase,
    required int cycleDay,
    @Default(0.0) double coefficientOfVar,
    @Default(0) int cyclesLogged,
    @Default(0) int currentLogStreak,
    @Default(false) bool hasLoggedToday,
    @Default([]) List<String> insights,
  }) = _PredictionResultModel;

  factory PredictionResultModel.fromJson(Map<String, dynamic> json) =>
      _$PredictionResultModelFromJson(json);
}

@freezed
class CycleRecordModel with _$CycleRecordModel {
  const factory CycleRecordModel({
    required String id,
    required int cycleNumber,
    required DateTime startDate,
    required DateTime periodStartDate,
    DateTime? endDate,
    DateTime? periodEndDate,
    int? cycleLengthDays,
    int? periodDurationDays,
    @Default(false) bool isComplete,
    int? predictionErrorDays,
  }) = _CycleRecordModel;

  factory CycleRecordModel.fromJson(Map<String, dynamic> json) =>
      _$CycleRecordModelFromJson(json);
}
