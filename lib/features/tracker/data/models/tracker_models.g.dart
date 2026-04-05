// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracker_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CycleProfileModelImpl _$$CycleProfileModelImplFromJson(
  Map<String, dynamic> json,
) => _$CycleProfileModelImpl(
  userId: json['userId'] as String,
  trackerMode: json['trackerMode'] as String,
  lastPeriodStart: json['lastPeriodStart'] == null
      ? null
      : DateTime.parse(json['lastPeriodStart'] as String),
  avgCycleLength: (json['avgCycleLength'] as num).toInt(),
  avgPeriodDuration: (json['avgPeriodDuration'] as num).toInt(),
  currentLogStreak: (json['currentLogStreak'] as num).toInt(),
  longestLogStreak: (json['longestLogStreak'] as num).toInt(),
  lastLogDate: json['lastLogDate'] == null
      ? null
      : DateTime.parse(json['lastLogDate'] as String),
  currentPhase: json['currentPhase'] as String?,
  currentCycleDay: (json['currentCycleDay'] as num?)?.toInt(),
  predictedNextStart: json['predictedNextStart'] == null
      ? null
      : DateTime.parse(json['predictedNextStart'] as String),
  predictionWindowEarly: json['predictionWindowEarly'] == null
      ? null
      : DateTime.parse(json['predictionWindowEarly'] as String),
  predictionWindowLate: json['predictionWindowLate'] == null
      ? null
      : DateTime.parse(json['predictionWindowLate'] as String),
  confidenceLevel: json['confidenceLevel'] as String,
);

Map<String, dynamic> _$$CycleProfileModelImplToJson(
  _$CycleProfileModelImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'trackerMode': instance.trackerMode,
  'lastPeriodStart': instance.lastPeriodStart?.toIso8601String(),
  'avgCycleLength': instance.avgCycleLength,
  'avgPeriodDuration': instance.avgPeriodDuration,
  'currentLogStreak': instance.currentLogStreak,
  'longestLogStreak': instance.longestLogStreak,
  'lastLogDate': instance.lastLogDate?.toIso8601String(),
  'currentPhase': instance.currentPhase,
  'currentCycleDay': instance.currentCycleDay,
  'predictedNextStart': instance.predictedNextStart?.toIso8601String(),
  'predictionWindowEarly': instance.predictionWindowEarly?.toIso8601String(),
  'predictionWindowLate': instance.predictionWindowLate?.toIso8601String(),
  'confidenceLevel': instance.confidenceLevel,
};

_$CycleLogModelImpl _$$CycleLogModelImplFromJson(Map<String, dynamic> json) =>
    _$CycleLogModelImpl(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      flow: json['flow'] as String?,
      symptoms:
          (json['symptoms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      crampIntensity: (json['crampIntensity'] as num?)?.toInt(),
      moodPrimary: json['moodPrimary'] as String?,
      moodSecondary:
          (json['moodSecondary'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      energyLevel: (json['energyLevel'] as num?)?.toInt(),
      sleepHours: (json['sleepHours'] as num?)?.toDouble(),
      sleepQuality: (json['sleepQuality'] as num?)?.toInt(),
      noteText: json['noteText'] as String?,
      nutritionTags:
          (json['nutritionTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      activityTags:
          (json['activityTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isRetroactive: json['isRetroactive'] as bool?,
    );

Map<String, dynamic> _$$CycleLogModelImplToJson(_$CycleLogModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'flow': instance.flow,
      'symptoms': instance.symptoms,
      'crampIntensity': instance.crampIntensity,
      'moodPrimary': instance.moodPrimary,
      'moodSecondary': instance.moodSecondary,
      'energyLevel': instance.energyLevel,
      'sleepHours': instance.sleepHours,
      'sleepQuality': instance.sleepQuality,
      'noteText': instance.noteText,
      'nutritionTags': instance.nutritionTags,
      'activityTags': instance.activityTags,
      'isRetroactive': instance.isRetroactive,
    };

_$PredictionResultModelImpl _$$PredictionResultModelImplFromJson(
  Map<String, dynamic> json,
) => _$PredictionResultModelImpl(
  predictedStart: DateTime.parse(json['predictedStart'] as String),
  windowEarly: DateTime.parse(json['windowEarly'] as String),
  windowLate: DateTime.parse(json['windowLate'] as String),
  ovulationDate: DateTime.parse(json['ovulationDate'] as String),
  fertilityStart: DateTime.parse(json['fertilityStart'] as String),
  fertilityEnd: DateTime.parse(json['fertilityEnd'] as String),
  confidenceLevel: json['confidenceLevel'] as String,
  daysUntilPrediction: (json['daysUntilPrediction'] as num).toInt(),
  currentPhase: json['currentPhase'] as String,
  cycleDay: (json['cycleDay'] as num).toInt(),
  coefficientOfVar: (json['coefficientOfVar'] as num?)?.toDouble() ?? 0.0,
  cyclesLogged: (json['cyclesLogged'] as num?)?.toInt() ?? 0,
  currentLogStreak: (json['currentLogStreak'] as num?)?.toInt() ?? 0,
  hasLoggedToday: json['hasLoggedToday'] as bool? ?? false,
  insights:
      (json['insights'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$$PredictionResultModelImplToJson(
  _$PredictionResultModelImpl instance,
) => <String, dynamic>{
  'predictedStart': instance.predictedStart.toIso8601String(),
  'windowEarly': instance.windowEarly.toIso8601String(),
  'windowLate': instance.windowLate.toIso8601String(),
  'ovulationDate': instance.ovulationDate.toIso8601String(),
  'fertilityStart': instance.fertilityStart.toIso8601String(),
  'fertilityEnd': instance.fertilityEnd.toIso8601String(),
  'confidenceLevel': instance.confidenceLevel,
  'daysUntilPrediction': instance.daysUntilPrediction,
  'currentPhase': instance.currentPhase,
  'cycleDay': instance.cycleDay,
  'coefficientOfVar': instance.coefficientOfVar,
  'cyclesLogged': instance.cyclesLogged,
  'currentLogStreak': instance.currentLogStreak,
  'hasLoggedToday': instance.hasLoggedToday,
  'insights': instance.insights,
};

_$CycleRecordModelImpl _$$CycleRecordModelImplFromJson(
  Map<String, dynamic> json,
) => _$CycleRecordModelImpl(
  id: json['id'] as String,
  cycleNumber: (json['cycleNumber'] as num).toInt(),
  startDate: DateTime.parse(json['startDate'] as String),
  periodStartDate: DateTime.parse(json['periodStartDate'] as String),
  endDate: json['endDate'] == null
      ? null
      : DateTime.parse(json['endDate'] as String),
  periodEndDate: json['periodEndDate'] == null
      ? null
      : DateTime.parse(json['periodEndDate'] as String),
  cycleLengthDays: (json['cycleLengthDays'] as num?)?.toInt(),
  periodDurationDays: (json['periodDurationDays'] as num?)?.toInt(),
  isComplete: json['isComplete'] as bool? ?? false,
);

Map<String, dynamic> _$$CycleRecordModelImplToJson(
  _$CycleRecordModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'cycleNumber': instance.cycleNumber,
  'startDate': instance.startDate.toIso8601String(),
  'periodStartDate': instance.periodStartDate.toIso8601String(),
  'endDate': instance.endDate?.toIso8601String(),
  'periodEndDate': instance.periodEndDate?.toIso8601String(),
  'cycleLengthDays': instance.cycleLengthDays,
  'periodDurationDays': instance.periodDurationDays,
  'isComplete': instance.isComplete,
};
